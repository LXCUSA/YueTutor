import Foundation

// MARK: - 代理请求错误（全部简体中文描述）
enum APIError: LocalizedError {
    case notConfigured   // 代理地址未配置
    case badURL          // 代理地址格式错误
    case server(String)  // 后端返回错误信息
    case decoding        // 返回数据无法解析

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "代理服务未配置：请先在设置里填写代理地址（Proxy Base URL）。"
        case .badURL:
            return "代理地址格式不正确，请检查设置里的 Proxy Base URL（需以 http:// 或 https:// 开头）。"
        case .server(let message):
            return "服务器返回错误：\(message)"
        case .decoding:
            return "服务器返回的数据格式无法解析，请稍后重试。"
        }
    }
}

// MARK: - 代理 API 客户端
/// POST {proxyBaseURL}/cantonese/chat，header 带 x-app-secret；
/// 后端返回 {ok, lesson, error}（LessonResponse），解码用 convertFromSnakeCase
final class APIClient {
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    func sendChat(_ request: ChatRequest) async throws -> Lesson {
        // 1. 拼 URL：去掉 base 尾部多余的 /，再接路径
        let base = settings.proxyBaseURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
        guard !base.isEmpty else { throw APIError.notConfigured }
        guard let url = URL(string: base + "/cantonese/chat"),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            throw APIError.badURL
        }

        // 2. 组装请求
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 60
        if !settings.appSecret.isEmpty {
            urlRequest.setValue(settings.appSecret, forHTTPHeaderField: "x-app-secret")
        }
        urlRequest.httpBody = try JSONEncoder().encode(request)

        // 3. 发请求
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // 4. 非 2xx：尽量带上后端给的错误信息
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let backendMessage = (try? decoder.decode(LessonResponse.self, from: data))?.error
            if let backendMessage, !backendMessage.isEmpty {
                throw APIError.server(backendMessage)
            }
            throw APIError.server("HTTP 状态码 \(http.statusCode)")
        }

        // 5. 解析返回体
        guard let lessonResponse = try? decoder.decode(LessonResponse.self, from: data) else {
            throw APIError.decoding
        }
        if lessonResponse.ok, let lesson = lessonResponse.lesson {
            return lesson
        }
        if let error = lessonResponse.error, !error.isEmpty {
            throw APIError.server(error)
        }
        throw APIError.decoding
    }
}
