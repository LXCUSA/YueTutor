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
CourseWord(cantonese: "初次見面", jyutping: "co1 ci3 gin3 min6", hakka: "初次见面(chhu chhi kien mien)", mandarin: "初次见面"),
CourseWord(cantonese: "麻煩你", jyutping: "maa4 faan4 nei5", hakka: "麻烦你(ma fan ngi)", mandarin: "麻烦你"),
CourseWord(cantonese: "拜拜", jyutping: "baai1 baai3", hakka: "拜拜(pai pai)", mandarin: "拜拜"),
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
CourseWord(cantonese: "今日", jyutping: "gam1 jat6", hakka: "今日(kim ngit)", mandarin: "今天"),
CourseWord(cantonese: "尋日", jyutping: "cam4 jat6", hakka: "寻日(chhim ngit)", mandarin: "昨天"),
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
CourseWord(cantonese: "好味", jyutping: "hou2 mei6", hakka: "好味(ho mi)", mandarin: "好吃"),
CourseWord(cantonese: "埋單", jyutping: "maai4 daan1", hakka: "埋单(mai tan)", mandarin: "买单"),
CourseWord(cantonese: "外賣", jyutping: "ngoi6 maai6", hakka: "外卖(ngoi mai)", mandarin: "外卖"),
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
CourseWord(cantonese: "轉車", jyutping: "zyun3 ce1", hakka: "转车(chon chha)", mandarin: "转车"),
CourseWord(cantonese: "落車", jyutping: "lok6 ce1", hakka: "落车(lok chha)", mandarin: "下车"),
CourseWord(cantonese: "上車", jyutping: "soeng5 ce1", hakka: "上车(shong chha)", mandarin: "上车"),
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
CourseWord(cantonese: "找錢", jyutping: "zaau2 cin2", hakka: "找钱(chau chhien)", mandarin: "找钱"),
CourseWord(cantonese: "收銀", jyutping: "sau1 ngan2", hakka: "收银(shu ngiun)", mandarin: "收银"),
CourseWord(cantonese: "特價", jyutping: "dak6 gaa3", hakka: "特价(thit ka)", mandarin: "特价"),
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
CourseWord(cantonese: "細佬", jyutping: "sai3 lou2", hakka: "细佬(se lau)", mandarin: "弟弟"),
CourseWord(cantonese: "家姐", jyutping: "gaa1 ze1", hakka: "家姐(ka chia)", mandarin: "姐姐"),
CourseWord(cantonese: "哥哥", jyutping: "go4 go1", hakka: "哥哥(ko ko)", mandarin: "哥哥"),
],
sentence: CourseSentence(
cantonese: "阿爸今晚唔返嚟食飯？",
jyutping: "aa3 baa4 gam1 maan5 m4 faan1 lai4 sik6 faan6?",
mandarin: "爸爸今晚不回来吃饭吗？"
),
tip: "返 faan1、飯 faan6 的 aa 拉长；瞓 fan3 先圆唇再收 -n 鼻音，别读松了。"
),CourseTheme(
id: "weather",
titleZh: "天气",
titleEn: "Weather",
words: [
CourseWord(cantonese: "天氣", jyutping: "tin1 hei3", hakka: "天气(thien hi)", mandarin: "天气"),
CourseWord(cantonese: "落雨", jyutping: "lok6 jyu5", hakka: "落雨(lok i)", mandarin: "下雨"),
CourseWord(cantonese: "好熱", jyutping: "hou2 jit6", hakka: "好热(ho ngiet)", mandarin: "很热"),
CourseWord(cantonese: "好凍", jyutping: "hou2 dung3", hakka: "好冻(ho tung)", mandarin: "很冷"),
CourseWord(cantonese: "颱風", jyutping: "toi4 fung1", hakka: "台风(thoi fung)", mandarin: "台风"),
CourseWord(cantonese: "出太陽", jyutping: "ceot1 taai3 joeng4", hakka: "出太阳(chut thai iong)", mandarin: "出太阳"),
CourseWord(cantonese: "涼快", jyutping: "loeng4 faai3", hakka: "凉快(liong khuai)", mandarin: "凉快"),
CourseWord(cantonese: "乾燥", jyutping: "gon1 cou3", hakka: "干燥(kon chau)", mandarin: "干燥"),
],
sentence: CourseSentence(
cantonese: "聽日會落雨，記得帶遮。",
jyutping: "ting1 jat6 wui5 lok6 jyu5, gei3 dak1 daai3 ze1.",
mandarin: "明天会下雨，记得带伞。"
),
tip: "入聲 -k 尾（熱 jit6、落 lok6）要短促收住，別拖長；遮 ze1 是陰平高平調。"
),
CourseTheme(
id: "doctor",
titleZh: "睇醫生",
titleEn: "Seeing a Doctor",
words: [
CourseWord(cantonese: "醫生", jyutping: "ji1 sang1", hakka: "医生(yi sen)", mandarin: "医生"),
CourseWord(cantonese: "唔舒服", jyutping: "m4 syu1 fuk6", hakka: "唔舒服(m shu fuk)", mandarin: "不舒服"),
CourseWord(cantonese: "發燒", jyutping: "faat3 siu1", hakka: "发烧(fat sheu)", mandarin: "发烧"),
CourseWord(cantonese: "頭痛", jyutping: "tau4 tung3", hakka: "头痛(theu thung)", mandarin: "头痛"),
CourseWord(cantonese: "藥", jyutping: "joek6", hakka: "药(iok)", mandarin: "药"),
CourseWord(cantonese: "感冒", jyutping: "gam2 mou6", hakka: "感冒(kam mau)", mandarin: "感冒"),
CourseWord(cantonese: "休息", jyutping: "jau1 sik1", hakka: "休息(hiu sit)", mandarin: "休息"),
CourseWord(cantonese: "睇醫生", jyutping: "tai2 ji1 sang1", hakka: "睇医生(thai yi sen)", mandarin: "看医生"),
],
sentence: CourseSentence(
cantonese: "我有啲發燒，聽日去睇醫生。",
jyutping: "ngo5 jau5 di1 faat3 siu1, ting1 jat6 heoi3 tai2 ji1 sang1.",
mandarin: "我有点发烧，明天去看医生。"
),
tip: "醫 ji1 陰平起音要高；燒 siu1 的 iu 係雙元音，別讀成單音素。"
),
CourseTheme(
id: "phone",
titleZh: "打電話",
titleEn: "Phone Calls",
words: [
CourseWord(cantonese: "電話", jyutping: "din6 waa2", hakka: "电话(thien fa)", mandarin: "电话"),
CourseWord(cantonese: "喂", jyutping: "wai2", hakka: "喂(we)", mandarin: "喂（接电话用语）"),
CourseWord(cantonese: "留言", jyutping: "lau4 jin4", hakka: "留言(liu ngien)", mandarin: "留言"),
CourseWord(cantonese: "覆電話", jyutping: "fuk1 din6 waa2", hakka: "覆电话(phuk thien fa)", mandarin: "回电话"),
CourseWord(cantonese: "訊息", jyutping: "seon3 sik1", hakka: "讯息(sin sit)", mandarin: "信息"),
CourseWord(cantonese: "接電話", jyutping: "zip3 din6 waa2", hakka: "接电话(chiap thien fa)", mandarin: "接电话"),
CourseWord(cantonese: "收線", jyutping: "sau1 sin3", hakka: "收线(shu sien)", mandarin: "挂电话"),
CourseWord(cantonese: "打錯", jyutping: "daa2 co3", hakka: "打错(ta chho)", mandarin: "打错（电话）"),
],
sentence: CourseSentence(
cantonese: "你聽日得唔得閒，我打畀你？",
jyutping: "nei5 ting1 jat6 dak1 m4 dak1 haan4, ngo5 daa2 bei2 nei5?",
mandarin: "你明天有空吗，我打给你？"
),
tip: "電 din6 陽去低降調，別讀成高音；畀 bei2 係「給」嘅意思，口語常用。"
),
CourseTheme(
id: "bank",
titleZh: "銀行",
titleEn: "Bank",
words: [
CourseWord(cantonese: "銀行", jyutping: "ngan4 hong4", hakka: "银行(ngiun hong)", mandarin: "银行"),
CourseWord(cantonese: "提款", jyutping: "tai4 fun2", hakka: "提款(thai khon)", mandarin: "取款"),
CourseWord(cantonese: "存款", jyutping: "cyun4 fun2", hakka: "存款(chhun khon)", mandarin: "存款"),
CourseWord(cantonese: "找換", jyutping: "zaau2 wun6", hakka: "找换(chau fon)", mandarin: "兑换"),
CourseWord(cantonese: "信用咭", jyutping: "seon3 jung6 kaat1", hakka: "信用咭(sin iung khat)", mandarin: "信用卡"),
CourseWord(cantonese: "戶口", jyutping: "wu6 hau2", hakka: "户口(fu heu)", mandarin: "账户"),
CourseWord(cantonese: "㩒錢", jyutping: "gam6 cin2", hakka: "㩒钱(khem chhien)", mandarin: "取钱（按钱）"),
CourseWord(cantonese: "櫃員機", jyutping: "gwai6 jyun4 gei1", hakka: "柜员机(khui ien ki)", mandarin: "ATM"),
],
sentence: CourseSentence(
cantonese: "附近有冇櫃員機，我想㩒錢。",
jyutping: "fu6 gan6 jau5 mou5 gwai6 jyun4 gei1, ngo5 soeng2 gam6 cin2.",
mandarin: "附近有ATM吗，我想取钱。"
),
tip: "銀 ngan4 嘅 ng 聲母係鼻音起頭，普通話冇呢個聲母，多練；㩒 gem6 係地道口語「按」嘅意思。"
),
CourseTheme(
id: "travel",
titleZh: "旅行",
titleEn: "Travel",
words: [
CourseWord(cantonese: "旅行", jyutping: "leoi5 hang4", hakka: "旅行(li hang)", mandarin: "旅行"),
CourseWord(cantonese: "酒店", jyutping: "zau2 dim3", hakka: "酒店(chiu tiam)", mandarin: "酒店"),
CourseWord(cantonese: "機票", jyutping: "gei1 piu3", hakka: "机票(ki phiau)", mandarin: "机票"),
CourseWord(cantonese: "景點", jyutping: "ging2 dim2", hakka: "景点(kin tiam)", mandarin: "景点"),
CourseWord(cantonese: "護照", jyutping: "wu6 ziu3", hakka: "护照(fu chau)", mandarin: "护照"),
CourseWord(cantonese: "行李", jyutping: "hang4 lei5", hakka: "行李(hang li)", mandarin: "行李"),
CourseWord(cantonese: "導遊", jyutping: "dou6 jau4", hakka: "导游(tho iu)", mandarin: "导游"),
CourseWord(cantonese: "出發", jyutping: "ceot1 faat3", hakka: "出发(chut fat)", mandarin: "出发"),
],
sentence: CourseSentence(
cantonese: "我哋下個月去旅行，你去唔去？",
jyutping: "ngo5 dei6 haa6 go3 jyut6 heoi3 leoi5 hang4, nei5 heoi3 m4 heoi3?",
mandarin: "我们下个月去旅行，你去不去？"
),
tip: "旅 leoi5 嘅 eo 係圓唇元音，先圓唇再展唇，陽上調上揚。"
),
CourseTheme(
id: "fun",
titleZh: "娛樂",
titleEn: "Entertainment",
words: [
CourseWord(cantonese: "睇戲", jyutping: "tai2 hei3", hakka: "睇戏(thai hi)", mandarin: "看电影"),
CourseWord(cantonese: "唱K", jyutping: "coeng3 kei1", hakka: "唱K(chhong K)", mandarin: "唱K"),
CourseWord(cantonese: "行街", jyutping: "haang4 gaai1", hakka: "行街(hang kai)", mandarin: "逛街"),
CourseWord(cantonese: "打機", jyutping: "daa2 gei1", hakka: "打机(ta ki)", mandarin: "打游戏"),
CourseWord(cantonese: "朋友", jyutping: "pang4 jau5", hakka: "朋友(phang iu)", mandarin: "朋友"),
CourseWord(cantonese: "食嘢", jyutping: "sik6 je5", hakka: "食嘢(sit ie)", mandarin: "吃东西"),
CourseWord(cantonese: "假期", jyutping: "gaa3 kei4", hakka: "假期(ka khi)", mandarin: "假期"),
],
sentence: CourseSentence(
cantonese: "週末一齊去睇戲，好唔好？",
jyutping: "zau1 mut6 jat1 cai4 heoi3 tai2 hei3, hou2 m4 hou2?",
mandarin: "周末一起去看电影，好不好？"
),
tip: "戲 hei3 嘅 ei 係雙元音，嘴型由半開到閉，陰去調下降。"
),
CourseTheme(
id: "work",
titleZh: "工作",
titleEn: "Work",
words: [
CourseWord(cantonese: "放工", jyutping: "fong3 gung1", hakka: "放工(piong kung)", mandarin: "下班"),
CourseWord(cantonese: "老闆", jyutping: "lou5 baan2", hakka: "老板(lo pan)", mandarin: "老板"),
CourseWord(cantonese: "同事", jyutping: "tung4 si6", hakka: "同事(thung si)", mandarin: "同事"),
CourseWord(cantonese: "開會", jyutping: "hoi1 wui2", hakka: "开会(khoi fi)", mandarin: "开会"),
CourseWord(cantonese: "加班", jyutping: "gaa1 baan1", hakka: "加班(ka pan)", mandarin: "加班"),
CourseWord(cantonese: "人工", jyutping: "jan4 gung1", hakka: "人工(ngin kung)", mandarin: "工资"),
CourseWord(cantonese: "請假", jyutping: "ceng2 gaa3", hakka: "请假(chhiang ka)", mandarin: "请假"),
],
sentence: CourseSentence(
cantonese: "我今日要加班，唔嚟食飯啦。",
jyutping: "ngo5 gam1 jat6 jiu3 gaa1 baan1, m4 lai4 sik6 faan6 laa1.",
mandarin: "我今天要加班，不来吃饭了。"
),
tip: "闆 baan2 嘅 aa 長元音拉長，陽上調上揚，別讀短。"
),
CourseTheme(
id: "hkculture",
titleZh: "港味文化",
titleEn: "HK Culture",
words: [
CourseWord(cantonese: "茶餐廳", jyutping: "caa4 caan1 teng1", hakka: "茶餐厅(chha chhan then)", mandarin: "茶餐厅"),
CourseWord(cantonese: "飲茶", jyutping: "jam2 caa4", hakka: "饮茶(im chha)", mandarin: "饮茶"),
CourseWord(cantonese: "叮叮", jyutping: "ding1 ding1", hakka: "叮叮(tin tin)", mandarin: "叮叮车（电车）"),
CourseWord(cantonese: "拜年", jyutping: "baai3 nin4", hakka: "拜年(pai ngien)", mandarin: "拜年"),
CourseWord(cantonese: "利是", jyutping: "lai6 si6", hakka: "利是(li shi)", mandarin: "利是（红包）"),
CourseWord(cantonese: "大排檔", jyutping: "daai6 paai4 dong3", hakka: "大排档(thai phai tong)", mandarin: "大排档"),
CourseWord(cantonese: "港式", jyutping: "gong2 sik1", hakka: "港式(kong shit)", mandarin: "港式"),
CourseWord(cantonese: "地道", jyutping: "dei6 dou6", hakka: "地道(thi tho)", mandarin: "地道"),
],
sentence: CourseSentence(
cantonese: "嚟香港一定要去茶餐廳飲茶！",
jyutping: "lai4 hoeng1 gong2 jat1 ding6 jiu3 heoi3 caa4 caan1 teng1 jam2 caa4!",
mandarin: "来香港一定要去茶餐厅饮茶！"
),
tip: "餐 caan1 嘅 aan 鼻韻尾，陰平高平調，一字一頓讀清楚。"
),
CourseTheme(
id: "plans",
titleZh: "約人",
titleEn: "Making Plans",
words: [
CourseWord(cantonese: "約", jyutping: "joek3", hakka: "约(iok)", mandarin: "约"),
CourseWord(cantonese: "聽日", jyutping: "ting1 jat6", hakka: "听日(thang ngit)", mandarin: "明天"),
CourseWord(cantonese: "晏晝", jyutping: "aan3 zau3", hakka: "晏昼(an chu)", mandarin: "下午"),
CourseWord(cantonese: "夜晚", jyutping: "je6 maan5", hakka: "夜晚(ia van)", mandarin: "晚上"),
CourseWord(cantonese: "得閒", jyutping: "dak1 haan4", hakka: "得闲(tet han)", mandarin: "有空"),
CourseWord(cantonese: "遲到", jyutping: "ci4 dou3", hakka: "迟到(chhi to)", mandarin: "迟到"),
CourseWord(cantonese: "等陣", jyutping: "dang2 zan6", hakka: "等阵(ten chhin)", mandarin: "等一下"),
CourseWord(cantonese: "見面", jyutping: "gin3 min6", hakka: "见面(kien mien)", mandarin: "见面"),
],
sentence: CourseSentence(
cantonese: "聽日晏晝三點見，得唔得？",
jyutping: "ting1 jat6 aan3 zau3 saam1 dim2 gin3, dak1 m4 dak1?",
mandarin: "明天下午三点见，行不行？"
),
tip: "約 joek3 入聲 -k 尾短促；晝 zau3 嘅 au 雙元音，陰去調下降。"
),
CourseTheme(
id: "feelings",
titleZh: "心情",
titleEn: "Feelings",
words: [
CourseWord(cantonese: "開心", jyutping: "hoi1 sam1", hakka: "开心(khoi sim)", mandarin: "开心"),
CourseWord(cantonese: "唔開心", jyutping: "m4 hoi1 sam1", hakka: "唔开心(m khoi sim)", mandarin: "不开心"),
CourseWord(cantonese: "攰", jyutping: "gui6", hakka: "攰(khui)", mandarin: "累"),
CourseWord(cantonese: "擔心", jyutping: "daam1 sam1", hakka: "担心(tam sim)", mandarin: "担心"),
CourseWord(cantonese: "嬲", jyutping: "nau1", hakka: "嬲(nau)", mandarin: "生气"),
CourseWord(cantonese: "驚", jyutping: "geng1", hakka: "惊(kiang)", mandarin: "害怕"),
CourseWord(cantonese: "冇嘢", jyutping: "mou5 je5", hakka: "冇嘢(mau ie)", mandarin: "没事"),
CourseWord(cantonese: "加油", jyutping: "gaa1 jau2", hakka: "加油(ka iu)", mandarin: "加油"),
],
sentence: CourseSentence(
cantonese: "唔使擔心，一切都會好返嘅。",
jyutping: "m4 sai2 daam1 sam1, jat1 cai3 dou1 wui5 hou2 faan1 ge3.",
mandarin: "不用担心，一切都会好起来的。"
),
tip: "嬲 nau1 陰平高平調，au 雙元音飽滿；驚 geng1 嘅 eng 鼻韻別讀成 en。"
),
]

// MARK: - 会话状态
/// 当前主题 id（用户最近一次进入的主题）
var currentThemeId: String?
/// 协议属性：供 UI 高亮当前话题
var currentTopicId: String? { currentThemeId }
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
/// 上一次测验是否从兴趣主题出题（"再考一个"沿用该范围）
var lastQuizFromInterests = false
/// 跟读连错几次后智能跳过
static let readAlongMaxFails = 3
/// 判定"用户在尝试跟读"的字符重合度阈值（0~1）
static let readAlongAttemptThreshold = 0.4

// MARK: - 主题查询
/// 按主题 id 取主题
func theme(id: String) -> CourseTheme? {
Self.curriculum.first { $0.id == id}
}

/// 下一个练习主题：兴趣优先——若用户在设置页勾了感兴趣的主题，
/// 按课程顺序跳到下一个感兴趣的（跳过当前主题、跳过已暂存的难句）；
/// 没选兴趣 / 感兴趣的都不可用时，回退到全量顺序轮换。
private func nextPracticeTheme(after id: String, interests: [String] = []) -> CourseTheme {
let n = Self.curriculum.count
guard let idx = Self.curriculum.firstIndex(where: { $0.id == id }) else { return Self.curriculum[0] }

if !interests.isEmpty {
var i = (idx + 1) % n
var guardCount = 0
while guardCount < n {
let theme = Self.curriculum[i]
if theme.id != id,
interests.contains(theme.titleZh),
!deferredThemes.contains(theme.id) {
return theme
}
i = (i + 1) % n
guardCount += 1
}
}

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
("weather", ["天气", "天氣", "下雨", "落雨", "打风", "打風", "weather", "rain"]),
("doctor", ["医生", "醫生", "看病", "睇医生", "睇醫生", "发烧", "發燒", "医院", "醫院", "doctor", "hospital"]),
("phone", ["电话", "電話", "打电话", "打電話", "手机", "手機", "phone", "call"]),
("bank", ["银行", "銀行", "取钱", "㩒錢", "柜员机", "櫃員機", "bank", "atm"]),
("travel", ["旅行", "旅游", "旅遊", "机场", "機場", "护照", "護照", "travel", "trip"]),
("fun", ["娱乐", "娛樂", "好玩", "电影", "電影", "睇戏", "睇戲", "唱K", "fun", "movie"]),
("work", ["工作", "上班", "返工", "老板", "老細", "加班", "work", "job"]),
("hkculture", ["香港", "文化", "茶餐厅", "茶餐廳", "饮茶", "飲茶", "hongkong", "culture"]),
("plans", ["约人", "約人", "约会", "約會", "见面", "見面", "安排", "plan"]),
("feelings", ["心情", "开心", "開心", "难过", "難過", "加油", "feeling", "mood"]),
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

// 1. 开场：输入为空，问好 + 自我介绍 + 列出全部主题
if text.isEmpty {
return greetingLesson()
}

// 2. 跟读正确：输入与场景句去标点/空白后一致即算跟读（用户常省略标点），
//    先于主题关键词匹配，保证快捷按钮和手动输入都能进跟读。
//    每句读对 readAlongPassCount 遍即过关，自动进入下一主题的场景句，避免无限重复。
let plainInput = Self.plainText(text)
if let theme = Self.curriculum.first(where: { Self.plainText($0.sentence.cantonese) == plainInput }) {
currentThemeId = theme.id
pendingQuiz = nil
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

// 2b. 换个主题：兴趣优先（设置页勾选的主题先轮），否则按课程顺序切到下一个（跳过已暂存的难句）
if text.contains("换个主题") || text.contains("換個主題") {
let next: CourseTheme
if let cur = currentThemeId {
next = nextPracticeTheme(after: cur, interests: profile.interests)
} else {
next = Self.curriculum[0]
}
currentThemeId = next.id
pendingQuiz = nil
pendingReadAlong = next.id
return themeLesson(next, switched: true)
}

// 3. 测验请求：出题（先不给答案）
// 3a. 主题对话卡片里的"考考我（当前主题）"：只从当前主题出题
if text.contains("考考我（当前主题）") || text.contains("考考我(当前主题)") {
pendingReadAlong = nil
lastQuizFromInterests = false
return quizLesson()
}
// 3b. "再考一个"：沿用上一次测验的出题范围（兴趣 / 当前主题）
if text.contains("再考一个") || text.contains("再考一個") {
pendingReadAlong = nil
return quizLesson(interests: lastQuizFromInterests ? profile.interests : [])
}
// 3c. 其他测验请求（头部"考考我" chip、手动输入）：从兴趣主题出题
if isQuizRequest(text) {
pendingReadAlong = nil
lastQuizFromInterests = !profile.interests.isEmpty
return quizLesson(interests: profile.interests)
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
pendingQuiz = nil
pendingReadAlong = theme.id
return themeLesson(theme)
}

// 7. 兜底：温和回复 + 列出全部主题引导
return fallbackLesson()
}

// MARK: - 各分支 Lesson 构造

/// 开场 Lesson：问好 + 介绍自己是本地粤语陪练 + 列出全部主题
private func greetingLesson() -> Lesson {
let themes = Self.curriculum.map(\.titleZh).joined(separator: "、")
return Lesson(
replyCantonese: "你好！我系你嘅离线粤语陪练。我哋可以由下面 \(Self.curriculum.count) 个主题开始学：\(themes)。你想先学边个？",
replyJyutping: "nei5 hou2! ngo5 hai6 nei5 ge3 loi4 sin3 jyut6 jyu5 pui4 lin6.",
replyEnglish: "你好！我是你的离线粤语陪练。我们可以从下面 \(Self.curriculum.count) 个主题开始：\(themes)。你想先学哪个？",
breakdown: introWords(),
tip: nil,
suggestedReplies: themeSuggestions(),
difficulty: "beginner"
)
}

/// "换个主题"快捷回复：按钮上标注当前主题，如"换个主题（当前：问候与礼貌）"。
/// 点按后发出的文本仍含"换个主题"，service 用子串匹配照常切主题。
private func switchThemeReply(current theme: CourseTheme?) -> SuggestedReply {
    let label = theme.map { "换个主题（当前：\($0.titleZh)）" } ?? "换个主题"
    return SuggestedReply(
        cantonese: label,
        jyutping: "wun6 go3 zyu2 tai4",
        english: "看看其他主题"
    )
}

/// 主题 Lesson：主题导语 + 场景句，breakdown 放 5 个词，tip 放主题 tip
private func themeLesson(_ theme: CourseTheme, switched: Bool = false) -> Lesson {
let lead = switched
? "好，换到「\(theme.titleZh)」主题！"
: "好，我哋嚟学「\(theme.titleZh)」！"
return Lesson(
replyCantonese: "\(lead)先嚟一句最实用嘅场景句：「\(theme.sentence.cantonese)」",
replyJyutping: theme.sentence.jyutping,
replyEnglish: "今天我们学「\(theme.titleZh)」。先来一句最实用的场景句：「\(theme.sentence.mandarin)」",
breakdown: theme.words.map { BreakdownItem(cantonese: $0.cantonese, jyutping: $0.jyutping, english: $0.mandarin)},
tip: theme.tip,
suggestedReplies: [
SuggestedReply(cantonese: "考考我（当前主题）", jyutping: "haau2 haau2 ngo5 (dong1 cin4 zyu2 tai4)", english: "只考当前主题"),
SuggestedReply(cantonese: theme.sentence.cantonese, jyutping: theme.sentence.jyutping, english: theme.sentence.mandarin),
switchThemeReply(current: theme),
],
difficulty: "beginner"
)
}

/// 测验出题：兴趣优先——勾了兴趣主题就从中随机抽一个主题出题；
/// 没勾则沿用老逻辑（当前主题，无则随机）。先不给答案，记到 pendingQuiz
private func quizLesson(interests: [String] = []) -> Lesson {
let interested = Self.curriculum.filter { interests.contains($0.titleZh) }
let theme: CourseTheme
if let pick = interested.randomElement() {
theme = pick
} else {
theme = currentThemeId.flatMap { self.theme(id: $0)}
?? Self.curriculum.randomElement()
?? Self.curriculum[0]
}
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
switch Self.judgeQuiz(userText: userText, word: word) {
case .exactChar:
correction = "写对了，「\(word.cantonese)」就系咁写！读嘅时候注意\(hint)，多读两遍就顺口啦。"
case .homophone:
let said = userText.trimmingCharacters(in: .whitespacesAndNewlines)
correction = "读音啱啦！你讲嘅「\(said)」同「\(word.cantonese)」同音（\(word.jyutping)），算你对！写就系咁写：「\(word.cantonese)」。读嘅时候注意\(hint)。"
case .jyutping:
correction = "粤拼打啱啦，「\(word.cantonese)」就系读「\(word.jyutping)」！注意\(hint)，跟住读多一次啦。"
case .wrong:
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
switchThemeReply(current: quizTheme),
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
SuggestedReply(cantonese: "考考我（当前主题）", jyutping: "haau2 haau2 ngo5 (dong1 cin4 zyu2 tai4)", english: "只考当前主题"),
switchThemeReply(current: theme),
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
switchThemeReply(current: theme),
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
SuggestedReply(cantonese: "考考我（当前主题）", jyutping: "haau2 haau2 ngo5 (dong1 cin4 zyu2 tai4)", english: "只考当前主题"),
switchThemeReply(current: next),
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
SuggestedReply(cantonese: "考考我（当前主题）", jyutping: "haau2 haau2 ngo5 (dong1 cin4 zyu2 tai4)", english: "只考当前主题"),
switchThemeReply(current: next),
],
difficulty: "beginner"
)
}

/// 兜底 Lesson：温和中文回复 + 列出全部主题名引导
private func fallbackLesson() -> Lesson {
let themes = Self.curriculum.map(\.titleZh).joined(separator: "、")
return Lesson(
replyCantonese: "唔好意思，我暂时听唔明呀。我系离线版粤语陪练，你可以拣下面其中一个主题开始学：\(themes)。",
replyJyutping: "",
replyEnglish: "没听懂你的意思。我是离线版粤语陪练，试试从下面 \(Self.curriculum.count) 个主题里选一个开始：\(themes)。",
breakdown: introWords(),
tip: nil,
suggestedReplies: themeSuggestions(),
difficulty: "beginner"
)
}

// MARK: - 小工具

/// 测验同音字归一：单字测验用语音作答时，识别常输出同音异字
///（如把 jau6 识别成"又"而非"右"）。测验考的是读音，同音即算对。
/// key: 识别可能输出的同音字 → value: 课程目标字
private static let homophoneCanonical: [Character: Character] = [
    "前": "錢",
    "蝕": "食",
    "犯": "飯", "范": "飯",
    "恒": "行", "衡": "行",
    "答": "搭",
    "咗": "左", "佐": "左",
    "又": "右", "佑": "右", "祐": "右",
    "評": "平", "瓶": "平",
    "桂": "貴",
    "底": "抵",
    "番": "返",
    "公": "工",
]

/// 测验答案归一化：plainText（繁简/语气词）+ 同音字→目标字
private static func quizNormalized(_ s: String) -> String {
    String(plainText(s).map { homophoneCanonical[$0] ?? $0 })
}

/// 测验判分结果
private enum QuizVerdict {
    case exactChar        // 字写对了（含繁简归一）
    case homophone       // 同音异字，读音对了
    case jyutping        // 粤拼打对了
    case wrong
}

/// 测验判分：字（含繁简/同音归一）或粤拼对任一即算对
private static func judgeQuiz(userText: String, word: CourseWord) -> QuizVerdict {
    let normInput = plainText(userText)
    let normTarget = plainText(word.cantonese)
    // 1. 字对
    if normInput.contains(normTarget) { return .exactChar }
    // 2. 同音字对（如语音"又" vs 目标"右"）
    if quizNormalized(userText).contains(quizNormalized(word.cantonese)) { return .homophone }
    // 3. 粤拼对（去空格/横杠、小写，如 "m4 goi1" / "m4goi1"）
    let normJyutping = word.jyutping.lowercased().replacingOccurrences(of: " ", with: "")
    let inputJyutping = userText.lowercased()
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: "-", with: "")
    if !inputJyutping.isEmpty, inputJyutping == normJyutping { return .jyutping }
    return .wrong
}

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

/// 全部主题名快捷回复
private func themeSuggestions() -> [SuggestedReply] {
Self.curriculum.map { SuggestedReply(cantonese: $0.titleZh, jyutping: "", english: $0.titleEn)}
}

/// 是否为测验请求：含"考考我/考我/测验"或 quiz 单词
private func isQuizRequest(_ text: String) -> Bool {
if text.contains("考考我") || text.contains("考我") || text.contains("再考一个") || text.contains("再考一個") || text.contains("测验") || text.contains("測驗") {
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
