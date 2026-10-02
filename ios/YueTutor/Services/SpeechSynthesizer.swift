import Foundation
import Combine
import AVFoundation

// MARK: - 粤语语音合成
/// AVSpeechSynthesizer，用 zh-HK 语音朗读；speak 传入文本和语速（0.0~1.0）
@MainActor
final class SpeechSynthesizer: ObservableObject {
    @Published var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    private let delegate = SpeechDelegate()

    init() {
        delegate.owner = self
        synthesizer.delegate = delegate
    }

    /// 朗读文本；rate 超出 0.0~1.0 会被钳制。空文本直接忽略。
    func speak(_ text: String, rate: Double) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // 先停掉正在读的，避免叠音
        stop()
        // 关键：朗读前必须把音频会话切到 playback，否则两种情况会无声——
        // (a) 之前用过语音输入，会话停在 SpeechRecognizer 设的 .record 上；
        // (b) 手机静音键打开时，默认会话的 AVSpeechSynthesizer 不发声。
        // .spokenAudio 是专为语音合成设计的 mode。
        do {
            let session = AVAudioSession.sharedInstance()
            // 先失活再切：会话可能停在录音的 .record 上，同上，切不彻底会无声
            try session.setActive(false)
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            // 会话配置失败也不中断，继续尝试播放
        }
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-HK")
            ?? AVSpeechSynthesisVoice(language: "zh-TW")
        utterance.rate = Float(min(max(rate, 0.0), 1.0))
        utterance.pitchMultiplier = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// 停止朗读
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
}

// MARK: - 合成回调转发
/// AVSpeechSynthesizer 的 delegate 回调不在主线程，用 Task 跳回 @MainActor 再更新 isSpeaking
private final class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var owner: SpeechSynthesizer?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor [weak owner] in owner?.isSpeaking = true }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak owner] in owner?.isSpeaking = false }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak owner] in owner?.isSpeaking = false }
    }
}
