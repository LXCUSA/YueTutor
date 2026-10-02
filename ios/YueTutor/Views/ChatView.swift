import SwiftUI

/// 聊天页：顶栏（家教名）+ 话题 chips + 消息流 + 底部输入条。
struct ChatView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var synthesizer: SpeechSynthesizer

    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var recognizer = SpeechRecognizer()
    @State private var inputText = ""

    /// 顶部话题 chips：课程全部主题（中文名），横向滚动。
    private var topics: [CourseTheme] {
        LocalTutorService.curriculum
    }

    var body: some View {
        VStack(spacing: 0) {
            topicChips
            Divider()
            messageList
            if let recognitionError = recognizer.errorMessage, !recognizer.isRecording {
                Text(recognitionError)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
            InputBar(
                text: $inputText,
                isRecording: recognizer.isRecording,
                isSending: viewModel.isSending,
                onMic: { recognizer.toggle() },
                onSend: sendInput
            )
        }
        .onAppear {
            viewModel.configure(settings: settings, profileStore: profileStore, synthesizer: synthesizer)
            viewModel.startIfNeeded()
        }
        .onChange(of: recognizer.transcript) { _, transcript in
            // 录音过程中把识别结果实时填入输入框
            if recognizer.isRecording {
                inputText = transcript
            }
        }
    }

    // MARK: - 话题 chips

    private var topicChips: some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollViewReader { chipProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(topics, id: \.id) { theme in
                            let isCurrent = theme.id == viewModel.currentTopicId
                            Button {
                                viewModel.switchTopic(theme.titleZh)
                            } label: {
                                Text(theme.titleZh)
                                    .font(.system(size: 17))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(isCurrent ? Theme.accent : Theme.accent.opacity(0.10))
                                    .foregroundColor(isCurrent ? .white : Theme.accent)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isSending)
                            .id(theme.id)
                        }
                    Button {
                        viewModel.askForQuiz()
                    } label: {
                        Text(L10n.t("chat.quiz"))
                            .font(.system(size: 17))
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Theme.accent.opacity(0.10))
                            .foregroundColor(Theme.accent)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSending)
                }
                .padding(.horizontal)
            }
            // 当前主题变化时，把对应的 chip 滚到可视区（16 个主题横向排布，
            // 打字/"换个主题"切换后高亮的 chip 可能在屏幕外）
            .onChange(of: viewModel.currentTopicId) { _, newId in
                guard let newId else { return }
                withAnimation {
                    chipProxy.scrollTo(newId, anchor: .center)
                }
            }
        }
        .padding(.vertical, 8)
    }
    }

    // MARK: - 消息列表

    /// 键盘收起灵敏度：手指在消息列表上拖动超过该距离（pt）即收键盘。
    /// 0 ≈ .immediately（一碰就收）；越大越不灵敏。20 是中间值。
    private let keyboardDismissDragThreshold: CGFloat = 20

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        messageRow(message)
                            .id(message.id)
                    }
                    // 底部锚点：学习者发消息时滚到底部
                    Color.clear
                        .frame(height: 1)
                        .id("bottomAnchor")
                }
                .padding()
            }
            .scrollDismissesKeyboard(.never)
            .simultaneousGesture(
                DragGesture(minimumDistance: keyboardDismissDragThreshold)
                    .onChanged { _ in dismissKeyboard() }
            )
            // 学习者发消息（count 增加）：滚到底部，即时反馈
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
                }
            }
            // 家教回复送达（pending 原地替换为正式内容）：新消息从顶部开始显示。
            // 两点教训：① 必须等 LazyVStack 量好新内容高度后再定位，否则停半中间——
            // async 一轮不够（16 张主题卡片量高度需要时间），等 0.25s；
            // ② 定位不要做动画：内容高度变化时动画滚动会插值漂移，直接瞬间定位最准。
            .onChange(of: viewModel.tutorDeliveryNonce) { _, _ in
                guard let id = viewModel.lastTutorMessageID else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    proxy.scrollTo(id, anchor: .top)
                }
            }
        }
    }

    /// 单条消息行：学习者右气泡，家教用卡片 / 思考中 / 失败提示。
    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
        switch message.role {
        case .learner:
            HStack {
                Spacer(minLength: 48)
                Text(message.text ?? "")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.accent)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            }
        case .tutor:
            HStack {
                if message.isPending {
                    pendingBubble(message)
                } else if let lesson = message.lesson {
                    MessageBubbleView(
                        lesson: lesson,
                        onSpeak: { viewModel.speak($0) },
                        onSuggestedReply: { viewModel.sendLearner($0) }
                    )
                }
                Spacer(minLength: 48)
            }
        }
    }

    /// 思考中气泡：转圈；失败时显示错误文案，点击重试。
    @ViewBuilder
    private func pendingBubble(_ message: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let errorText = message.errorText {
                Button {
                    viewModel.retryFailed()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(errorText)
                            .font(.footnote)
                            .foregroundColor(.red)
                        Text(L10n.t("chat.error_retry"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            } else {
                ProgressView()
                    .tint(Theme.accent)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    // MARK: - 发送

    private func sendInput() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if recognizer.isRecording {
            recognizer.stop()
        }
        viewModel.sendLearner(text)
        inputText = ""
    }
}
