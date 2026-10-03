import SwiftUI

/// 课程详情：生词卡（汉字大字｜粤拼｜客家话近似｜普通话意思，每行一个朗读按钮）
/// + 场景句卡 + 小贴士卡。朗读通过父视图传入的 `onSpeak` 回调。
struct CourseDetailView: View {
    // 订阅设置：只为语言切换时刷新界面文字（L10n 为静态读取，需靠观察者触发重绘）。
    @EnvironmentObject var settings: AppSettings

    let theme: CourseTheme
    let onSpeak: (String) -> Void

    init(theme: CourseTheme, onSpeak: @escaping (String) -> Void) {
        self.theme = theme
        self.onSpeak = onSpeak
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                wordsSection
                sentenceSection
                tipSection
            }
            .padding()
        }
        .navigationTitle(L10n.language == .chinese ? theme.titleZh : theme.titleEn)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 生词

    private var wordsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("course.words_section"))
                .font(.headline)
            ForEach(theme.words.indices, id: \.self) { index in
                wordCard(theme.words[index])
            }
        }
    }

    private func wordCard(_ word: CourseWord) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(word.cantonese)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(word.jyutping)
                    .font(Theme.jyutpingFont(size: 14))
                    .foregroundColor(.secondary)
                Text("\(L10n.t("course.hakka_prefix"))\(word.hakka)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(word.mandarin)
                    .font(.subheadline)
            }
            Spacer(minLength: 4)
            Button {
                onSpeak(word.cantonese)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title3)
                    .foregroundColor(Theme.accent)
            }
            .accessibilityLabel(L10n.t("course.speak_hint"))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    // MARK: - 场景句

    private var sentenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("course.sentence_section"))
                .font(.headline)
            ForEach(theme.sentences.indices, id: \.self) { i in
                let s = theme.sentences[i]
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(s.cantonese)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(s.jyutping)
                            .font(Theme.jyutpingFont(size: 14))
                            .foregroundColor(.secondary)
                        Text(s.mandarin)
                            .font(.body)
                    }
                    Spacer(minLength: 4)
                    Button {
                        onSpeak(s.cantonese)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundColor(Theme.accent)
                    }
                    .accessibilityLabel(L10n.t("course.speak_hint"))
                }
                .padding()
                .background(Theme.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
            }
        }
    }

    // MARK: - 小贴士

    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("course.tip_section"))
                .font(.headline)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                Text(theme.tip)
                    .font(.subheadline)
            }
            .padding()
            .background(Color.orange.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
    }
}
