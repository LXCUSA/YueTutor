import SwiftUI

/// 聊天状态管理：消息流 / 发送 / 朗读 / service 选择。
///
/// service 选择：`settings.tutorMode == .local` 用 `LocalTutorService()`，
/// 否则用 `ProxyTutorService(settings:)`（v1 只走本地，以后 proxy 可用时直接生效）。
@MainActor
final class ChatViewModel: ObservableObject {
    /// 全部聊天消息（含思考中的 pending）。
    @Published var messages: [ChatMessage] = []
    /// 是否正在等待家教回复。
    @Published var isSending = false

    private var settings: AppSettings?
    private var profileStore: ProfileStore?
    private var synthesizer: SpeechSynthesizer?
    private var didStart = false

    // MARK: - 配置

    /// 由 `ChatView.onAppear` 调用，注入依赖。
    func configure(settings: AppSettings, profileStore: ProfileStore, synthesizer: SpeechSynthesizer) {
        self.settings = settings
        self.profileStore = profileStore
        self.synthesizer = synthesizer
    }

    /// 是否已经开场（发过首条请求）。
    var hasStarted: Bool { didStart }

    // MARK: - 开场

    /// 首次进入时调一次：用空消息向 service 要开场白（不显示用户气泡）。
    func startIfNeeded() {
        guard !didStart else { return }
        guard settings != nil, profileStore != nil else { return }
        didStart = true
        Task { await requestReply(userText: "", history: []) }
    }

    // MARK: - 发送

    /// 发送学习者消息。
    func sendLearner(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        guard settings != nil, profileStore != nil else { return }
        let history = recentHistory()
        messages.append(.learner(trimmed))
        Task { await requestReply(userText: trimmed, history: history) }
    }

    /// 切换话题：把主题名作为用户消息发送。
    func switchTopic(_ topic: String) {
        sendLearner(topic)
    }

    /// 发送"考考我"，让家教出题考学习者。
    func askForQuiz() {
        // 发给 service 的是固定中文指令；按钮上的显示文字走 L10n 本地化。
        sendLearner("考考我")
    }

    /// 重试上一次失败的发送：清掉失败的 pending，重发最后一条学习者消息。
    func retryFailed() {
        guard !isSending else { return }
        guard let lastText = messages.last(where: { $0.role == .learner && !$0.isPending })?.text,
              !lastText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        messages.removeAll(where: { $0.isPending })
        sendLearner(lastText)
    }

    // MARK: - 朗读

    /// 按设置语速朗读指定文本。
    func speak(_ text: String) {
        synthesizer?.speak(text, rate: settings?.speechRate ?? 0.5)
    }

    /// 停止朗读。
    func stopSpeaking() {
        synthesizer?.stop()
    }

    // MARK: - 内部

    /// 按设置选择 service。
    private func makeService() -> (any TutorService)? {
        guard let settings else { return nil }
        if settings.tutorMode == .local {
            return LocalTutorService()
        } else {
            return ProxyTutorService(settings: settings)
        }
    }

    /// 最近 20 条有效消息转 `[ChatTurn]`（去掉思考中的 pending；role 用
    /// LLM 通用的 "user" / "assistant"，与服务端 buildMessages 的归一化保持一致）。
    private func recentHistory() -> [ChatTurn] {
        messages.suffix(20).compactMap { message in
            guard !message.isPending else { return nil }
            switch message.role {
            case .learner:
                guard let text = message.text, !text.isEmpty else { return nil }
                return ChatTurn(role: "user", text: text)
            case .tutor:
                let text = message.lesson?.replyCantonese ?? message.text ?? ""
                guard !text.isEmpty else { return nil }
                return ChatTurn(role: "assistant", text: text)
            }
        }
    }

    /// 向 service 请求回复：先挂 pending 气泡，成功替换为家教卡片，失败标 errorText。
    private func requestReply(userText: String, history: [ChatTurn]) async {
        guard let settings, let profileStore, let service = makeService() else { return }
        guard !isSending else { return }
        isSending = true
        defer { isSending = false }

        let pending = ChatMessage.pendingTutor()
        messages.append(pending)
        let pendingID = pending.id

        do {
            let lesson = try await service.sendChat(
                profile: profileStore.profile,
                history: history,
                userText: userText,
                useWebSearch: false
            )
            if let index = messages.firstIndex(where: { $0.id == pendingID }) {
                messages[index] = .tutor(lesson)
            }
            if settings.autoSpeak {
                synthesizer?.speak(lesson.replyCantonese, rate: settings.speechRate)
            }
        } catch {
            if let index = messages.firstIndex(where: { $0.id == pendingID }) {
                messages[index].errorText = L10n.t("error.chat_failed")
            }
        }
    }
}
