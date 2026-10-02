import SwiftUI

/// 底部输入条：麦克风按钮（录音中变红）+ 圆角输入框 + 发送按钮。
struct InputBar: View {
    // 订阅设置：只为语言切换时刷新界面文字（L10n 为静态读取，需靠观察者触发重绘）。
    @EnvironmentObject var settings: AppSettings

    @Binding var text: String
    let isRecording: Bool
    let isSending: Bool
    let onMic: () -> Void
    let onSend: () -> Void

    init(text: Binding<String>, isRecording: Bool, isSending: Bool, onMic: @escaping () -> Void, onSend: @escaping () -> Void) {
        self._text = text
        self.isRecording = isRecording
        self.isSending = isSending
        self.onMic = onMic
        self.onSend = onSend
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onMic) {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .font(.system(size: 18))
                    .foregroundColor(isRecording ? .white : Theme.accent)
                    .frame(width: 40, height: 40)
                    .background(isRecording ? Color.red : Theme.accent.opacity(0.12))
                    .clipShape(Circle())
            }
            .accessibilityLabel(L10n.t(isRecording ? "input.mic_stop_hint" : "input.mic_hint"))

            TextField(L10n.t("input.placeholder"), text: $text, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button(action: onSend) {
                Group {
                    if isSending {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(canSend ? Theme.accent : Color.gray.opacity(0.35))
                .clipShape(Circle())
            }
            .disabled(!canSend)
            .accessibilityLabel(L10n.t("input.send_hint"))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    /// 有文字且不在发送中时才可点发送。
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }
}
