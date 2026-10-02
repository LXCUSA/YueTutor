import SwiftUI

/// App 入口：装配全局状态（设置 / 个人信息 / 语音合成）。界面语言固定中文。
@main
struct YueTutorApp: App {
    @StateObject private var settings: AppSettings
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var synthesizer = SpeechSynthesizer()

    init() {
        _settings = StateObject(wrappedValue: AppSettings())
        L10n.language = .chinese
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(profileStore)
                .environmentObject(synthesizer)
        }
    }
}
