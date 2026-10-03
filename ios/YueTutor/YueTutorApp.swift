import SwiftUI

/// App 入口：装配全局状态（设置 / 个人信息 / 语音合成）。界面语言跟随系统（中文系→中文，其他→英文）。
@main
struct YueTutorApp: App {
    @StateObject private var settings: AppSettings
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var synthesizer = SpeechSynthesizer()
    @StateObject private var checkinService = DailyCheckinService()

    init() {
        _settings = StateObject(wrappedValue: AppSettings())
        L10n.language = .systemDefault
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .environmentObject(profileStore)
                .environmentObject(synthesizer)
                .environmentObject(checkinService)
        }
    }
}
