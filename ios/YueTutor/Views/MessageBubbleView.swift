import SwiftUI

/// 家教回复卡片：粤语大字（可朗读）+ 粤拼 + 中文翻译 + 逐词解析 + 温和纠正 + 小贴士 + 建议回复。
struct MessageBubbleView: View {
    // 订阅设置：只为语言切换时刷新界面文字（L10n 为静态读取，需靠观察者触发重绘）。
    @EnvironmentObject var settings: AppSettings

    let lesson: Lesson
    let onSpeak: (String) -> Void
    let onSuggestedReply: (String) -> Void

    init(lesson: Lesson, onSpeak: @escaping (String) -> Void, onSuggestedReply: @escaping (String) -> Void) {
        self.lesson = lesson
        self.onSpeak = onSpeak
        self.onSuggestedReply = onSuggestedReply
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 粤语大字 + 朗读按钮
            HStack(alignment: .top, spacing: 8) {
                Text(lesson.replyCantonese)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer(minLength: 4)
                Button {
                    onSpeak(lesson.replyCantonese)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(Theme.accent)
                }
                .accessibilityLabel(L10n.t("message.speak_hint"))
            }

            // 粤拼（等宽、灰色）
            Text(lesson.replyJyutping)
                .font(Theme.jyutpingFont(size: 14))
                .foregroundColor(.secondary)

            // 中文翻译（Lesson.english 字段实际是简体中文意思）
            Text(lesson.replyEnglish)
                .font(.body)

            if !lesson.breakdown.isEmpty {
                breakdownSection
            }

            // 温和纠正（有才显示）
            if let correction = lesson.correction, !correction.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.t("message.correction_title"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(correction)
                            .font(.subheadline)
                    }
                }
                .padding(10)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
            }

            // 小贴士（有才显示）
            if let tip = lesson.tip, !tip.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.t("message.tip_title"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Text(tip)
                            .font(.subheadline)
                    }
                }
                .padding(10)
                .background(Color.orange.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
            }

            // 建议回复：点则回调 onSuggestedReply（传出粤语原文）
            if !lesson.suggestedReplies.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.t("message.suggested_title"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    ForEach(lesson.suggestedReplies.indices, id: \.self) { index in
                        let reply = lesson.suggestedReplies[index]
                        Button {
                            onSuggestedReply(reply.cantonese)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reply.cantonese)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(reply.jyutping)
                                        .font(Theme.jyutpingFont(size: 11))
                                        .foregroundColor(.secondary)
                                    // SuggestedReply.english 字段实际是简体中文意思
                                    Text(reply.english)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer(minLength: 4)
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Theme.accent.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.smallRadius, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    // MARK: - 逐词解析：汉字｜粤拼｜中文意思

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.t("message.breakdown_title"))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            ForEach(lesson.breakdown.indices, id: \.self) { index in
                let item = lesson.breakdown[index]
                HStack(spacing: 8) {
                    Text(item.cantonese)
                        .fontWeight(.medium)
                    Text(item.jyutping)
                        .font(Theme.jyutpingFont(size: 12))
                        .foregroundColor(.secondary)
                    // BreakdownItem.english 字段实际是简体中文意思
                    Text(item.english)
                        .foregroundColor(.secondary)
                    Spacer(minLength: 0)
                }
                .font(.subheadline)
            }
        }
        .padding(.top, 2)
    }
}
