import Foundation
import Combine

// MARK: - 家教模式
enum TutorMode: String, Codable, CaseIterable {
    case local   // 本地离线家教（v1 默认）
    case proxy   // 代理后端 AI 家教（以后用）
}

// MARK: - App 显示语言
enum AppLanguage: String, Codable, CaseIterable {
    case chinese = "zh-Hans"
    case english = "en"

    /// 跟随系统语言：中文系（zh-Hans/zh-Hant/…）显示中文，其他显示英文
    static var systemDefault: AppLanguage {
        let first = Locale.preferredLanguages.first ?? ""
        return first.hasPrefix("zh") ? .chinese : .english
    }
}

// MARK: - App 设置
/// UserDefaults key "yuetutor.settings" 持久化，每个 setter 都存
final class AppSettings: ObservableObject {
    private static let storageKey = "yuetutor.settings"

    @Published var tutorMode: TutorMode = .local { didSet { persist() } }
    @Published var proxyBaseURL: String = "" { didSet { persist() } }
    @Published var appSecret: String = "" { didSet { persist() } }
    @Published var speechRate: Double = 0.42 { didSet { persist() } }
    @Published var autoSpeak: Bool = true { didSet { persist() } }
    /// 按钮震动反馈开关（设置页可关）
    @Published var hapticsEnabled: Bool = true { didSet { persist() } }

    /// 代理地址是否已配置：proxyBaseURL 非空即视为已配置
    var proxyConfigured: Bool {
        !proxyBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 从 UserDefaults("yuetutor.settings") 读取，没有则用默认值
    /// 注意：init 内赋值不会触发 didSet，这里整体加载一次即可
    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(SettingsData.self, from: data) {
            tutorMode = saved.tutorMode
            proxyBaseURL = saved.proxyBaseURL
            appSecret = saved.appSecret
            speechRate = saved.speechRate
            autoSpeak = saved.autoSpeak
            hapticsEnabled = saved.hapticsEnabled
        }
    }

    /// 把当前全部设置整体写进 UserDefaults
    private func persist() {
        let snapshot = SettingsData(
            tutorMode: tutorMode,
            proxyBaseURL: proxyBaseURL,
            appSecret: appSecret,
            speechRate: speechRate,
            autoSpeak: autoSpeak,
            hapticsEnabled: hapticsEnabled
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

// MARK: - 设置快照
/// 设置的 Codable 快照，用于整体持久化。
/// 自定义解码：老版本存档缺字段时用默认值，保证升级不丢已有设置。
private struct SettingsData: Codable {
    var tutorMode: TutorMode
    var proxyBaseURL: String
    var appSecret: String
    var speechRate: Double
    var autoSpeak: Bool
    var hapticsEnabled: Bool

    init(tutorMode: TutorMode, proxyBaseURL: String, appSecret: String,
         speechRate: Double, autoSpeak: Bool, hapticsEnabled: Bool) {
        self.tutorMode = tutorMode
        self.proxyBaseURL = proxyBaseURL
        self.appSecret = appSecret
        self.speechRate = speechRate
        self.autoSpeak = autoSpeak
        self.hapticsEnabled = hapticsEnabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tutorMode = try c.decodeIfPresent(TutorMode.self, forKey: .tutorMode) ?? .local
        proxyBaseURL = try c.decodeIfPresent(String.self, forKey: .proxyBaseURL) ?? ""
        appSecret = try c.decodeIfPresent(String.self, forKey: .appSecret) ?? ""
        speechRate = try c.decodeIfPresent(Double.self, forKey: .speechRate) ?? 0.42
        autoSpeak = try c.decodeIfPresent(Bool.self, forKey: .autoSpeak) ?? true
        hapticsEnabled = try c.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
    }
}
