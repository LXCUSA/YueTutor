import SwiftUI

/// 根视图：按是否完成新手引导，切换欢迎页 / 主界面。
struct RootView: View {
    @EnvironmentObject private var profileStore: ProfileStore

    var body: some View {
        Group {
            if profileStore.isOnboarded {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

/// 主界面：聊天 / 课程 / 设置三个 tab。
struct MainTabView: View {
    // 订阅设置：只为语言切换时刷新 tab 标题（L10n 为静态读取，需靠观察者触发重绘）。
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label(L10n.t("tab.chat"), systemImage: "message")
                }
            CourseListView()
                .tabItem {
                    Label(L10n.t("tab.course"), systemImage: "book")
                }
            SettingsView()
                .tabItem {
                    Label(L10n.t("tab.settings"), systemImage: "gear")
                }
        }
    }
}
