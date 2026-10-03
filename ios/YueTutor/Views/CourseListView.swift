import SwiftUI

/// 课程列表：`LocalTutorService.curriculum` 的全部主题，点入详情。
struct CourseListView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var synthesizer: SpeechSynthesizer
    @EnvironmentObject private var checkinService: DailyCheckinService

    private var themes: [CourseTheme] {
        LocalTutorService.curriculum
    }

    var body: some View {
        NavigationStack {
            List {
                // 今日打卡卡片
                Section {
                    DailyCheckinCard()
                }
                Section {
                    ForEach(themes, id: \.id) { theme in
                        NavigationLink {
                            CourseDetailView(theme: theme, onSpeak: speak)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(theme.titleZh)
                                        .font(.headline)
                                    Text(theme.titleEn)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(String(format: L10n.t("course.word_count"), theme.words.count))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text(String(format: L10n.t("course.subtitle"), LocalTutorService.curriculum.count))
                }
            }
            .navigationTitle(L10n.t("course.title"))
            .onAppear {
                checkinService.refresh()
            }
        }
    }

    /// 课程朗读：按设置语速读出粤语，由详情页的朗读按钮回调。
    private func speak(_ text: String) {
        synthesizer.speak(text, rate: settings.speechRate)
    }
}
