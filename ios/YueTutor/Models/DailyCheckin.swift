import Foundation

// MARK: - 每日打卡内容
/// 由 Muse 每天 08:00 生成，推到 YueTutor 仓库 docs/daily-checkin.json，
/// App 启动时拉取（raw.githubusercontent.com），缓存到本地，没网用缓存。
struct DailyCheckin: Codable {
    let date: String              // yyyy-MM-dd，如 2026-10-03
    let weekday: String           // 周六
    let theme: String             // 家庭·日常
    let words: [CheckinWord]      // 5 个词
    let sentence: CheckinSentence // 1 个场景句
    let tip: String               // 发音 / 语法 tip

    /// 打卡项 id：w0..w4 / s0 / tip
    var itemIds: [String] {
        words.indices.map { "w\($0)" } + ["s0", "tip"]
    }
}

struct CheckinWord: Codable, Hashable {
    let cantonese: String
    let jyutping: String
    let hakka: String
    let mandarin: String
}

struct CheckinSentence: Codable, Hashable {
    let cantonese: String
    let jyutping: String
    let mandarin: String
}

// MARK: - 打卡特别主题
extension DailyCheckin {
    /// 转为课程特别主题（id 固定 "daily-checkin"，插在课程最前，供聊天闭环直接使用）
    var asTheme: CourseTheme {
        CourseTheme(
            id: "daily-checkin",
            titleZh: "今日打卡",
            titleEn: "Daily Check-in",
            words: words.map {
                CourseWord(cantonese: $0.cantonese, jyutping: $0.jyutping, hakka: $0.hakka, mandarin: $0.mandarin)
            },
            sentences: [CourseSentence(cantonese: sentence.cantonese, jyutping: sentence.jyutping, mandarin: sentence.mandarin)],
            tip: tip
        )
    }
}

// MARK: - 打卡结果（App → Worker → KV，供下一次打卡自适应出题）
struct CheckinResult: Codable {
    let date: String
    let done: [String]       // 完成的打卡项 id
    let completedAt: String  // ISO8601
}
