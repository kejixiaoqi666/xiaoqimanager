# xiaoqimanager
小七管理（初始化正式项目）

## 当前结构

- `backend/core-a`：后端 A 目录
- `backend/core-b`：后端 B 目录
- `config/services.json`：统一管理后端目录、端口、健康检查地址、配置文件路径
- `scripts/install.sh`：初始化安装脚本（会自动创建并补齐后端 `.env`）
- `app.py`：轻量管理服务（提供 API + web 面板静态资源）
- `web/`：管理面板前端页面

## 快速开始

```bash
bash scripts/install.sh
python3 app.py
```

打开 `http://127.0.0.1:8080` 查看 web 面板。

## API

- `GET /api/summary`：服务总览
- `GET /api/services`：服务详情（含 `.env` 预览、状态）
