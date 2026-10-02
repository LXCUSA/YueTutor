import SwiftUI

/// 设置页：个人信息（名字 / 水平单选 / 兴趣多选 / 家教名字，逐项可配、改动即存）/
/// 家教模式（v1 固定本地离线，不提供切换）/ 语速 / 自动朗读 / 版本号。
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var customInterest = ""

    /// 预设兴趣的本地化 key（与 OnboardingView 共用：美食 / 旅行 / 购物 / 科技 / 音乐 / 电影）。
    private let presetInterestKeys = [
        "onboarding.interest_food",
        "onboarding.interest_travel",
        "onboarding.interest_shopping",
        "onboarding.interest_tech",
        "onboarding.interest_music",
        "onboarding.interest_movie",
    ]

    private var presetInterestTitles: [String] {
        presetInterestKeys.map { L10n.t($0) }
    }

    /// 已选的自定义兴趣（不在预设里的）。
    private var customInterests: [String] {
        profileStore.profile.interests.filter { !presetInterestTitles.contains($0) }
    }

    var body: some View {
        NavigationStack {
            Form {
                // 个人信息：名字 / 家教名字 / 水平（单选），改动即时保存
                Section(header: Text(L10n.t("settings.profile_section"))) {
                    TextField(L10n.t("settings.profile_name"), text: Binding(
                        get: { profileStore.profile.name },
                        set: { profileStore.setName($0) }
                    ))
                    TextField(L10n.t("settings.profile_tutor"), text: Binding(
                        get: { profileStore.profile.tutorName },
                        set: { profileStore.setTutorName($0) }
                    ))
                    Picker(L10n.t("settings.profile_level"), selection: Binding(
                        get: { profileStore.profile.level },
                        set: { profileStore.setLevel($0) }
                    )) {
                        Text(L10n.t("onboarding.level_beginner")).tag(LearnerLevel.beginner)
                        Text(L10n.t("onboarding.level_intermediate")).tag(LearnerLevel.intermediate)
                        Text(L10n.t("onboarding.level_advanced")).tag(LearnerLevel.advanced)
                    }
                    .pickerStyle(.segmented)
                }

                // 兴趣（多选）：预设 chips 开关 + 自定义增删
                Section(header: Text(L10n.t("settings.profile_interests"))) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                        ForEach(presetInterestTitles, id: \.self) { title in
                            let selected = profileStore.profile.interests.contains(title)
                            Button {
                                toggleInterest(title)
                            } label: {
                                Text(title)
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
                    // 已选的自定义兴趣：点 × 移除
                    if !customInterests.isEmpty {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                            ForEach(customInterests, id: \.self) { title in
                                HStack(spacing: 4) {
                                    Text(title)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    Button {
                                        toggleInterest(title)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Theme.accent)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    // 添加自定义兴趣
                    HStack {
                        TextField(L10n.t("settings.profile_custom_placeholder"), text: $customInterest)
                            .onSubmit(addCustomInterest)
                        Button(L10n.t("settings.profile_add"), action: addCustomInterest)
                            .disabled(customInterest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

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

    private func addCustomInterest() {
        let trimmed = customInterest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var current = profileStore.profile.interests
        if !current.contains(trimmed) {
            current.append(trimmed)
            profileStore.setInterests(current)
        }
        customInterest = ""
    }
}
