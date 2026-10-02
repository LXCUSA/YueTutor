import Foundation

// MARK: - 消息角色
enum MessageRole: String, Codable {
    case learner
    case tutor
}

// MARK: - 聊天消息
/// 聊天列表中的一条消息：学员文本 / 家教课程 / 等待中的家教气泡
struct ChatMessage: Identifiable, Hashable {
    let id: UUID
    let role: MessageRole
    var text: String?
    var lesson: Lesson?
    var isPending: Bool
    var errorText: String?

    /// 学员发出的文本消息
    static func learner(_ text: String) -> ChatMessage {
        ChatMessage(id: UUID(), role: .learner, text: text, lesson: nil, isPending: false, errorText: nil)
    }

    /// 家教返回的一课内容
    static func tutor(_ lesson: Lesson) -> ChatMessage {
        ChatMessage(id: UUID(), role: .tutor, text: nil, lesson: lesson, isPending: false, errorText: nil)
    }

    /// 等待中的家教气泡（请求发出、回答未到时展示）
    static func pendingTutor() -> ChatMessage {
        ChatMessage(id: UUID(), role: .tutor, text: nil, lesson: nil, isPending: true, errorText: nil)
    }
}
