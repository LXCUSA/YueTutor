import SwiftUI
import UIKit

/// App 全局视觉规范：主色、圆角、字体集中定义，各 View 统一引用。
enum Theme {
    /// 主色：粤式暖红，用于发送气泡、按钮、chips 高亮等。
    static let accent = Color(red: 0.78, green: 0.18, blue: 0.16)

    /// 卡片 / 气泡圆角。
    static let cornerRadius: CGFloat = 16

    /// 小圆角：chips、胶囊按钮、内嵌提示卡。
    static let smallRadius: CGFloat = 10

    /// 朱红：悬浮按钮用，比主色更亮一档，在深色背景上更醒目。
    static let vermilion = Color(red: 1.0, green: 0.30, blue: 0.0)

    /// 粤拼等宽字体（粤拼用等宽排版更易对照声调数字）。
    static func jyutpingFont(size: CGFloat) -> Font {
        .system(size: size, design: .monospaced)
    }
}

// MARK: - 震动反馈

/// 按钮触感反馈：轻点按钮时调用，`settings.hapticsEnabled` 关闭时不震。
func playHaptic(_ settings: AppSettings, style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    guard settings.hapticsEnabled else { return }
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}
