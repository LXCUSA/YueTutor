import Foundation

/// 界面文案本地化：不跟随系统语言，只跟 App 内设置（`AppLanguage`）走。
///
/// 用法：`L10n.t("tab.chat")`
/// 文案从 Bundle.main 下 `{language.rawValue}.lproj/Localizable.strings` 读取，
/// 找不到时回退为 key 本身，方便在开发期发现漏配的 key。
enum L10n {
    /// 当前界面语言，由 `YueTutorApp` 在启动和 `appLanguage` 变化时同步。
    static var language: AppLanguage = .chinese

    /// 取 key 对应的本地化文案。
    static func t(_ key: String) -> String {
        table()[key] ?? key
    }

    // MARK: - 私有缓存

    /// 按语言缓存已解析的 strings 表，避免每次渲染都读文件。
    private static var cache: [String: [String: String]] = [:]

    private static func table() -> [String: String] {
        let code = language.rawValue
        if let hit = cache[code] { return hit }
        let loaded = loadStrings(languageCode: code)
        cache[code] = loaded
        return loaded
    }

    /// 从指定语言的 lproj 目录加载 Localizable.strings。
    private static func loadStrings(languageCode: String) -> [String: String] {
        guard let url = Bundle.main.url(
            forResource: "Localizable",
            withExtension: "strings",
            subdirectory: "\(languageCode).lproj"
        ),
        let data = try? Data(contentsOf: url),
        let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
        let dict = plist as? [String: String] else {
            return [:]
        }
        return dict
    }
}
