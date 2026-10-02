import Foundation
import Combine

// MARK: - 学习者水平
enum LearnerLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced

    /// 中文展示名
    var displayName: String {
        switch self {
        case .beginner: return "零基础"
        case .intermediate: return "进阶"
        case .advanced: return "高级"
        }
    }
}

// MARK: - 学习者档案
struct TutorProfile: Codable {
    var name: String
    var level: LearnerLevel
    var interests: [String]
    var tutorName: String
    var focus: String?
}

// MARK: - 档案存储
/// UserDefaults key "yuetutor.profile" 持久化；无已存档案时给默认值
final class ProfileStore: ObservableObject {
    private static let storageKey = "yuetutor.profile"

    @Published var profile: TutorProfile

    /// 是否已完成 onboarding：已保存过名字即视为已引导
    var isOnboarded: Bool {
        !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 从 UserDefaults("yuetutor.profile") 读取，没有则给默认值
    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(TutorProfile.self, from: data) {
            profile = saved
        } else {
            profile = TutorProfile(name: "", level: .beginner, interests: [], tutorName: "小粤", focus: nil)
        }
    }

    /// 保存档案（并持久化）
    func save(name: String, level: LearnerLevel, interests: [String], tutorName: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTutor = tutorName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile = TutorProfile(
            name: trimmedName,
            level: level,
            interests: interests,
            tutorName: trimmedTutor.isEmpty ? "小粤" : trimmedTutor,
            focus: profile.focus
        )
        persist()
    }

    /// 清掉已存 profile（isOnboarded 变为 false）
    func reset() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
        profile = TutorProfile(name: "", level: .beginner, interests: [], tutorName: "小粤", focus: nil)
    }

    /// 更新兴趣（多选）：设置页的主题多选用
    func setInterests(_ interests: [String]) {
        profile.interests = interests
        persist()
    }

    /// 把当前 profile 写进 UserDefaults
    private func persist() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
