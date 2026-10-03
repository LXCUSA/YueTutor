import Foundation

// MARK: - 课程词
/// 汉字 + 粤拼数字调 + 客家话近似读音（仅联想用，已标"近似"）+ 普通话意思
struct CourseWord: Codable, Hashable {
    let cantonese: String   // 汉字
    let jyutping: String    // 粤拼数字调
    let hakka: String       // 客家话近似读音（联想用）
    let mandarin: String    // 普通话意思
}

// MARK: - 课程场景句
struct CourseSentence: Codable, Hashable {
    let cantonese: String
    let jyutping: String
    let mandarin: String
}

// MARK: - 课程主题
/// 一个主题 = 8 个词 + 3 个场景句 + 1 条发音 tip
struct CourseTheme: Codable, Hashable, Identifiable {
    let id: String          // "greeting" / "number" / "food" / "direction" / "shopping" / "family"
    let titleZh: String
    let titleEn: String
    let words: [CourseWord]      // 8 个
    let sentences: [CourseSentence]  // 3 个场景句（第 0 句为代表句）
    let tip: String              // 发音 tip（简体中文）
}
