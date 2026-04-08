# xiaoqimanager

一个轻量级多服务状态面板：后端用 Python 标准库，前端为静态页面，开箱即用。

## 快速开始

```bash
git clone https://github.com/kejixiaoqi666/xiaoqimanager.git
cd xiaoqimanager
bash scripts/start.sh
```

默认访问：`http://127.0.0.1:8080`

---

## 一键脚本地址（已更新）

请使用当前项目脚本地址：

- `https://raw.githubusercontent.com/kejixiaoqi666/xiaoqimanager/refs/heads/main/scripts/quickstart.sh`

```bash
curl -fsSL https://raw.githubusercontent.com/kejixiaoqi666/xiaoqimanager/refs/heads/main/scripts/quickstart.sh -o /tmp/xiaoqimanager-quickstart.sh \
  && bash /tmp/xiaoqimanager-quickstart.sh
```

> 如果你使用的是自己的 fork，请把 URL 中的 `kejixiaoqi666/xiaoqimanager` 替换成你的仓库路径。

---

## 一键安装/更新并启动

`quickstart.sh` 支持自动 clone / pull 并启动：

- `APP_DIR`：默认 `$HOME/xiaoqimanager`
- `REPO_URL`：默认 `https://github.com/kejixiaoqi666/xiaoqimanager.git`
- `BRANCH`：默认 `main`
- `RUN_MODE`：`daemon`（默认）或 `foreground`

示例（前台运行）：

```bash
RUN_MODE=foreground bash scripts/quickstart.sh
```

---

## 常用命令

```bash
# 前台运行
bash scripts/start.sh --foreground

# 后台运行（默认）
bash scripts/start.sh --daemon

# 状态 / 停止 / 重启
bash scripts/start.sh --status
bash scripts/start.sh --stop
bash scripts/start.sh --restart
```

日志与 PID：

- `run/xiaoqimanager.log`
- `run/xiaoqimanager.pid`

---

## API

- `GET /api/summary`：总数、在线数、离线数
- `GET /api/services`：服务配置、状态、`.env` 预览

配置文件：`config/services.json`
