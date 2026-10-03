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

// MARK: - 打卡结果（App → Worker → KV，供下一次打卡自适应出题）
struct CheckinResult: Codable {
    let date: String
    let done: [String]       // 完成的打卡项 id
    let completedAt: String  // ISO8601
}
