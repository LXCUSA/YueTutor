import SwiftUI

/// 设置页：家教模式（v1 固定本地离线，不提供切换）/ 语速 / 自动朗读 / 版本号。
/// 个人信息不在此显示：v1 本地链路不消费名字/水平/兴趣/家教名（仅 AI 代理用，已隐藏）。
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                // 家教模式：v1 只支持本地课程，不提供切到 proxy 的 UI
                Section(header: Text(L10n.t("settings.tutor_section"))) {
                    HStack {
                        Text(L10n.t("settings.mode_local"))
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.accent)
                    }
                }

                // AI 陪练代理配置：v1 暂不显示（用户要求），以后启用时取消注释
                // Section(header: Text(L10n.t("settings.proxy_section"))) {
                //     TextField(L10n.t("settings.proxy_url"), text: $settings.proxyBaseURL)
                //         .disabled(true)
                //     SecureField(L10n.t("settings.proxy_secret"), text: $settings.appSecret)
                //         .disabled(true)
                //     Text(L10n.t("settings.proxy_note"))
                //         .font(.footnote)
                //         .foregroundColor(.secondary)
                // }

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
