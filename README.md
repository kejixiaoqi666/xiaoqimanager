# xiaoqimanager

小七管理（初始化正式项目）是一个**轻量级多服务管理面板**：

- 后端使用 Python 标准库 HTTP 服务，不依赖 Flask/FastAPI。
- 前端是静态页面，默认展示服务状态、配置预览和总览统计。
- 配置统一由 `config/services.json` 管理，适合快速接入多个内部服务。

---

## 1. 项目功能（详细说明）

### 1.1 核心能力

1. **服务清单管理**
   - 通过 `config/services.json` 声明多个服务（名称、目录、端口、健康检查地址、配置文件路径）。
2. **服务健康状态探测**
   - 管理端会轮询每个服务的 `healthEndpoint`，并返回 `online / degraded / offline` 状态。
3. **配置文件预览**
   - 自动读取每个服务的 `.env`，以键值方式展示（忽略注释和空行）。
4. **总览统计**
   - 提供总服务数、在线数、离线数等指标，方便运维快速排查。
5. **自带 Web 管理面板**
   - 启动后直接访问 `http://127.0.0.1:8080`（默认），无需额外前端构建步骤。

### 1.2 当前目录说明

- `backend/core-a`：后端 A（示例）
- `backend/core-b`：后端 B（示例）
- `config/services.json`：服务元数据配置中心
- `scripts/install.sh`：安装与初始化脚本（依赖检查 + `.env` 初始化）
- `app.py`：管理服务入口（API + 静态资源服务）
- `web/`：管理面板前端静态资源

### 1.3 API 说明

- `GET /api/summary`
  - 返回服务总数、在线数、离线数。
- `GET /api/services`
  - 返回每个服务的详情：
    - 基础配置（name/path/port/healthEndpoint/config）
    - 实时状态（status）
    - 配置预览（envPreview）

---

## 2. 正确安装与启动方式（避免 “No such file or directory”）

你报错的根因是：在 `~` 目录直接执行了 `bash scripts/install.sh`，而不是在仓库目录中执行。

请按以下顺序：

```bash
git clone https://github.com/doubleDimple/oci-start.git
cd oci-start
bash scripts/install.sh
python3 app.py
```

启动成功后访问：

- `http://127.0.0.1:8080`

> 注意：`scripts/install.sh` 与 `app.py` 都是**相对仓库根目录**的路径，必须先 `cd` 到项目目录。

如果你希望“真正一键启动”（自动安装 + 后台运行 + PID/日志管理），直接用：

```bash
bash scripts/start.sh
```

常用命令：

```bash
# 前台运行（便于调试）
bash scripts/start.sh --foreground

# 查看状态 / 停止 / 重启
bash scripts/start.sh --status
bash scripts/start.sh --stop
bash scripts/start.sh --restart
```

日志和 PID 文件位置：

- `run/xiaoqimanager.log`
- `run/xiaoqimanager.pid`

---


## 一键安装/更新并启动（单行命令）

如果你希望像 `curl ... && bash ...` 这样的方式进行“安装 + 更新 + 启动”，可直接执行：

```bash
curl -fsSL https://raw.githubusercontent.com/doubleDimple/oci-start/main/scripts/quickstart.sh -o /tmp/xiaoqimanager-quickstart.sh && bash /tmp/xiaoqimanager-quickstart.sh
```

可选环境变量：

- `APP_DIR`：默认 `$HOME/xiaoqimanager`
- `REPO_URL`：默认 `https://github.com/doubleDimple/oci-start.git`
- `BRANCH`：默认 `main`
- `RUN_MODE`：`daemon`（默认）或 `foreground`

示例（前台运行）：

```bash
RUN_MODE=foreground curl -fsSL https://raw.githubusercontent.com/doubleDimple/oci-start/main/scripts/quickstart.sh -o /tmp/xiaoqimanager-quickstart.sh && bash /tmp/xiaoqimanager-quickstart.sh
```

---

## 3. install.sh 会做什么

`scripts/install.sh` 现在包含以下动作：

1. 检查并安装基础依赖（Debian/Ubuntu 系统下自动安装）
   - `python3`
   - `curl`
2. 创建项目必需目录（如不存在）
3. 初始化 `backend/core-a/.env` 与 `backend/core-b/.env`
   - 优先从 `.env.example` 复制
   - 若模板不存在，则生成默认 `.env`
4. 校验 `config/services.json` 是否存在
5. 输出下一步启动命令

---

## 4. 运行参数

`app.py` 支持环境变量：

- `WEB_HOST`：默认 `127.0.0.1`
- `WEB_PORT`：默认 `8080`

示例：

```bash
WEB_HOST=0.0.0.0 WEB_PORT=8080 python3 app.py
```

---

## 5. 常见问题（FAQ）

### Q1: `bash: scripts/install.sh: No such file or directory`
A: 你当前目录不在仓库根目录，先执行 `cd oci-start`（或你的项目实际目录）。

### Q2: `python3: can't open file 'app.py': [Errno 2] No such file or directory`
A: 同上，`app.py` 不在当前目录；请进入仓库根目录后再执行。

### Q2.1: 我已经 `cd oci-start` 了，为什么还是提示没有 `scripts/install.sh` / `app.py`？
A: 这通常不是目录问题，而是你当前仓库内容不对（比如克隆到了同名但不同内容的仓库、切到了错误分支，或拉取不完整）。

请直接执行下面这组“强校验”命令：

```bash
pwd
git remote -v
git branch --show-current
find . -maxdepth 2 -type f \( -name "install.sh" -o -name "app.py" -o -name "services.json" \)
```

在正确仓库中，你至少应看到：

- `./scripts/install.sh`
- `./app.py`
- `./config/services.json`

如果看不到，请删除后重新克隆（避免旧目录污染）：

```bash
cd ~
rm -rf oci-start
git clone https://github.com/doubleDimple/oci-start.git
cd oci-start
bash scripts/install.sh
WEB_HOST=0.0.0.0 WEB_PORT=8080 python3 app.py
```

### Q3: 脚本能否在 CentOS / Rocky 使用？
A: 当前自动安装依赖仅内置 `apt-get` 路径。若系统无 `apt-get`，脚本会提示你手动安装 `python3` 和 `curl`。

---

## 6. 适用场景

- 单机部署时快速查看多服务健康状态
- 开发/测试环境统一查看服务配置与状态
- 作为更完整运维平台（如 Prometheus/Grafana）前的轻量入口
