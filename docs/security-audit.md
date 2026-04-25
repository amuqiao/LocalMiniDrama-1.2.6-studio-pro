# 安全审计报告

> **文档职责**：记录 LocalMiniDrama v1.2.6 针对 API 密钥外泄风险的代码审计结论
> **适用场景**：评估本项目是否安全存储和使用 AI API 密钥时参阅
> **目标读者**：关心数据安全的用户、二次开发者、安全评审人员
> **维护规范**：每次引入新的对外 HTTP 请求或依赖包时，需同步更新"外部域名汇总"和"依赖包检查"节

---

## 审计结论

**未发现恶意的 API 密钥窃取或上传行为。**

代码中不存在将用户 API Key 偷发至第三方服务器的逻辑。所有密钥仅在以下范围内流动：

1. 用户通过 UI 输入 → 后端数据库（SQLite，本地存储）
2. 后端读取密钥 → 发往**用户自己配置的** `base_url`（即 AI 服务商 API 地址）

---

## 审计范围

| 审计对象 | 路径 |
|----------|------|
| 前端网络请求 | `frontweb/src/` |
| 后端对外 HTTP 请求 | `backend-node/src/services/` |
| AI 配置存取逻辑 | `aiConfigService.js`、`aiConfig.js` |
| 外部硬编码域名 | 全项目 grep |
| 第三方依赖包 | `package.json`（前端 + 后端） |

---

## 逐项检查结果

### 前端

| 检查项 | 结论 |
|--------|------|
| Axios baseURL | ✅ 仅指向 `/api/v1`（本机代理） |
| 是否直接调 AI API | ✅ 否，所有 AI 请求经后端中转 |
| localStorage 存储密钥 | ✅ 否 |
| 埋点 / 统计 / 遥测代码 | ✅ 未发现（无 Sentry、Mixpanel、GA 等） |
| Vite 代理是否有异常转发 | ✅ 仅代理到 `localhost:5679` |

### 后端

| 检查项 | 结论 |
|--------|------|
| API Key 发往地址 | ✅ 仅发往 `config.base_url`（用户配置） |
| 是否有固定外发地址接收密钥 | ✅ 否 |
| 统计 / 上报 / 遥测代码 | ✅ 未发现 |

### 依赖包

后端和前端的所有依赖均为业界常见开源包（express、better-sqlite3、vue、axios、element-plus 等），未发现含有数据收集功能的可疑包。

---

## 外部域名汇总

以下为项目中全部硬编码的外部域名及其安全状态：

| 域名 | 用途 | 含 API Key | 状态 |
|------|------|:----------:|------|
| `api.klingai.com` | 可灵官方 API | 是（正常鉴权） | ✅ 安全 |
| `api-beijing.klingai.com` | 可灵官方 API（北京节点） | 是（正常鉴权） | ✅ 安全 |
| `ffir.cn` | 可灵视频中转站 | **是** | ⚠️ 见下文说明 |
| `imageproxy.zhongzhuan.chat` | 图片代理上传 | **否** | ✅ 安全 |
| `dashscope.aliyuncs.com` | 阿里云通义 API | 是（正常鉴权） | ✅ 安全 |
| `ark.cn-beijing.volces.com` | 火山引擎 API | 是（正常鉴权） | ✅ 安全 |
| `generativelanguage.googleapis.com` | Google Gemini API | 是（正常鉴权） | ✅ 安全 |
| `api.vidu.cn` | Vidu 视频 API | 是（正常鉴权） | ✅ 安全 |

### `ffir.cn` 中转站说明

**触发条件**：仅当用户在 AI 配置中选择使用可灵（Kling）视频服务，且**未填写官方 AccessKey + SecretKey** 时，系统默认回退到 `ffir.cn` 作为中转站，用户的 Bearer Token 会随请求发往该站点。

**这不是恶意行为**：这是项目为没有官方账号的用户提供的备用通道，行为在代码中公开可见（`videoClient.js` → `resolveKlingOmniBaseUrl`）。

**消除此风险的方法**：在 AI 配置中填写可灵官方开放平台申请的 `AccessKey` 和 `SecretKey`，系统将使用官方接口，不经过任何中转站。

### `imageproxy.zhongzhuan.chat` 图片代理说明

用于将 AI 生成的图片 URL（部分为临时链接）转存为稳定可访问的图床链接。上传内容**仅为图片二进制数据**，请求头中不包含任何 API Key 或用户身份信息（`uploadService.js` 第 147–185 行可验证）。

---

## API Key 在系统内的完整流向

```
用户在 UI 输入 API Key
        │
        ▼
POST /api/v1/aiConfig  （HTTPS，仅本机可达）
        │
        ▼
SQLite 数据库（本地文件，非云端）
        │
        ▼  发起 AI 请求时
后端读取 api_key
        │
        ▼
Authorization: Bearer <api_key>
        │
        ▼
用户配置的 base_url（AI 服务商 API）
```

密钥全程不离开本机，除非用户主动配置了第三方中转站地址作为 `base_url`。

---

## 一个代码层面的注意点

`aiConfigService.js` 的 `rowToConfig` 函数（第 198 行）在 GET 接口响应中返回**完整明文** `api_key`，不做掩码处理。这意味着：

- 打开浏览器 DevTools → Network，可看到密钥明文
- 若其他人能访问你的浏览器或后端端口，可读取密钥

**已采取的缓解措施**：`backend-node/configs/config.yaml` 中 `host` 已修改为 `127.0.0.1`，后端仅接受本机请求，局域网设备无法访问 API。

---

## 总结

| 风险类型 | 等级 | 说明 |
|----------|------|------|
| 恶意密钥上传 | ✅ 无 | 代码中不存在 |
| 遥测/统计数据收集 | ✅ 无 | 代码中不存在 |
| 可灵中转站密钥共享 | ⚠️ 低 | 用户主动选择时发生，可配置官方密钥规避 |
| 局域网 API 端口暴露 | ✅ 已修复 | host 已改为 127.0.0.1 |
