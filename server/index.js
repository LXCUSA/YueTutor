// yuetutor-proxy —— 「粤语陪练」App 的 Node 代理后端（可选）。
// v1 App 是纯离线版，不用这个后端；它以后启用 AI 陪练时才会派上用场。
// 本服务只做两件事：用 APP_SECRET 鉴权 + 把各家 LLM 的 API key 藏在服务端，
// 避免 key 直接出现在 App 客户端里。
//
// 多模型提供商可插拔：LLM_PROVIDER=anthropic|xai|gemini（默认 anthropic）。
// 三家共用同一份中文讲解版家教 system prompt。
//
// 环境变量：
// LLM_PROVIDER —— anthropic | xai | gemini（默认 anthropic）
// LLM_MODEL —— 覆盖默认模型（兼容旧名 TUTOR_MODEL）
// 各家默认：anthropic→claude-sonnet-4-6 / xai→grok-4 / gemini→gemini-2.5-flash
// ANTHROPIC_API_KEY / XAI_API_KEY / GEMINI_API_KEY —— 按所选 provider 填一个
// APP_SECRET —— App 端 header x-app-secret 对应的密钥（必填，未配置则鉴权直接 401）
// PORT —— 监听端口，默认 3000

const express = require("express");

const APP_SECRET = process.env.APP_SECRET || "";
const PORT = Number(process.env.PORT) || 3000;
const LLM_PROVIDER = (process.env.LLM_PROVIDER || "anthropic").toLowerCase();

const PROVIDER_DEFAULTS = {
anthropic: { model: "claude-sonnet-4-6", envKey: "ANTHROPIC_API_KEY"},
xai: { model: "grok-4", envKey: "XAI_API_KEY"},
gemini: { model: "gemini-2.5-flash", envKey: "GEMINI_API_KEY"},
};

const LLM_MODEL =
process.env.LLM_MODEL ||
process.env.TUTOR_MODEL || // 兼容旧环境变量名
(PROVIDER_DEFAULTS[LLM_PROVIDER] || {}).model;

const app = express();
app.use(express.json({ limit: "1mb"}));

// —— 鉴权：x-app-secret 对 APP_SECRET。APP_SECRET 未配置时直接 401。
function auth(req, res, next) {
const secret = req.header("x-app-secret");
if (!APP_SECRET || secret!== APP_SECRET) {
return res.status(401).json({ ok: false, error: "unauthorized"});
}
next();
}

class UpstreamError extends Error {
constructor(status, payload) {
super("upstream error");
this.status = status;
this.payload = payload;
}
}

// —— 从模型返回里提取 JSON 对象：取首个 { 到最后的}。
function extractJsonObject(raw) {
const start = raw.indexOf("{");
const end = raw.lastIndexOf("}");
if (start === -1 || end === -1 || end <= start) return null;
try {
return JSON.parse(raw.slice(start, end + 1));
} catch {
return null;
}
}

// —— 解析失败的兜底 lesson：把原文当成粤语回复展示。
function fallbackLesson(raw, profile) {
const level = (profile && profile.level) || "beginner";
return {
reply_cantonese: String(raw).slice(0, 2000),
reply_jyutping: "",
reply_english: "（模型返回格式异常，以下为原文）",
breakdown: [],
correction: null,
tip: null,
suggested_replies: [],
difficulty: ["beginner", "intermediate", "advanced"].includes(level)? level: "beginner",
};
}

// —— 家教 system prompt（简体中文重写版，三家 provider 共用）。
// 讲解、翻译、纠正全部用简体中文；粤语用香港口语繁体字 + 数字调粤拼。
function buildSystemPrompt(profile) {
const p = profile || {};
const name = p.name || "同学";
const level = p.level || "beginner";
const interests = Array.isArray(p.interests)? p.interests.join("、"): p.interests || "日常话题";
const tutorName = p.tutorName || "粤语家教";
const focus = p.focus || "开口说粤语";

return `你是${tutorName}，一位温暖耐心的香港粤语家教，和学生 ${name} 一对一聊天式教学。
学生是内地人、母语客家话、零基础学粤语。学习目标：${focus}。当前水平：${level}。


1. 讲解、翻译、纠正、学习建议，全部用简体中文写。
2. 粤语必须用香港口语（用係、喺、嘅、咗、啲、嘢、唔、睇、點解、而家），繁体字书写。
3. 所有出现的粤语句子，都必须配数字调的粤拼（如：nei5 hou2）。粤拼不许缺调号、不许用字母调。


学生粤语说错了要温和纠正：先肯定他对的地方，再只给一个最关键的调整点，不要一次性堆很多纠正。
没问题就直接夸，顺着话题聊下去。


在 tip 里自然带出，点到为止、一次只讲一个，例如：粤语 aa 是长元音别读短了；
粤语 2 声是高升调（35 调），别读成客家话的低调；yu 是撮口元音，嘴要撮圆；
gw、kw 是圆唇音，唇形要圆。只有跟本轮内容相关的才说，不相关的不要硬塞。


多用问句推进对话，每次回复 1–4 句粤语（简短、有信息量）。
话题尽量贴学生的兴趣：${interests}。不要讲课式长篇大论，要像真人聊天一样带学生开口。


只输出一个 JSON 对象，不要 markdown、不要代码块围栏、不要多余文字。
键名固定如下（snake_case）：
- reply_cantonese：粤语回复，繁体口语，1–4 句
- reply_jyutping：对应粤拼，数字调
- reply_english：对应简体中文翻译（注意：这是中文翻译，不是英文）
- breakdown：0–6 个生词/短语数组，每项 {cantonese, jyutping, english}，english 为中文意思
- correction：简体中文纠正，先肯定再给一个调整点；没问题则为 null
- tip：简体中文学习小贴士，一次一个点；可为 null
- suggested_replies：2–3 个学生可接的回复，每项 {cantonese, jyutping, english}，english 为中文意思
- difficulty：beginner / intermediate / advanced（对照学生水平：${level}）`;
}

// —— Provider 接口：async ({ system, messages, useWebSearch, profile }) -> lesson 对象
// messages 为 [{ role: "user"|"assistant", content}]。模型返回解析失败时用 fallbackLesson 兜底。

// Anthropic：v1/messages + system 里要求纯 JSON + prompt caching + extractJsonObject 兜底。
async function anthropicComplete({ system, messages, useWebSearch, profile }) {
const body = {
model: LLM_MODEL,
max_tokens: 2048,
system: [{ type: "text", text: system, cache_control: { type: "ephemeral"}}],
messages,
};
if (useWebSearch) {
body.tools = [{ type: "web_search_20260219", name: "web_search", max_uses: 3}];
}
let res;
try {
res = await fetch("https://api.anthropic.com/v1/messages", {
method: "POST",
headers: {
"content-type": "application/json",
"x-api-key": process.env.ANTHROPIC_API_KEY,
"anthropic-version": "2023-06-01",
},
body: JSON.stringify(body),
});
} catch (e) {
throw new UpstreamError(502, { message: String((e && e.message) || e)});
}
const data = await res.json().catch(() => null);
if (!res.ok) {
throw new UpstreamError(res.status, data && data.error? data.error: data);
}
const raw = (data.content || [])
.filter((b) => b.type === "text")
.map((b) => b.text)
.join("\n");
return extractJsonObject(raw) || fallbackLesson(raw, profile);
}

// OpenAI 兼容路径（xAI Grok 与 Gemini 共用，用 baseURL 区分）：
// response_format json_object 拿干净 JSON；system prompt 放 messages[0] 的 system role。
async function openaiCompatibleComplete(baseURL, apiKey, { system, messages, useWebSearch, profile }) {
let sys = system;
if (useWebSearch) {
// 该路径暂不支持联网搜索：在 prompt 里提醒模型说明知识截止，不报错。
sys += "\n\n如需引用最新信息，请在 tip 或回复中说明你的知识截止情况，不要编造实时资讯。";
}
const body = {
model: LLM_MODEL,
response_format: { type: "json_object"},
messages: [{ role: "system", content: sys},...messages],
};
let res;
try {
res = await fetch(`${baseURL}/chat/completions`, {
method: "POST",
headers: {
"content-type": "application/json",
authorization: `Bearer ${apiKey}`,
},
body: JSON.stringify(body),
});
} catch (e) {
throw new UpstreamError(502, { message: String((e && e.message) || e)});
}
const data = await res.json().catch(() => null);
if (!res.ok) {
throw new UpstreamError(res.status, data && data.error? data.error: data);
}
const raw = data && data.choices && data.choices[0] && data.choices[0].message
? String(data.choices[0].message.content || "")
: "";
return extractJsonObject(raw);
}

const PROVIDERS = {
anthropic: (args) => anthropicComplete(args),
xai: (args) =>
openaiCompatibleComplete("https://api.x.ai/v1", process.env.XAI_API_KEY, args),
gemini: (args) =>
openaiCompatibleComplete(
"https://generativelanguage.googleapis.com/v1beta/openai",
process.env.GEMINI_API_KEY,
args
),
};

// —— 把 history 转成各家通用的 messages 数组。
function buildMessages(history, userText) {
const messages = [];
for (const item of history || []) {
if (!item || typeof item.text!== "string") continue;
messages.push({
role: (item.role === "assistant" || item.role === "tutor") ? "assistant" : "user",
content: item.text,
});
}
messages.push({ role: "user", content: userText});
return messages;
}

app.get("/health", (req, res) => {
res.json({ ok: true});
});

app.post("/cantonese/chat", auth, async (req, res) => {
const { profile, history, userText, useWebSearch} = req.body || {};

if (!userText || typeof userText!== "string") {
return res.status(400).json({ ok: false, error: "userText is required"});
}

const complete = PROVIDERS[LLM_PROVIDER];
if (!complete) {
return res.status(400).json({
ok: false,
error: `不支持的 LLM_PROVIDER：${LLM_PROVIDER}，请设为 anthropic、xai 或 gemini`,
});
}

const { envKey} = PROVIDER_DEFAULTS[LLM_PROVIDER];
if (!process.env[envKey]) {
return res.status(500).json({
ok: false,
error: `未配置 ${envKey}：当前 LLM_PROVIDER=${LLM_PROVIDER}，请设置该环境变量后再试`,
});
}

try {
const system = buildSystemPrompt(profile);
const messages = buildMessages(history, userText);
const lesson =
await complete({ system, messages, useWebSearch:!!useWebSearch, profile});
res.json({ ok: true, lesson});
} catch (e) {
if (e instanceof UpstreamError) {
return res.status(e.status).json({ ok: false, error: "upstream error", detail: e.payload});
}
return res.status(500).json({ ok: false, error: "internal error", detail: String((e && e.message) || e)});
}
});

app.listen(PORT, () => {
console.log(`yuetutor-proxy listening on:${PORT} (provider=${LLM_PROVIDER}, model=${LLM_MODEL})`);
});
