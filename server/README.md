# yuetutor-proxy（可选后端）

「粤语陪练」App 的 Node 代理后端，**v1 不用**。v1 是纯离线版，用户暂时没有
LLM API key；这份代码是"以后启用 AI 陪练"时才派上用场的基础。

为什么要有代理：LLM 的 API key 存在服务端、App 只带 `APP_SECRET` 来调用，
key 不会出现在客户端。

支持三家模型提供商（`LLM_PROVIDER` 切换），**三家共用同一份中文讲解版家教
system prompt**（粤语香港口语繁体 + 数字调粤拼，讲解/纠正全用简体中文）。

## 三家提供商

| `LLM_PROVIDER` | 服务 | 默认模型（`LLM_MODEL` 可覆盖） | 联网搜索 |
|---|---|---|---|
| `anthropic`（默认） | Anthropic Claude | `claude-sonnet-4-6` | ✅ 原生 web_search tool |
| `xai` | xAI Grok（OpenAI 兼容接口） | `grok-4` | ⚠️ 暂不支持，prompt 里提醒说明知识截止 |
| `gemini` | Google Gemini（OpenAI 兼容接口） | `gemini-2.5-flash` | ⚠️ 暂不支持，prompt 里提醒说明知识截止 |

实现：`anthropic` 走 `api.anthropic.com/v1/messages`
（prompt caching + system 要求纯 JSON + `extractJsonObject` 兜底提取）；
`xai` / `gemini` 共用一个 OpenAI-compatible 实现
（`response_format: {"type": "json_object"}`，system prompt 放 messages[0] 的 system role），
仅 baseURL 与 key 不同。

## Key 申请（各去哪申请）

1. **Anthropic**：[console.anthropic.com](https://console.anthropic.com/) 注册 →
   左侧 "API keys" → Create key。注意 Claude API 是按量付费，需绑定支付方式。
2. **xAI**：[console.x.ai](https://console.x.ai/) 注册 → "API Keys" 页面创建。
   默认模型为 `grok-4`，若返回模型不存在错误，请以
   [xAI 文档](https://docs.x.ai/docs/models) 为准改用 `grok-3`（设 `LLM_MODEL=grok-3`）。
3. **Gemini**：[Google AI Studio](https://aistudio.google.com/)（用 Google 账号登录）→
   "Get API key" 创建。本代理走 Gemini 的 OpenAI 兼容端点
   `generativelanguage.googleapis.com/v1beta/openai/chat/completions`，
   用同一把 API key 以 Bearer 方式鉴权即可。

## 环境变量

| 变量 | 说明 |
|---|---|
| `LLM_PROVIDER` | `anthropic` / `xai` / `gemini`，默认 `anthropic` |
| `LLM_MODEL` | 覆盖默认模型（也兼容旧名 `TUTOR_MODEL`） |
| `ANTHROPIC_API_KEY` | LLM_PROVIDER=anthropic 时必填 |
| `XAI_API_KEY` | LLM_PROVIDER=xai 时必填 |
| `GEMINI_API_KEY` | LLM_PROVIDER=gemini 时必填 |
| `APP_SECRET` | App 端鉴权密钥（必填，未配置鉴权直接 401） |
| `PORT` | 监听端口，默认 `3000` |

所选 provider 对应的 key 未配置时，`/cantonese/chat` 返回 500 并明确提示缺哪个变量。

## 接口

- `GET /health` → `{ok: true}`
- `POST /cantonese/chat`
  - 鉴权：请求头 `x-app-secret` 必须等于服务端环境变量 `APP_SECRET`
    （`APP_SECRET` 未配置时直接返回 401）
  - 请求体：`{profile: {name, level, interests, tutorName, focus}, history: [{role, text}], userText, useWebSearch}`
  - 返回：`{ok: true, lesson}`，lesson 为 snake_case JSON
    （`reply_cantonese` / `reply_jyutping` / `reply_english`(中文翻译) /
    `breakdown` / `correction` / `tip` / `suggested_replies` / `difficulty`）
  - 上游报错时透传状态码与错误信息

## 本地运行

```bash
cd server
npm install
# 三选一：
export LLM_PROVIDER=anthropic ANTHROPIC_API_KEY=sk-ant-... APP_SECRET=随便设一个长随机串
# export LLM_PROVIDER=xai XAI_API_KEY=xai-... APP_SECRET=...
# export LLM_PROVIDER=gemini GEMINI_API_KEY=AIza... APP_SECRET=...
npm start
```

## 部署建议

Railway / Render / Fly.io 均可。把 `APP_SECRET`、所选 provider 的 key、
`LLM_PROVIDER`（非 anthropic 时）设为平台的环境变量，然后用 `npm start` 启动。
公网部署请只走 HTTPS。

## App 端启用（v1 暂置灰）

将来在 App「设置」里填：代理 URL（如 `https://xxx.railway.app`）+
`APP_SECRET` 密钥，即可切到 AI 陪练模式。App 端不需要为三家 provider 各做 UI，
v1 设置页里这个入口是置灰不可用的。
