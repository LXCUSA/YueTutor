import Foundation

// MARK: - 聊天轮次
/// 发给家教服务的历史上下文：role 取 "user" / "assistant"
struct ChatTurn: Codable {
    let role: String
    let text: String
}

// MARK: - 家教服务协议
/// 本地离线家教与代理后端家教都实现这个协议，ViewModel 只依赖协议
protocol TutorService {
    func sendChat(profile: TutorProfile, history: [ChatTurn], userText: String, useWebSearch: Bool) async throws -> Lesson
}
