import SwiftUI

/// App 全局视觉规范：主色、圆角、字体集中定义，各 View 统一引用。
enum Theme {
    /// 主色：粤式暖红，用于发送气泡、按钮、chips 高亮等。
    static let accent = Color(red: 0.78, green: 0.18, blue: 0.16)

    /// 卡片 / 气泡圆角。
    static let cornerRadius: CGFloat = 16

    /// 小圆角：chips、胶囊按钮、内嵌提示卡。
    static let smallRadius: CGFloat = 10

    /// 粤拼等宽字体（粤拼用等宽排版更易对照声调数字）。
    static func jyutpingFont(size: CGFloat) -> Font {
        .system(size: size, design: .monospaced)
    }
}
