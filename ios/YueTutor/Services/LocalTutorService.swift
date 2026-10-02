import Foundation

// MARK: - 本地离线家教（v1 核心）
/// 纯离线：按课程主题 + 关键词匹配 + 小测验状态机组织学习闭环。
/// history / useWebSearch 参数本地用不上，但签名按协议保留。
final class LocalTutorService: TutorService {

// MARK: - 课程数据（粤拼已核对，勿改）
static let curriculum: [CourseTheme] = [
CourseTheme(
id: "greeting",
titleZh: "问候与礼貌",
titleEn: "Greetings",
words: [
CourseWord(cantonese: "你好", jyutping: "nei5 hou2", hakka: "你好(ni ho)", mandarin: "你好"),
CourseWord(cantonese: "早晨", jyutping: "zou2 san4", hakka: "早晨(zo sen)", mandarin: "早上好"),
CourseWord(cantonese: "唔該", jyutping: "m4 goi1", hakka: "唔該(m gai)", mandarin: "谢谢（麻烦别人时说）"),
CourseWord(cantonese: "多謝", jyutping: "do1 ze6", hakka: "多謝(do qia)", mandarin: "谢谢（收到东西时说）"),
CourseWord(cantonese: "唔好意思", jyutping: "m4 hou2 ji3 si3", hakka: "唔好意思(m ho yi si)", mandarin: "不好意思"),
],
sentence: CourseSentence(
cantonese: "好耐冇见，你最近点呀？",
jyutping: "hou2 noi6 mou5 gin3, nei5 zeoi3 gan6 dim2 aa3?",
mandarin: "好久不见，你最近怎么样？"
),
tip: "阳上5声（你 nei5、好 hou2）可以套客家话阳平的升调感觉；hou2 的 ou 是双元音，圆唇收住，别念成单音 hau。"
),
CourseTheme(
id: "number",
titleZh: "数字·时间·钱",
titleEn: "Numbers & Money",
words: [
CourseWord(cantonese: "幾多", jyutping: "gei2 do1", hakka: "几多(ki to)", mandarin: "多少"),
CourseWord(cantonese: "錢", jyutping: "cin4", hakka: "钱(tshien)", mandarin: "钱"),
CourseWord(cantonese: "點鐘", jyutping: "dim2 zung1", hakka: "点钟(tiam zung)", mandarin: "几点钟"),
CourseWord(cantonese: "半", jyutping: "bun3", hakka: "半(pan)", mandarin: "半（半小时）"),
CourseWord(cantonese: "鐘頭", jyutping: "zung1 tau4", hakka: "钟头(zung thiu)", mandarin: "小时"),
],
sentence: CourseSentence(
cantonese: "呢個幾多錢？",
jyutping: "ni1 go3 gei2 do1 cin4?",
mandarin: "这个多少钱？"
),
tip: "粤语阴上调（2声，gei2/dim2）是高升调，客家话上声偏低；读 gei2 时尾音往上挑，像普通话“急”但不要那么促，别读成 gei4（记）。"
),
CourseTheme(
id: "food",
titleZh: "食物·饮品",
titleEn: "Food & Drink",
words: [
CourseWord(cantonese: "食", jyutping: "sik6", hakka: "食(sit)", mandarin: "吃"),
CourseWord(cantonese: "飯", jyutping: "faan6", hakka: "飯(fan)", mandarin: "饭（米饭）"),
CourseWord(cantonese: "飲", jyutping: "jam2", hakka: "飲(yim)", mandarin: "喝"),
CourseWord(cantonese: "茶", jyutping: "caa4", hakka: "茶(tsha)", mandarin: "茶"),
CourseWord(cantonese: "好食", jyutping: "hou2 sik6", hakka: "好吃(ho sit)", mandarin: "好吃（味道好）"),
],
sentence: CourseSentence(
cantonese: "我要一杯凍檸茶，唔該。",
jyutping: "ngo5 jiu3 jat1 bui1 dung3 ning4 caa4, m4 goi1.",
mandarin: "我要一杯冻柠茶，谢谢。"
),
tip: "aa 是长元音（茶 caa4、飯 faan6），嘴张大、音拖长；客家 a 偏短，读短了会变味。对着镜子夸张读「caa——」找拉长感。"
),
CourseTheme(
id: "direction",
titleZh: "出行·方向",
titleEn: "Getting Around",
words: [
CourseWord(cantonese: "行", jyutping: "haang4", hakka: "行(hang)", mandarin: "走；去"),
CourseWord(cantonese: "搭", jyutping: "daap3", hakka: "搭(dap)", mandarin: "乘坐（搭车、搭地铁）"),
CourseWord(cantonese: "轉", jyutping: "zyun2", hakka: "转(zon)", mandarin: "转、换乘"),
CourseWord(cantonese: "左", jyutping: "zo2", hakka: "左(zo)", mandarin: "左"),
CourseWord(cantonese: "右", jyutping: "jau6", hakka: "右(yu)", mandarin: "右"),
],
sentence: CourseSentence(
cantonese: "唔該，去地鐵站點行呀？",
jyutping: "m4 goi1, heoi3 dei6 tit3 zaam6 dim2 haang4 aa3?",
mandarin: "请问，去地铁站怎么走？"
),
tip: "轉 zyun2 的 yu 是撮口元音，客家话里没有；先摆出说“淤”时的口型（嘴唇撮圆收小）定住再发音，多练「轉車 zyun2 ce1」「遠 jyun5」。"
),
CourseTheme(
id: "shopping",
titleZh: "购物·砍价",
titleEn: "Shopping",
words: [
CourseWord(cantonese: "減價", jyutping: "gaam2 gaa3", hakka: "减价(gam ga)", mandarin: "降价、打折"),
CourseWord(cantonese: "平", jyutping: "ping4", hakka: "平(piang)", mandarin: "便宜"),
CourseWord(cantonese: "貴", jyutping: "gwai3", hakka: "贵(gui)", mandarin: "贵"),
CourseWord(cantonese: "抵", jyutping: "dai2", hakka: "抵(dai)", mandarin: "划算、值"),
CourseWord(cantonese: "價錢", jyutping: "gaa3 cin4", hakka: "价钱(ga qien)", mandarin: "价格"),
],
sentence: CourseSentence(
cantonese: "老闆，平啲得唔得呀？",
jyutping: "lou5 ban2, ping4 di1 dak1 m4 dak1 aa3?",
mandarin: "老板，便宜一点行不行？"
),
tip: "減價、價錢的 aa 要拉长（嘴张大、拖半拍）才有粤语味；折 zit3 是入声 -t 收尾，客家话有入声，直接借力、短促收住别拖出元音。"
),
CourseTheme(
id: "family",
titleZh: "家庭·日常",
titleEn: "Family",
words: [
CourseWord(cantonese: "爸爸", jyutping: "baa4 baa1", hakka: "爸爸(pa pa)", mandarin: "爸爸"),
CourseWord(cantonese: "媽媽", jyutping: "maa4 maa1", hakka: "妈妈(ma ma)", mandarin: "妈妈"),
CourseWord(cantonese: "食飯", jyutping: "sik6 faan6", hakka: "食饭(sit fan)", mandarin: "吃饭"),
CourseWord(cantonese: "瞓覺", jyutping: "fan3 gaau3", hakka: "瞓觉(fun kau)", mandarin: "睡觉"),
CourseWord(cantonese: "返工", jyutping: "faan1 gung1", hakka: "返工(fan kung)", mandarin: "上班"),
],
sentence: CourseSentence(
cantonese: "阿爸今晚唔返嚟食飯？",
jyutping: "aa3 baa4 gam1 maan5 m4 faan1 lai4 sik6 faan6?",
mandarin: "爸爸今晚不回来吃饭吗？"
),
tip: "返 faan1、飯 faan6 的 aa 拉长；瞓 fan3 先圆唇再收 -n 鼻音，别读松了。"
),
]

// MARK: - 会话状态
/// 当前主题 id（用户最近一次进入的主题）
var currentThemeId: String?
/// 待公布答案的测验词
var pendingQuiz: CourseWord?
/// 跟读计数：themeId -> 该主题场景句已读对的遍数（过关后清零）
var readAlongCount: [String: Int] = [:]
/// 跟读过关所需的正确遍数
static let readAlongPassCount = 2
/// 当前期待跟读的主题 id（刚展示了场景句，等用户跟读）
var pendingReadAlong: String?
/// 跟读失败计数：themeId -> 连错次数（读对后清零）
var readAlongFails: [String: Int] = [:]
/// 暂时跳过的主题 id（多次读不对），绕完一圈后重新加入练习
var deferredThemes: [String] = []
/// 跟读连错几次后智能跳过
static let readAlongMaxFails = 3
/// 判定"用户在尝试跟读"的字符重合度阈值（0~1）
static let readAlongAttemptThreshold = 0.4

// MARK: - 主题查询
/// 按主题 id 取主题
func theme(id: String) -> CourseTheme? {
Self.curriculum.first { $0.id == id}
}

/// 下一个练习主题：跳过 deferred 的难句；绕完一圈后把 deferred 清空
///（之前跳过的重新出现，即"以后重试"）；极端全跳过时清空重来，绝不死循环
private func nextPracticeTheme(after id: String) -> CourseTheme {
let n = Self.curriculum.count
guard let idx = Self.curriculum.firstIndex(where: { $0.id == id }) else { return Self.curriculum[0] }
let nextIdx = (idx + 1) % n
if nextIdx == 0, !deferredThemes.isEmpty {
deferredThemes = []
return Self.curriculum[0]
}
var i = nextIdx
var guardCount = 0
while deferredThemes.contains(Self.curriculum[i].id), guardCount < n {
i = (i + 1) % n
guardCount += 1
}
if guardCount >= n { deferredThemes = [] }
return Self.curriculum[i]
}

/// 输入与目标句的字符重合度（0~1），用于判断用户是否在尝试跟读（而非闲聊）
private static func similarity(_ input: String, _ target: String) -> Double {
let a = Set(plainText(input)), b = Set(plainText(target))
guard !b.isEmpty else { return 0 }
return Double(a.intersection(b).count) / Double(b.count)
}

/// 按主题名/关键词匹配用户输入
func theme(matching text: String) -> CourseTheme? {
let trimmed = text.trimmingCharacters(in:.whitespacesAndNewlines)
guard !trimmed.isEmpty else { return nil}
let lower = trimmed.lowercased()
// 1. 精确匹配：id / 中文名 / 英文名
for theme in Self.curriculum {
if lower == theme.id { return theme}
if trimmed == theme.titleZh { return theme}
if lower == theme.titleEn.lowercased() { return theme}
}
// 2. 关键词匹配：中文关键词用子串匹配，英文关键词用单词匹配（避免 "this" 误含 "hi"）
let keywordMap: [(id: String, keywords: [String])] = [
("greeting", ["你好", "问候", "問候", "礼貌", "禮貌", "打招呼", "greeting", "hello", "hi"]),
("number", ["钱", "錢", "数字", "數字", "多少", "时间", "時間", "几点", "幾點", "钟点", "鐘點", "number", "money"]),
("food", ["吃", "喝", "茶", "饭", "飯", "食", "飲", "饮", "食物", "饮品", "飲品", "food", "drink"]),
("direction", ["路", "方向", "地铁", "地鐵", "出行", "转车", "轉車", "怎么走", "點行", "点行", "direction", "metro"]),
("shopping", ["买", "買", "便宜", "贵", "貴", "砍价", "砍價", "购物", "購物", "打折", "减价", "減價", "平", "shop"]),
("family", ["爸爸", "妈妈", "媽媽", "爸", "妈", "媽", "家", "家庭", "family"]),
]
let tokens = lower.split(whereSeparator: {!$0.isLetter}).map(String.init)
for entry in keywordMap {
for keyword in entry.keywords {
let isASCII = keyword.unicodeScalars.allSatisfy { $0.isASCII}
if isASCII {
if tokens.contains(keyword.lowercased()) { return theme(id: entry.id)}
} else if trimmed.contains(keyword) {
return theme(id: entry.id)
}
}
}
return nil
}

// MARK: - 对话入口
func sendChat(profile: TutorProfile, history: [ChatTurn], userText: String, useWebSearch: Bool) async throws -> Lesson {
let text = userText.trimmingCharacters(in:.whitespacesAndNewlines)

// 1. 开场：输入为空，问好 + 自我介绍 + 列出 6 个主题
if text.isEmpty {
return greetingLesson()
}

// 2. 跟读正确：输入与场景句去标点/空白后一致即算跟读（用户常省略标点），
//    先于主题关键词匹配，保证快捷按钮和手动输入都能进跟读。
//    每句读对 readAlongPassCount 遍即过关，自动进入下一主题的场景句，避免无限重复。
let plainInput = Self.plainText(text)
if let theme = Self.curriculum.first(where: { Self.plainText($0.sentence.cantonese) == plainInput }) {
currentThemeId = theme.id
readAlongFails[theme.id] = 0
deferredThemes.removeAll { $0 == theme.id }
let count = (readAlongCount[theme.id] ?? 0) + 1
if count >= Self.readAlongPassCount {
readAlongCount[theme.id] = 0
let next = nextPracticeTheme(after: theme.id)
currentThemeId = next.id
pendingReadAlong = next.id
return readAlongPassedLesson(passed: theme, next: next)
}
readAlongCount[theme.id] = count
pendingReadAlong = theme.id
return readAlongLesson(theme, round: count)
}

// 2b. 换个主题：按课程顺序切到下一个（跳过已暂存的难句）
if text.contains("换个主题") || text.contains("換個主題") {
let next: CourseTheme
if let cur = currentThemeId {
next = nextPracticeTheme(after: cur)
} else {
next = Self.curriculum[0]
}
currentThemeId = next.id
pendingReadAlong = next.id
return themeLesson(next)
}

// 3. 测验请求：出题（先不给答案）
if isQuizRequest(text) {
pendingReadAlong = nil
return quizLesson()
}

// 4. 有未公布的测验：用户的下一轮输入即公布答案
if let quiz = pendingQuiz {
pendingQuiz = nil
return quizAnswerLesson(word: quiz, userText: text)
}

// 5. 跟读失败：正等用户跟读某句，输入与该句有明显重合却对不上，
//    视为一次跟读尝试（纯闲聊不计）。连错 readAlongMaxFails 次则智能跳过，
//    记下该句，绕完其他主题一圈后重新出现（以后重试）。
if let pendingId = pendingReadAlong,
let pendingTheme = theme(id: pendingId),
Self.similarity(text, pendingTheme.sentence.cantonese) >= Self.readAlongAttemptThreshold {
let fails = (readAlongFails[pendingId] ?? 0) + 1
if fails >= Self.readAlongMaxFails {
readAlongFails[pendingId] = 0
pendingReadAlong = nil
if !deferredThemes.contains(pendingId) { deferredThemes.append(pendingId) }
let next = nextPracticeTheme(after: pendingId)
currentThemeId = next.id
pendingReadAlong = next.id
return readAlongSkippedLesson(skipped: pendingTheme, next: next)
}
readAlongFails[pendingId] = fails
return readAlongRetryLesson(pendingTheme)
}

// 6. 主题匹配：进入主题学习
if let theme = theme(matching: text) {
currentThemeId = theme.id
pendingReadAlong = theme.id
return themeLesson(theme)
}

// 7. 兜底：温和回复 + 列出 6 个主题引导
return fallbackLesson()
}

// MARK: - 各分支 Lesson 构造

/// 开场 Lesson：问好 + 介绍自己是本地粤语陪练 + 列出 6 个主题
private func greetingLesson() -> Lesson {
let themes = Self.curriculum.map(\.titleZh).joined(separator: "、")
return Lesson(
replyCantonese: "你好！我系你嘅离线粤语陪练。我哋可以由下面 6 个主题开始学：\(themes)。你想先学边个？",
replyJyutping: "nei5 hou2! ngo5 hai6 nei5 ge3 loi4 sin3 jyut6 jyu5 pui4 lin6.",
replyEnglish: "你好！我是你的离线粤语陪练。我们可以从下面 6 个主题开始：\(themes)。你想先学哪个？",
breakdown: introWords(),
tip: nil,
suggestedReplies: themeSuggestions(),
difficulty: "beginner"
)
}

/// 主题 Lesson：主题导语 + 场景句，breakdown 放 5 个词，tip 放主题 tip
private func themeLesson(_ theme: CourseTheme) -> Lesson {
Lesson(
replyCantonese: "今日我哋学！先嚟一句最实用嘅场景句：「\(theme.sentence.cantonese)」",
replyJyutping: theme.sentence.jyutping,
replyEnglish: "今天我们学「\(theme.titleZh)」。先来一句最实用的场景句：「\(theme.sentence.mandarin)」",
breakdown: theme.words.map { BreakdownItem(cantonese: $0.cantonese, jyutping: $0.jyutping, english: $0.mandarin)},
tip: theme.tip,
suggestedReplies: [
SuggestedReply(cantonese: "考考我", jyutping: "haau2 haau2 ngo5", english: "来个小测验"),
SuggestedReply(cantonese: theme.sentence.cantonese, jyutping: theme.sentence.jyutping, english: theme.sentence.mandarin),
SuggestedReply(cantonese: "换个主题", jyutping: "wun6 go3 zyu2 tai4", english: "看看其他主题"),
],
difficulty: "beginner"
)
}

/// 测验出题：从当前主题（无则随机）抽一个词，先不给答案，记到 pendingQuiz
private func quizLesson() -> Lesson {
let theme = currentThemeId.flatMap { self.theme(id: $0)}
?? Self.curriculum.randomElement()
?? Self.curriculum[0]
guard let word = theme.words.randomElement() else {
return fallbackLesson()
}
currentThemeId = theme.id
pendingQuiz = word
return Lesson(
replyCantonese: "「\(word.cantonese)」點讀？試下讀出聲或者打粤拼。",
replyJyutping: "",
replyEnglish: "小测验：「\(word.cantonese)」（意思是「\(word.mandarin)」）怎么读？试着读出声，或者打出它的粤拼。答完点「公布答案」。",
breakdown: [],
tip: nil,
suggestedReplies: [
SuggestedReply(cantonese: "公布答案", jyutping: "gung1 bou3 daap3 on3", english: "公布答案"),
],
difficulty: "beginner"
)
}

/// 测验答案：公布正确粤拼，温和中文反馈（先肯定再给一个调整点），清空 pendingQuiz
private func quizAnswerLesson(word: CourseWord, userText: String) -> Lesson {
let quizTheme = Self.curriculum.first { $0.words.contains(word)}
let hint = adjustmentHint(for: word)
let correction: String
if userText.contains(word.cantonese) {
correction = "写对了，「\(word.cantonese)」就系咁写！读嘅时候注意\(hint)，多读两遍就顺口啦。"
} else {
correction = "敢开口就系进步！「\(word.cantonese)」读「\(word.jyutping)」，注意\(hint)，跟住读多一次啦。"
}
return Lesson(
replyCantonese: "答案系「\(word.jyutping)」！",
replyJyutping: word.jyutping,
replyEnglish: "「\(word.cantonese)」读作 \(word.jyutping)，意思是「\(word.mandarin)」。",
breakdown: [BreakdownItem(cantonese: word.cantonese, jyutping: word.jyutping, english: word.mandarin)],
correction: correction,
tip: quizTheme?.tip,
suggestedReplies: [
SuggestedReply(cantonese: "再考一个", jyutping: "zoi3 haau2 jat1 go3", english: "再考一个"),
SuggestedReply(cantonese: "换个主题", jyutping: "wun6 go3 zyu2 tai4", english: "看看其他主题"),
],
difficulty: "beginner"
)
}

/// 跟读 Lesson：第 round 遍读对，鼓励再跟读（附场景句快捷按钮，点一下就能再跟）
private func readAlongLesson(_ theme: CourseTheme, round: Int) -> Lesson {
Lesson(
replyCantonese: "读得唔错！呢句系第 \(round) 遍，跟住我一齐再读多次：「\(theme.sentence.cantonese)」",
replyJyutping: theme.sentence.jyutping,
replyEnglish: "跟读得很好！这是第 \(round) 遍，再跟着粤拼读一遍：「\(theme.sentence.mandarin)」",
breakdown: sentenceKeywords(in: theme),
tip: "跟读建议：先慢速跟准每个字嘅声调，再加速连成一句，一句读够 \(Self.readAlongPassCount) 遍就过关。",
suggestedReplies: [
SuggestedReply(cantonese: theme.sentence.cantonese, jyutping: theme.sentence.jyutping, english: theme.sentence.mandarin),
SuggestedReply(cantonese: "考考我", jyutping: "haau2 haau2 ngo5", english: "来个小测验"),
SuggestedReply(cantonese: "换个主题", jyutping: "wun6 go3 zyu2 tai4", english: "看看其他主题"),
],
difficulty: "beginner"
)
}

/// 跟读没对：温和纠正，再示范一次（不报次数，不给压力）
private func readAlongRetryLesson(_ theme: CourseTheme) -> Lesson {
Lesson(
replyCantonese: "唔紧要，慢慢嚟。听我读一次，你跟住读：「\(theme.sentence.cantonese)」",
replyJyutping: theme.sentence.jyutping,
replyEnglish: "没关系，慢慢来。听我读一遍，你跟着读：「\(theme.sentence.mandarin)」",
breakdown: sentenceKeywords(in: theme),
tip: "跟读建议：先慢速跟准每个字嘅声调，再加速连成一句。",
suggestedReplies: [
SuggestedReply(cantonese: theme.sentence.cantonese, jyutping: theme.sentence.jyutping, english: theme.sentence.mandarin),
SuggestedReply(cantonese: "换个主题", jyutping: "wun6 go3 zyu2 tai4", english: "看看其他主题"),
],
difficulty: "beginner"
)
}

/// 智能跳过：多次读不对，先跳过（绕完一圈后会回来重试），切到下一句
private func readAlongSkippedLesson(skipped: CourseTheme, next: CourseTheme) -> Lesson {
Lesson(
replyCantonese: "呢句有啲拗口，我哋跳过先，迟啲再返嚟试过，你已经好叻啦！下一句嚟啦，跟住读：「\(next.sentence.cantonese)」",
replyJyutping: next.sentence.jyutping,
replyEnglish: "这句有点难，我们先跳过，之后再回来试。你已经很棒了！下一句：「\(next.sentence.mandarin)」",
breakdown: next.words.map { BreakdownItem(cantonese: $0.cantonese, jyutping: $0.jyutping, english: $0.mandarin) },
tip: next.tip,
suggestedReplies: [
SuggestedReply(cantonese: next.sentence.cantonese, jyutping: next.sentence.jyutping, english: next.sentence.mandarin),
SuggestedReply(cantonese: "考考我", jyutping: "haau2 haau2 ngo5", english: "来个小测验"),
SuggestedReply(cantonese: "换个主题", jyutping: "wun6 go3 zyu2 tai4", english: "看看其他主题"),
],
difficulty: "beginner"
)
}

/// 跟读过关 Lesson：肯定 + 自动进入下一主题的场景句
private func readAlongPassedLesson(passed: CourseTheme, next: CourseTheme) -> Lesson {
Lesson(
replyCantonese: "两遍都读啱，好嘢！「\(passed.sentence.cantonese)」过关喇。下一句嚟啦，跟住读：「\(next.sentence.cantonese)」",
replyJyutping: next.sentence.jyutping,
replyEnglish: "两遍都读对了，太棒了！「\(passed.sentence.mandarin)」过关。下一句：「\(next.sentence.mandarin)」",
breakdown: next.words.map { BreakdownItem(cantonese: $0.cantonese, jyutping: $0.jyutping, english: $0.mandarin) },
tip: next.tip,
suggestedReplies: [
SuggestedReply(cantonese: next.sentence.cantonese, jyutping: next.sentence.jyutping, english: next.sentence.mandarin),
SuggestedReply(cantonese: "考考我", jyutping: "haau2 haau2 ngo5", english: "来个小测验"),
SuggestedReply(cantonese: "换个主题", jyutping: "wun6 go3 zyu2 tai4", english: "看看其他主题"),
],
difficulty: "beginner"
)
}

/// 兜底 Lesson：温和中文回复 + 列出 6 个主题名引导
private func fallbackLesson() -> Lesson {
let themes = Self.curriculum.map(\.titleZh).joined(separator: "、")
return Lesson(
replyCantonese: "唔好意思，我暂时听唔明呀。我系离线版粤语陪练，你可以拣下面其中一个主题开始学：\(themes)。",
replyJyutping: "",
replyEnglish: "没听懂你的意思。我是离线版粤语陪练，试试从下面 6 个主题里选一个开始：\(themes)。",
breakdown: introWords(),
tip: nil,
suggestedReplies: themeSuggestions(),
difficulty: "beginner"
)
}

// MARK: - 小工具

/// 去标点去空白后的纯文本（只留字母与数字），用于跟读比对。
/// 比对前做两层归一化：
/// 1. 简→繁（ICU Hans-Hant）：语音识别（zh-HK）输出繁体如 點，课程多为简体如 点，实为同字；
/// 2. 粤语语气词异体归一：呀/嗄→啊（同为 aa3），避免"點啊"被判错。
static func plainText(_ s: String) -> String {
let traditional = (s as NSString).applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? s
let particleMap: [Character: Character] = ["呀": "啊", "嗄": "啊"]
return String(traditional.compactMap { ch -> Character? in
let c = particleMap[ch] ?? ch
return (c.isLetter || c.isNumber) ? c : nil
})
}

/// 两个入门词：你好、早晨
private func introWords() -> [BreakdownItem] {
[
BreakdownItem(cantonese: "你好", jyutping: "nei5 hou2", english: "你好"),
BreakdownItem(cantonese: "早晨", jyutping: "zou2 san4", english: "早上好"),
]
}

/// 6 个主题名快捷回复
private func themeSuggestions() -> [SuggestedReply] {
Self.curriculum.map { SuggestedReply(cantonese: $0.titleZh, jyutping: "", english: $0.titleEn)}
}

/// 是否为测验请求：含"考考我/考我/测验"或 quiz 单词
private func isQuizRequest(_ text: String) -> Bool {
if text.contains("考考我") || text.contains("考我") || text.contains("测验") || text.contains("測驗") {
return true
}
let tokens = text.lowercased().split(whereSeparator: {!$0.isLetter}).map(String.init)
return tokens.contains("quiz")
}

/// 根据粤拼特征给一个简短的发音调整点（用于测验反馈）
private func adjustmentHint(for word: CourseWord) -> String {
let jyutping = word.jyutping
if jyutping.contains("yu") {
return "「yu」要撮口（嘴唇收圆收小）再发音"
}
if jyutping.contains("aa") {
return "「aa」系长元音，嘴张大、音拖长"
}
let syllables = jyutping.split(separator: " ")
if let last = syllables.last, last.count >= 2 {
let chars = Array(last)
let coda = chars[chars.count - 2]
if coda == "p" || coda == "t" || coda == "k" {
return "入声（-\(coda) 收尾）要短促收住，唔好拖出元音"
}
}
let tones = syllables.compactMap { $0.last}.filter { $0.isNumber}
if tones.contains("2") || tones.contains("5") {
return "第 2/5 声系升调，尾音往上挑"
}
return "把每个字嘅声调读准"
}

/// 场景句关键词拆解：先找全部主题词里出现在句中的词（长词优先、去包含），
/// 不足 2 个时用标点分段补齐，最多 3 个
private func sentenceKeywords(in theme: CourseTheme) -> [BreakdownItem] {
let sentence = theme.sentence.cantonese
let allWords = Self.curriculum.flatMap { $0.words}
.sorted { $0.cantonese.count > $1.cantonese.count}
var matched: [CourseWord] = []
for word in allWords {
guard sentence.contains(word.cantonese) else { continue}
// 跳过已被更长词覆盖的短词（如已选"食飯"就不再选"食"），也去重
if matched.contains(where: { $0.cantonese.contains(word.cantonese)}) { continue}
matched.append(word)
if matched.count >= 3 { break}
}
// 按在句中出现的先后顺序排列
matched.sort {
let a = sentence.range(of: $0.cantonese)?.lowerBound ?? sentence.startIndex
let b = sentence.range(of: $1.cantonese)?.lowerBound ?? sentence.startIndex
return a < b
}
var items = matched.map { BreakdownItem(cantonese: $0.cantonese, jyutping: $0.jyutping, english: $0.mandarin)}
if items.count < 2 {
for segment in alignedSegments(of: theme.sentence) where items.count < 3 {
if !items.contains(where: { $0.cantonese == segment.cantonese}) {
items.append(segment)
}
}
}
return Array(items.prefix(3))
}

/// 把场景句按标点切成短语段；粤语/粤拼/普通话三段数量一致时对齐返回
private func alignedSegments(of sentence: CourseSentence) -> [BreakdownItem] {
let separators = CharacterSet(charactersIn: "，,？?。.!！、；;：:")
func split(_ s: String) -> [String] {
s.components(separatedBy: separators)
.map { $0.trimmingCharacters(in:.whitespaces)}
.filter {!$0.isEmpty}
}
let cantoneseParts = split(sentence.cantonese)
let jyutpingParts = split(sentence.jyutping)
let mandarinParts = split(sentence.mandarin)
guard !cantoneseParts.isEmpty,
cantoneseParts.count == jyutpingParts.count,
cantoneseParts.count == mandarinParts.count else {
return []
}
return zip(zip(cantoneseParts, jyutpingParts), mandarinParts).map {
BreakdownItem(cantonese: $0.0.0, jyutping: $0.0.1, english: $0.1)
}
}
}
