# 运维操作手册

> **文档职责**：覆盖 LocalMiniDrama 本地开发环境的从零安装到日常服务管理全流程
> **适用场景**：首次搭建环境、日常启停服务、排查服务异常
> **目标读者**：开发者，具备基础命令行操作能力，无需了解项目内部架构
> **维护规范**：修改端口或服务数量时同步更新"服务地址"和脚本说明；新增依赖时同步更新"前置要求"节

---

## 一、前置要求

| 依赖 | 版本要求 | 验证命令 |
|------|----------|----------|
| Node.js | ≥ 18 | `node -v` |
| npm | 随 Node.js 附带 | `npm -v` |
| macOS / Linux | — | — |

> Windows 用户请使用项目根目录的 `run_dev.bat`，不使用本手册中的 shell 脚本。

---

## 二、首次环境安装

按顺序执行以下步骤，只需做一次。

### 1. 安装后端依赖

```bash
cd backend-node
npm install --registry https://registry.npmmirror.com
```

### 2. 安装前端依赖

```bash
cd frontweb
npm install --registry https://registry.npmmirror.com
```

### 3. 初始化数据库

```bash
cd backend-node
npm run migrate
```

输出 `Migrations complete.` 表示成功。

> 后续启动会自动执行增量迁移，**无需重复手动执行**。

### 4. 确认配置文件

```bash
ls backend-node/configs/config.yaml
```

文件存在则跳过。若不存在：

```bash
cp backend-node/configs/config.example.yaml backend-node/configs/config.yaml
```

然后按需修改端口、数据库路径、语言（`zh` / `en`）。AI 接口密钥可在启动后通过 UI「AI 配置」页面填写，无需直接编辑文件。

---

## 三、服务管理

所有操作通过项目根目录的 **`service.sh`** 统一管理：

```
./service.sh {start|stop|restart|status}
```

### 命令速查

| 命令 | 说明 |
|------|------|
| `./service.sh start` | 启动所有服务（已运行则跳过） |
| `./service.sh stop` | 停止所有服务 |
| `./service.sh restart` | 重启所有服务 |
| `./service.sh status` | 查看运行状态 |

### 服务地址

| 服务 | 地址 |
|------|------|
| 前端（开发） | http://localhost:3013 |
| 后端 API | http://localhost:5679/api/v1 |
| 健康检查 | http://localhost:5679/health |

### 示例输出

**start**
```
[INFO]  启动 backend...
[INFO]  backend 已启动  PID=12345  端口=5679
[INFO]  日志文件：scripts/logs/backend.log
[INFO]  启动 frontend...
[INFO]  frontend 已启动  PID=12389  端口=3013
[INFO]  日志文件：scripts/logs/frontend.log
```

**status**
```
[backend]
  ● 运行中  端口=5679  PID=12345
  地址：http://localhost:5679/api/v1

[frontend]
  ● 运行中  端口=3013  PID=12389
  地址：http://localhost:3013
```

---

## 四、脚本结构

```
service.sh              ← 统一入口（委托给 scripts/ 下的子脚本）
scripts/
├── start.sh            ← 启动服务，等待端口就绪后返回
├── stop.sh             ← 按端口杀进程，清理 PID 文件
├── restart.sh          ← stop → start
├── status.sh           ← 检查端口占用，打印状态
├── .pids/              ← 运行时 PID 文件（gitignored）
└── logs/               ← 服务日志（gitignored）
    ├── backend.log
    └── frontend.log
```

---

## 五、日志查看

```bash
# 实时跟踪后端日志
tail -f scripts/logs/backend.log

# 实时跟踪前端日志
tail -f scripts/logs/frontend.log
```

日志文件累积追加，不会自动轮转。若文件过大，手动清空：

```bash
> scripts/logs/backend.log
> scripts/logs/frontend.log
```

---

## 六、常见问题

### 端口被占用，start 报 WARN 跳过

先检查是否有残留进程：

```bash
./service.sh status
```

如果显示已停止但端口仍被占用，说明有其他程序占用该端口：

```bash
lsof -i tcp:5679    # 查看占用后端端口的进程
lsof -i tcp:3013    # 查看占用前端端口的进程
```

### 启动超时（等待 15 秒后报错）

查看日志定位原因：

```bash
tail -50 scripts/logs/backend.log
```

常见原因：`config.yaml` 配置错误、数据库文件权限问题。

### better-sqlite3 模块报错

```bash
cd backend-node
npm install --registry https://registry.npmmirror.com
```

如果在 Electron 桌面版开发，还需重编译：

```bash
cd desktop
npm run rebuild:backend-native
```
