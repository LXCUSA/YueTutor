import Foundation
import Combine

// MARK: - 每日打卡服务
/// 拉取仓库的 docs/daily-checkin.json（Muse 每天 08:00 生成并推送），
/// 成功则缓存到 Documents，失败/没网就用缓存。打卡进度按日期存 UserDefaults。
final class DailyCheckinService: ObservableObject {
    static let remoteURL = URL(string: "https://raw.githubusercontent.com/lxc-usa/YueTutor/main/docs/daily-checkin.json")!
    private static let cacheFileName = "daily-checkin.json"

    @Published private(set) var checkin: DailyCheckin? {
        didSet {
            // 同步为课程特别主题，聊天闭环（chips/考考我/跟读/关键词）直接可用
            LocalTutorService.dailyCheckinTheme = checkin?.asTheme
            NotificationCenter.default.post(name: .curriculumDidReload, object: nil)
        }
    }
    @Published private(set) var doneItems: Set<String> = []
    /// 今日是否已上报结果（避免重复 POST）
    @Published private(set) var reportedDate: String?

    private var cacheURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Self.cacheFileName)
    }

    init() {
        loadCache()
        // 还没有缓存（比如首次安装且无网络）就用内置的默认打卡内容
        if checkin == nil, let url = Bundle.main.url(forResource: "daily-checkin", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let bundled = try? JSONDecoder().decode(DailyCheckin.self, from: data) {
            checkin = bundled
            loadProgress()
        }
        reportedDate = UserDefaults.standard.string(forKey: "checkin-reported-date")
    }

    /// 界面出现时调用：先读缓存立刻显示，后台拉新
    func refresh() {
        loadCache()
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: Self.remoteURL)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { return }
                let fresh = try JSONDecoder().decode(DailyCheckin.self, from: data)
                try? data.write(to: cacheURL, options: .atomic)
                await MainActor.run {
                    // 只有日期更新时才重置进度，避免同一天重复拉取清空已打勾
                    let isNewDay = self.checkin?.date != fresh.date
                    self.checkin = fresh
                    if isNewDay { self.doneItems = [] }
                    self.loadProgress()
                }
            } catch {
                // 没网/解析失败就用缓存，不打扰用户
            }
        }
    }

    private func loadCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let cached = try? JSONDecoder().decode(DailyCheckin.self, from: data) else { return }
        let isNewDay = checkin?.date != cached.date
        checkin = cached
        if isNewDay { doneItems = [] }
        loadProgress()
    }

    private func loadProgress() {
        guard let date = checkin?.date else { return }
        let saved = UserDefaults.standard.stringArray(forKey: "checkin-done-\(date)") ?? []
        // 只保留当前打卡仍存在的项
        let valid = Set(checkin?.itemIds ?? [])
        doneItems = Set(saved).intersection(valid).union(doneItems.intersection(valid))
    }

    func toggle(_ id: String) {
        if doneItems.contains(id) {
            doneItems.remove(id)
        } else {
            doneItems.insert(id)
        }
        saveProgress()
    }

    private func saveProgress() {
        guard let date = checkin?.date else { return }
        UserDefaults.standard.set(Array(doneItems), forKey: "checkin-done-\(date)")
    }

    /// 进度：已完成 / 总数
    var progress: (done: Int, total: Int) {
        guard let checkin else { return (0, 0) }
        return (Set(checkin.itemIds).intersection(doneItems).count, checkin.itemIds.count)
    }

    var isComplete: Bool {
        guard let checkin else { return false }
        return Set(checkin.itemIds).isSubset(of: doneItems)
    }

    /// 是否已上报今日结果
    var hasReportedToday: Bool {
        reportedDate == checkin?.date
    }

    /// 上报今日打卡结果（Worker 中转，供下一次自适应出题）
    func reportToday() async -> Bool {
        guard let checkin, !hasReportedToday else { return false }
        let formatter = ISO8601DateFormatter()
        let result = CheckinResult(
            date: checkin.date,
            done: checkin.itemIds.filter { doneItems.contains($0) },
            completedAt: formatter.string(from: Date())
        )
        let ok = await CheckinReporter.report(result)
        if ok {
            await MainActor.run {
                self.reportedDate = checkin.date
                UserDefaults.standard.set(checkin.date, forKey: "checkin-reported-date")
            }
        }
        return ok
    }
}
