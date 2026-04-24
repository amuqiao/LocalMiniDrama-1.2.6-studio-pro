# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **文档职责**：覆盖 LocalMiniDrama 的开发命令、架构概览和关键约定，供 Claude Code 快速上手
> **适用场景**：进入此仓库开始任何开发或调试任务前
> **目标读者**：Claude Code 实例，具备 Node.js/Vue 3/Electron 基础知识
> **维护规范**：新增路由或服务时同步更新架构节；修改端口、命令或配置路径时同步更新命令节

## 项目简介

AI 驱动的短剧生成桌面应用。完整工作流：故事大纲 → AI 生成多集剧本 → 角色/场景/道具提取与出图 → 分镜生成 → 逐帧视频生成 → 合并成片。全程数据本地存储，不上传云端。

## 目录结构

```
backend-node/   Express + SQLite 后端（核心业务逻辑）
frontweb/       Vue 3 + Vite 前端
desktop/        Electron 桌面壳（内嵌后端和前端 dist）
```

## 服务管理（推荐）

项目根目录提供统一脚本，详见 `docs/ops-manual.md`：

```bash
./service.sh start    # 启动后端（:5679）+ 前端（:3013）
./service.sh stop     # 停止所有服务
./service.sh restart  # 重启所有服务
./service.sh status   # 查看运行状态
```

日志位于 `scripts/logs/{backend,frontend}.log`。

## 开发命令

### 后端

```bash
cd backend-node
npm install
cp configs/config.example.yaml configs/config.yaml   # 首次配置
npm run migrate   # 首次初始化数据库 schema
npm run dev       # 开发模式（--watch 自动重载，端口 5679）
npm start         # 生产模式
```

### 前端

```bash
cd frontweb
npm install
npm run dev       # 开发服务器（端口 3013，自动代理到 :5679）
npm run build     # 构建到 frontweb/dist
```

### 桌面（Electron）

```bash
cd desktop
npm install
npm run rebuild:backend-native   # 首次：为 Electron ABI 重编译 better-sqlite3
npm start                        # 开发模式（需先构建前端）
npm run dist                     # 打包 Windows exe
npm run dist:cn                  # 同上，使用国内镜像
npm run dist:mac                 # macOS 打包
```

### 一键启动（Windows）

```bash
run_dev.bat   # 自动关闭 5679 端口并在独立终端启动后端 + 前端
```

## 高层架构

### 请求链路

```
Browser / Electron BrowserWindow
  └─ Axios HTTP → /api/v1/*
       └─ Express Routes（backend-node/src/routes/）
            └─ Services（backend-node/src/services/）
                 ├─ better-sqlite3（同步查询，无 Promise）
                 └─ 外部 AI API（DashScope / Volcengine / Kling / Gemini / Vidu 等）
```

### 关键分层约定

- **Routes → Services → DB**：路由层不直接操作数据库，所有写操作经 Service 层中转。
- **同步 DB**：`better-sqlite3` 全部使用同步 API，服务层无需 async/await 处理数据库调用。
- **异步 AI 任务**：图像/视频生成为长耗时任务，后端写入 `async_tasks` 表，前端轮询 `/api/v1/tasks/:id` 获取状态。
- **本地文件存储**：生成产物存于 `backend-node/data/storage/{images,characters,scenes,videos,merged}/`，DB 记录相对路径，通过 `/static/*` 回传前端。

### AI 客户端分工

| 文件 | 职责 |
|------|------|
| `aiClient.js` | 通用文本生成，支持多厂商 |
| `imageClient.js` | 图像生成 + 轮询完成状态 |
| `videoClient.js` | 视频生成 + 轮询完成状态 |
| `videoMergeService.js` | 调用本地 FFmpeg 合并视频片段 |

### 前端状态管理

Pinia store 位于 `frontweb/src/stores/film.js`，缓存剧目/剧集/资产数据。页面组件直接调用 store action，store 内调用 Axios。

## 关键配置

| 文件 | 用途 |
|------|------|
| `backend-node/configs/config.yaml` | 端口、DB 路径、存储目录、语言（zh/en） |
| `frontweb/vite.config.js` | 开发代理规则（`:3013` → `:5679`） |
| `desktop/main.js` | Electron 窗口 + 子进程启动后端逻辑 |

## 数据库迁移

`migrate.js` 在后端启动时自动执行，支持旧数据库列检测升级。手动跑迁移：

```bash
cd backend-node && npm run migrate
```

迁移文件位于 `backend-node/src/db/migrations/`，按序号递增命名。

## 注意事项

- Node.js ≥ 18（`better-sqlite3` 依赖现代 V8）。
- 桌面打包前必须先运行 `npm run rebuild:backend-native`，否则 `better-sqlite3` ABI 不匹配。
- 开发环境视频合并依赖系统 PATH 中的 FFmpeg 或 `backend-node/tools/ffmpeg/` 内置二进制；桌面版已内置但体积 ~95 MB，已触发 GitHub LFS 警告，勿直接 `git add` 该文件。
- `stubs.js` 路由提供 mock 端点，用于前端脱离 AI 服务调试。
