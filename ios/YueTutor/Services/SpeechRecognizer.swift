import Foundation
import Combine
import AVFoundation
import Speech

// MARK: - 粤语语音识别
/// SFSpeechRecognizer(locale: zh-HK) + AVAudioEngine 实时转写。
/// 需要麦克风和语音识别双授权（requestAuthorization）。
@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var isAvailable: Bool = false
    @Published var errorMessage: String?

    private let recognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "zh-HK"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    /// 请求麦克风 + 语音识别授权；全部通过且识别器可用才返回 true
    func requestAuthorization() async -> Bool {
        let micGranted = await AVAudioApplication.requestRecordPermission()
        let speechStatus = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        let granted = micGranted && speechStatus == .authorized
        let available = granted && recognizer != nil && (recognizer?.isAvailable ?? false)
        isAvailable = available
        if !granted {
            errorMessage = "语音输入需要麦克风和语音识别权限，请到「设置」中开启后再试。"
        } else if recognizer == nil {
            errorMessage = "当前设备不支持粤语（zh-HK）语音识别。"
        } else if !(recognizer?.isAvailable ?? false) {
            errorMessage = "语音识别服务暂不可用，请检查网络后重试。"
        } else {
            errorMessage = nil
        }
        return available
    }

    /// 在开始 / 停止之间切换；开始前先拿到麦克风 + 语音识别双授权，
    /// 否则 installTap 会因 0 声道格式抛 ObjC 异常直接崩溃（见 2026-10-02 .ips）。
    func toggle() {
        if isRecording {
            stop()
        } else {
            Task {
                let ok = await requestAuthorization()
                guard ok else { return }  // 失败原因已由 requestAuthorization 写进 errorMessage
                start()
            }
        }
    }

    /// 开始实时转写（部分结果会实时更新 transcript）
    func start() {
        guard let recognizer = recognizer else {
            errorMessage = "当前设备不支持粤语（zh-HK）语音识别。"
            return
        }
        guard !isRecording else { return }

        // 1. 先配好录音会话 —— 必须在首次触碰 inputNode 之前！
        //    inputNode 是懒创建的，创建那一刻的会话决定了它的声道数，
        //    若先触碰（如下面的 stopEngine）再配会话，格式会永久定格为 0 声道。
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // 先失活再切 category：会话可能停在 TTS 的 .playback 上，
            // 激活状态直接切 category 切不彻底
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "无法启动麦克风：\(error.localizedDescription)"
            return
        }

        // 2. 再清理上一轮的残留状态（这里才会首次触碰 inputNode，此时会话已就绪）
        recognitionTask?.cancel()
        recognitionTask = nil
        stopEngine()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        // 纵深防御：无权限/会话未就绪时 format 可能是 0 声道，
        // 此时 installTap 会抛 ObjC NSException（Swift 无法捕获）导致闪退，绝不能调
        guard format.channelCount > 0, format.sampleRate > 0 else {
            stopEngine()
            errorMessage = "麦克风不可用：未能获取录音格式，请检查麦克风权限后重试。"
            return
        }
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self, weak request] result, error in
            // 识别回调不在主线程，用 Task 跳回 @MainActor 再碰状态
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // 只处理当前轮任务的回调：旧任务被 cancel 后延迟到达的回调直接丢弃，
                // 否则老文本会被写回 transcript、跟新一轮的文本拼接在一起
                guard let request = request, self.recognitionRequest === request else { return }
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                    self.errorMessage = nil
                }
                if error != nil || (result?.isFinal ?? false) {
                    if let nsError = error as NSError?,
                       !(nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110) {
                        // 1110 是"长时间无语音输入"超时，视为正常结束，不报错
                        self.errorMessage = "语音识别出错：\(nsError.localizedDescription)"
                    }
                    self.stopEngine()
                    self.isRecording = false
                    self.recognitionTask = nil
                }
            }
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            // 新一轮录音从空文本开始：旧文本不残留、不与新文本拼接
            //（会触发 ChatView 的 onChange 把输入框同步清空）
            transcript = ""
            errorMessage = nil
        } catch {
            stopEngine()
            recognitionTask?.cancel()
            recognitionTask = nil
            recognitionRequest = nil
            errorMessage = "无法启动麦克风：\(error.localizedDescription)"
        }
    }

    /// 停止转写（保留已识别的文本）
    func stop() {
        recognitionRequest?.endAudio()
        stopEngine()
        isRecording = false
        // recognitionTask 收到最终结果后会在回调里自行清理
    }

    /// 停引擎、拆掉 inputNode 的 tap（不碰 recognitionTask）
    private func stopEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}
