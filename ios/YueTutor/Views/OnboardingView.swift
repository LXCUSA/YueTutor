import SwiftUI

/// 新手引导：名字 → 水平 → 兴趣（至少选 1 个）+ 家教名字，完成后写入 ProfileStore。
struct OnboardingView: View {
    @EnvironmentObject private var profileStore: ProfileStore
    // 订阅设置：只为语言切换时刷新界面文字（L10n 为静态读取，需靠观察者触发重绘）。
    @EnvironmentObject var settings: AppSettings

    @State private var step = 0
    @State private var name = ""
    @State private var level: LearnerLevel = .beginner
    @State private var interests: [String] = []
    @State private var customInterest = ""
    @State private var tutorName: String

    /// 预设兴趣的本地化 key（美食 / 旅行 / 购物 / 科技 / 音乐 / 电影）。
    private let presetInterestKeys = [
        "onboarding.interest_food",
        "onboarding.interest_travel",
        "onboarding.interest_shopping",
        "onboarding.interest_tech",
        "onboarding.interest_music",
        "onboarding.interest_movie",
    ]

    init() {
        _tutorName = State(initialValue: L10n.t("onboarding.tutor_default"))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题
            VStack(spacing: 8) {
                Text(L10n.t("onboarding.title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(L10n.t("onboarding.subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 48)
            .padding(.horizontal)

            // 步骤指示
            Text(String(format: L10n.t("onboarding.step_of"), step + 1))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 16)
            stepDots
                .padding(.top, 8)

            // 步骤内容（小屏可滚动）
            ScrollView {
                Group {
                    switch step {
                    case 0: nameStep
                    case 1: levelStep
                    default: interestsStep
                    }
                }
                .padding(.top, 24)
            }

            // 上一步 / 下一步（最后一步为开始学习）
            HStack(spacing: 12) {
                if step > 0 {
                    Button(L10n.t("onboarding.back")) {
                        step -= 1
                    }
                    .buttonStyle(.bordered)
                }
                Button(step < 2 ? L10n.t("onboarding.next") : L10n.t("onboarding.start")) {
                    if step < 2 {
                        step += 1
                    } else {
                        finish()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(!canProceed)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
    }

    // MARK: - 步骤指示点

    private var stepDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index <= step ? Theme.accent : Color.gray.opacity(0.25))
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - 第一步：名字

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("onboarding.name_title"))
                .font(.title2)
                .fontWeight(.semibold)
            TextField(L10n.t("onboarding.name_placeholder"), text: $name)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .submitLabel(.next)
                .onSubmit {
                    if canProceed { step += 1 }
                }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - 第二步：水平（三选一）

    private var levelStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("onboarding.level_title"))
                .font(.title2)
                .fontWeight(.semibold)
            ForEach([LearnerLevel.beginner, .intermediate, .advanced], id: \.self) { option in
                Button {
                    level = option
                } label: {
                    HStack {
                        Text(levelLabel(option))
                            .foregroundColor(.primary)
                        Spacer()
                        if level == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.accent)
                        }
                    }
                    .padding()
                    .background(level == option ? Theme.accent.opacity(0.10) : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
    }

    private func levelLabel(_ level: LearnerLevel) -> String {
        switch level {
        case .beginner: return L10n.t("onboarding.level_beginner")
        case .intermediate: return L10n.t("onboarding.level_intermediate")
        case .advanced: return L10n.t("onboarding.level_advanced")
        }
    }

    // MARK: - 第三步：兴趣 + 家教名字

    private var interestsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("onboarding.interests_title"))
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(L10n.t("onboarding.interests_hint"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 预设兴趣 chips（可多选）
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                ForEach(presetInterestKeys, id: \.self) { key in
                    let title = L10n.t(key)
                    Button {
                        toggleInterest(title)
                    } label: {
                        Text(title)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(interests.contains(title) ? Theme.accent : Theme.accent.opacity(0.12))
                            .foregroundColor(interests.contains(title) ? .white : Theme.accent)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            // 自定义兴趣
            HStack {
                TextField(L10n.t("onboarding.custom_placeholder"), text: $customInterest)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addCustomInterest)
                Button(L10n.t("onboarding.add"), action: addCustomInterest)
                    .buttonStyle(.bordered)
                    .disabled(customInterest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // 家教名字
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t("onboarding.tutor_title"))
                    .font(.headline)
                TextField(L10n.t("onboarding.tutor_placeholder"), text: $tutorName)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }

    private func toggleInterest(_ title: String) {
        if let index = interests.firstIndex(of: title) {
            interests.remove(at: index)
        } else {
            interests.append(title)
        }
    }

    private func addCustomInterest() {
        let trimmed = customInterest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !interests.contains(trimmed) else { return }
        interests.append(trimmed)
        customInterest = ""
    }

    // MARK: - 校验与完成

    /// 每一步的通过条件：名字必填；兴趣至少选 1 个。
    private var canProceed: Bool {
        switch step {
        case 0:
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return !interests.isEmpty
        default:
            return true
        }
    }

    private func finish() {
        let trimmedTutorName = tutorName.trimmingCharacters(in: .whitespacesAndNewlines)
        profileStore.save(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            level: level,
            interests: interests,
            tutorName: trimmedTutorName.isEmpty ? L10n.t("onboarding.tutor_default") : trimmedTutorName
        )
    }
}
