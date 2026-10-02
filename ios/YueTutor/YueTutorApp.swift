import SwiftUI

/// App 入口：装配全局状态（设置 / 个人信息 / 语音合成），并同步界面语言到 `L10n`。
@main
struct YueTutorApp: App {
    @StateObject private var settings: AppSettings
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var synthesizer = SpeechSynthesizer()

    init() {
        // 先创建设置对象，冷启动时就按用户保存的语言初始化 L10n，
        // 避免首屏视图 init 早于 onAppear 导致语言闪烁。
        let initialSettings = AppSettings()
        _settings = StateObject(wrappedValue: initialSettings)
        L10n.language = initialSettings.appLanguage
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(profileStore)
                .environmentObject(synthesizer)
                .onAppear {
                    // 启动时同步一次（兜底）
                    L10n.language = settings.appLanguage
                }
                .onChange(of: settings.appLanguage) { _, newLanguage in
                    // 设置页切换语言时同步，订阅了 settings 的视图会自动重绘
                    L10n.language = newLanguage
                }
        }
    }
}
