import Foundation

// MARK: - 打卡结果上报
/// POST 到 Cloudflare Worker（yuetutor-checkin），Worker 校验密钥后写入 KV。
/// 密钥硬编码在 App 里：泄露的最坏情况是有人伪造打卡数据（Worker 有每日限流），
/// 炸不了仓库——真正的写仓库密钥只在 Worker 服务端。
enum CheckinReporter {
    /// Worker 域名（已部署：2026-10-03）
    static let workerBaseURL = "https://yuetutor-checkin.liuxc-usa.workers.dev"
    /// 与 Worker 端 CHECKIN_SECRET 一致
    static let secret = "f530314ad950dc427338c52b3f000186213a06b3cb2482886218545df504494b"

    /// 上报打卡结果，返回是否成功（网络失败返回 false，不抛异常）
    static func report(_ result: CheckinResult) async -> Bool {
        guard let url = URL(string: workerBaseURL + "/checkin") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 15
        req.setValue(secret, forHTTPHeaderField: "X-Checkin-Secret")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(result)
        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}
