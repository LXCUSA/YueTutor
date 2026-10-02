import SwiftUI

/// 设置页：语速 / 自动朗读 / 版本号。
/// v1 只有本地课程：不显示家教模式切换和 AI 代理配置；个人信息 v1 本地链路不消费，也不在此显示。
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var profileStore: ProfileStore

    var body: some View {
        NavigationStack {
            Form {
                // 兴趣（多选）：16 个课程主题，不支持自定义输入
                Section(header: Text(L10n.t("settings.interests_section"))) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                        ForEach(LocalTutorService.curriculum, id: \.id) { theme in
                            let selected = profileStore.profile.interests.contains(theme.titleZh)
                            Button {
                                toggleInterest(theme.titleZh)
                            } label: {
                                Text(theme.titleZh)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .frame(maxWidth: .infinity)
                                    .background(selected ? Theme.accent : Theme.accent.opacity(0.12))
                                    .foregroundColor(selected ? .white : Theme.accent)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

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

    // MARK: - 兴趣多选

    private func toggleInterest(_ title: String) {
        var current = profileStore.profile.interests
        if let index = current.firstIndex(of: title) {
            current.remove(at: index)
        } else {
            current.append(title)
        }
        profileStore.setInterests(current)
    }
}
