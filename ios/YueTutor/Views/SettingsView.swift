import SwiftUI

/// 设置页：语速 / 自动朗读 / 版本号。
/// v1 只有本地课程：不显示家教模式切换和 AI 代理配置；个人信息 v1 本地链路不消费，也不在此显示。
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                // 语音：语速 + 自动朗读
                Section(header: Text(L10n.t("settings.voice_section"))) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(L10n.t("settings.speech_rate"))
                            Spacer()
                            Text(String(format: "%.2f", settings.speechRate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.speechRate, in: 0.3...0.7, step: 0.05)
                            .tint(Theme.accent)
                    }
                    Toggle(L10n.t("settings.auto_speak"), isOn: $settings.autoSpeak)
                        .tint(Theme.accent)
                }

                // 版本号
                Section {
                    Text(L10n.t("settings.version"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(L10n.t("settings.attribution"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle(L10n.t("settings.title"))
        }
    }
}
