import SwiftUI

// MARK: - 今日打卡卡片（课程页顶部）
/// 点进入打卡详情；进度实时显示。
struct DailyCheckinCard: View {
    @EnvironmentObject private var checkinService: DailyCheckinService

    var body: some View {
        NavigationLink {
            DailyCheckinDetailView()
        } label: {
            HStack(spacing: 12) {
                Text("🌅")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 4) {
                    if let checkin = checkinService.checkin {
                        Text("\(L10n.t("checkin.today")) · \(checkin.date) \(checkin.weekday)")
                            .font(.headline)
                        Text(checkin.theme)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text(L10n.t("checkin.today"))
                            .font(.headline)
                        Text(L10n.t("checkin.empty"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                let p = checkinService.progress
                if p.total > 0 {
                    Text(String(format: L10n.t("checkin.progress"), p.done, p.total))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                    ProgressView(value: Double(p.done), total: Double(p.total))
                        .frame(width: 60)
                        .tint(Theme.accent)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - 打卡详情：5 词 1 句 1 tip，逐项打勾 + 朗读
struct DailyCheckinDetailView: View {
    @EnvironmentObject private var checkinService: DailyCheckinService
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var synthesizer: SpeechSynthesizer
    @State private var reportMessage: String?

    var body: some View {
        Group {
            if let checkin = checkinService.checkin {
                List {
                    Section(header: Text(L10n.t("checkin.words"))) {
                        ForEach(Array(checkin.words.enumerated()), id: \.offset) { i, word in
                            checkinRow(
                                id: "w\(i)",
                                title: word.cantonese,
                                subtitle: "\(word.jyutping) · \(word.mandarin)",
                                note: "客：\(word.hakka)",
                                speakText: word.cantonese
                            )
                        }
                    }
                    Section(header: Text(L10n.t("checkin.sentence"))) {
                        checkinRow(
                            id: "s0",
                            title: checkin.sentence.cantonese,
                            subtitle: checkin.sentence.jyutping,
                            note: checkin.sentence.mandarin,
                            speakText: checkin.sentence.cantonese
                        )
                    }
                    Section(header: Text(L10n.t("checkin.tip"))) {
                        checkinRow(
                            id: "tip",
                            title: checkin.tip,
                            subtitle: "",
                            note: "",
                            speakText: nil
                        )
                    }
                    Section {
                        Button {
                            Task {
                                let ok = await checkinService.reportToday()
                                reportMessage = ok ? L10n.t("checkin.reported") : L10n.t("checkin.report_failed")
                            }
                        } label: {
                            Text(buttonTitle)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .disabled(!checkinService.isComplete || checkinService.hasReportedToday)
                        if let msg = reportMessage {
                            Text(msg)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text(L10n.t("checkin.empty"))
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(L10n.t("checkin.today"))
    }

    private var buttonTitle: String {
        if checkinService.hasReportedToday { return L10n.t("checkin.reported") }
        return L10n.t("checkin.complete")
    }

    /// 打卡行：标题 + 副标题 + 朗读按钮 + 打勾
    private func checkinRow(id: String, title: String, subtitle: String, note: String, speakText: String?) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if let speakText {
                Button {
                    synthesizer.speak(speakText, rate: settings.speechRate)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(Theme.accent)
                }
                .buttonStyle(.plain)
            }
            Button {
                checkinService.toggle(id)
            } label: {
                Image(systemName: checkinService.doneItems.contains(id) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(checkinService.doneItems.contains(id) ? Theme.accent : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
