import Foundation

// MARK: - 词语拆解项
/// 对单个粤语词的拆解：汉字 + 粤拼 + 简体中文意思
struct BreakdownItem: Codable, Hashable, Identifiable {
    var id: String { cantonese + jyutping + english }
    let cantonese: String
    let jyutping: String
    let english: String   // 简体中文意思
}

// MARK: - 建议回复
/// 聊天框下方的快捷回复：粤语原文 + 粤拼 + 简体中文意思
struct SuggestedReply: Codable, Hashable, Identifiable {
    var id: String { cantonese }
    let cantonese: String
    let jyutping: String
    let english: String   // 简体中文意思
}

// MARK: - 一次家教回答
/// 家教（本地或代理）返回的一课内容。
/// 防御性解码：每个字段缺失时回退为 "" / [] / nil，绝不抛错。
struct Lesson: Codable, Hashable {
    let replyCantonese: String
    let replyJyutping: String
    let replyEnglish: String   // 简体中文翻译
    let breakdown: [BreakdownItem]
    let correction: String?    // 中文纠正/反馈
    let tip: String?           // 中文学习 tip
    let suggestedReplies: [SuggestedReply]
    let difficulty: String?

    /// 供本地服务直接构造的 memberwise 风格初始化器
    init(
        replyCantonese: String,
        replyJyutping: String,
        replyEnglish: String,
        breakdown: [BreakdownItem] = [],
        correction: String? = nil,
        tip: String? = nil,
        suggestedReplies: [SuggestedReply] = [],
        difficulty: String? = nil
    ) {
        self.replyCantonese = replyCantonese
        self.replyJyutping = replyJyutping
        self.replyEnglish = replyEnglish
        self.breakdown = breakdown
        self.correction = correction
        self.tip = tip
        self.suggestedReplies = suggestedReplies
        self.difficulty = difficulty
    }

    /// 防御性解码：字段缺失时用 "" / [] / nil 代替，绝不抛错
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        replyCantonese = try container.decodeIfPresent(String.self, forKey: .replyCantonese) ?? ""
        replyJyutping = try container.decodeIfPresent(String.self, forKey: .replyJyutping) ?? ""
        replyEnglish = try container.decodeIfPresent(String.self, forKey: .replyEnglish) ?? ""
        breakdown = try container.decodeIfPresent([BreakdownItem].self, forKey: .breakdown) ?? []
        correction = try container.decodeIfPresent(String.self, forKey: .correction)
        tip = try container.decodeIfPresent(String.self, forKey: .tip)
        suggestedReplies = try container.decodeIfPresent([SuggestedReply].self, forKey: .suggestedReplies) ?? []
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
    }

    /// 编码（与防御性解码配对，手动实现以满足 Codable）
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(replyCantonese, forKey: .replyCantonese)
        try container.encode(replyJyutping, forKey: .replyJyutping)
        try container.encode(replyEnglish, forKey: .replyEnglish)
        try container.encode(breakdown, forKey: .breakdown)
        try container.encodeIfPresent(correction, forKey: .correction)
        try container.encodeIfPresent(tip, forKey: .tip)
        try container.encode(suggestedReplies, forKey: .suggestedReplies)
        try container.encodeIfPresent(difficulty, forKey: .difficulty)
    }
}

// MARK: - 后端统一返回体
/// 代理后端返回的包：{ ok, lesson, error }
struct LessonResponse: Codable {
    let ok: Bool
    let lesson: Lesson?
    let error: String?

    /// 防御性解码：ok 缺失时视为 false，绝不抛错
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ok = try container.decodeIfPresent(Bool.self, forKey: .ok) ?? false
        lesson = try container.decodeIfPresent(Lesson.self, forKey: .lesson)
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }

    /// 编码（与防御性解码配对，手动实现以满足 Codable）
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ok, forKey: .ok)
        try container.encodeIfPresent(lesson, forKey: .lesson)
        try container.encodeIfPresent(error, forKey: .error)
    }
}
