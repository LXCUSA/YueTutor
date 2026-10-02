import SwiftUI

/// 聊天页：顶栏（家教名）+ 话题 chips + 消息流 + 底部输入条。
struct ChatView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var synthesizer: SpeechSynthesizer

    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var recognizer = SpeechRecognizer()
    @State private var inputText = ""

    /// 顶部话题 chips：课程前 6 个主题（中文名）。
    private var topics: [CourseTheme] {
        Array(LocalTutorService.curriculum.prefix(6))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
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

    // MARK: - 顶栏：家教名字 + 离线状态 + 停止朗读

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(profileStore.profile.tutorName)
                    .font(.headline)
                Text(L10n.t("chat.header_status"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if synthesizer.isSpeaking {
                Button {
                    viewModel.stopSpeaking()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundColor(Theme.accent)
                }
                .accessibilityLabel(L10n.t("chat.stop_speaking"))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - 话题 chips

    private var topicChips: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.t("chat.topics_title"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(topics, id: \.id) { theme in
                        Button {
                            viewModel.switchTopic(theme.titleZh)
                        } label: {
                            Text(theme.titleZh)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Theme.accent.opacity(0.10))
                                .foregroundColor(Theme.accent)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSending)
                    }
                    Button {
                        viewModel.askForQuiz()
                    } label: {
                        Text(L10n.t("chat.quiz"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Theme.accent)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSending)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - 消息列表

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        messageRow(message)
                    }
                    // 底部锚点：新消息进来时滚到底部
                    Color.clear
                        .frame(height: 1)
                        .id("bottomAnchor")
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo("bottomAnchor", anchor: .bottom)
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
