import Foundation

// MARK: - 课程来源
/// 设置页展示：当前生效课程从哪来。
enum CurriculumSource {
    case builtIn                          // 内置课程（Documents 里没有 curriculum.json）
    case customFile(URL)                  // 已加载外部 curriculum.json
    case invalidFile(URL, reason: String) // 外部文件有问题，已回退内置课程
}

// MARK: - 课程加载器：内置 + 外部 curriculum.json
/// 外部课程文件位置：App 的 Documents 目录（Info.plist 配了 UIFileSharingEnabled，
/// 在 iPhone"文件"App 里可见为"粤语陪练"文件夹）。用户把按模板写好的 curriculum.json
/// 放进去，点设置页"重新载入课程"即生效，无需重新发版。
/// 校验不通过 / 解析失败时回退内置课程，并在设置页显示原因。
enum CurriculumLoader {
    /// App 读取的外部课程文件名
    static let fileName = "curriculum.json"
    /// 导出的模板文件名（与读取文件区分开，避免覆盖用户已有的 curriculum.json）
    static let templateFileName = "curriculum-template.json"

    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    static var fileURL: URL { documentsURL.appendingPathComponent(fileName) }
    static var templateURL: URL { documentsURL.appendingPathComponent(templateFileName) }

    /// 加载课程：外部文件存在则解析 + 校验，失败回退内置。
    static func load(fallback: [CourseTheme]) -> (curriculum: [CourseTheme], source: CurriculumSource) {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            return (fallback, .builtIn)
        }
        do {
            let data = try Data(contentsOf: url)
            let themes = try JSONDecoder().decode([CourseTheme].self, from: data)
            if let reason = validate(themes) {
                return (fallback, .invalidFile(url, reason: reason))
            }
            return (themes, .customFile(url))
        } catch {
            return (fallback, .invalidFile(url, reason: "解析失败：\(error.localizedDescription)"))
        }
    }

    /// 校验外部课程：返回 nil 表示通过，否则返回中文原因（设置页展示）。
    /// 注意：主题 id 不要改——跟读进度、兴趣选择、测验范围都靠 id 关联。
    static func validate(_ themes: [CourseTheme]) -> String? {
        if themes.isEmpty { return "课程为空，至少需要 1 个主题" }
        var seen = Set<String>()
        for (i, theme) in themes.enumerated() {
            let label = "第 \(i + 1) 个主题"
            if theme.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "\(label)缺少 id"
            }
            if !seen.insert(theme.id).inserted {
                return "主题 id 重复：\(theme.id)"
            }
            if theme.titleZh.isEmpty { return "主题「\(theme.id)」缺少中文标题" }
            if theme.words.isEmpty { return "主题「\(theme.titleZh)」没有单词" }
            for (j, w) in theme.words.enumerated() {
                if w.cantonese.isEmpty || w.jyutping.isEmpty || w.mandarin.isEmpty {
                    return "主题「\(theme.titleZh)」第 \(j + 1) 个词字段不完整"
                }
            }
            if theme.sentences.isEmpty { return "主题「\(theme.titleZh)」没有场景句" }
            for (j, s) in theme.sentences.enumerated() {
                if s.cantonese.isEmpty || s.jyutping.isEmpty || s.mandarin.isEmpty {
                    return "主题「\(theme.titleZh)」第 \(j + 1) 句字段不完整"
                }
                // 基础粤拼检查：字数（去标点空白）== 粤拼音节数
                let chars = s.cantonese.filter { !$0.isWhitespace && !$0.isPunctuation }
                let syllables = s.jyutping.split { $0.isWhitespace }
                if chars.count != syllables.count {
                    return "主题「\(theme.titleZh)」第 \(j + 1) 句：\(chars.count) 个字但 \(syllables.count) 个粤拼音节"
                }
            }
        }
        return nil
    }

    /// 导出课程为模板 JSON（UTF-8，格式化），供用户照着改。
    @discardableResult
    static func exportTemplate(_ themes: [CourseTheme]) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(themes)
        try data.write(to: templateURL, options: .atomic)
        return templateURL
    }
}

// MARK: - 课程重载通知
extension Notification.Name {
    /// 外部课程重载完成：聊天页等界面刷新主题列表。
    static let curriculumDidReload = Notification.Name("YueTutorCurriculumDidReload")
}
