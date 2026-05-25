# logwatch-ai

Lightweight cloud agent for Windows Event Log anomaly detection.

This package installs a small, efficient agent on your Windows machine that monitors system logs in real-time and sends them to the **LogWatch AI cloud server** for ML-powered anomaly detection. The machine learning model (Isolation Forest) runs entirely on the server — your machine only runs the lightweight collector.

---

## Installation

```bash
pip install logwatch-ai
```

---

## Quick Start

### 1. Get your API key

Log into the LogWatch AI dashboard, go to **Projects**, create a new project, and copy the generated API key.

### 2. Run the agent

**Option A — Command line:**

```bash
logwatch-ai --server https://your-server.onrender.com/api/logs/ingest --api-key YOUR_API_KEY
```

**Option B — Config file:**

Create a `logagent.yaml` file:

```yaml
server_url: "https://your-server.onrender.com/api/logs/ingest"
api_key: "YOUR_API_KEY"
batch_size: 100
poll_interval_seconds: 5
flush_interval_seconds: 60
sqlite_db_path: "local_buffer.db"
```

Then simply run:

```bash
logwatch-ai
```

**Option C — Python API:**

```python
from logwatch_ai import LogAgent

agent = LogAgent(
    server_url="https://your-server.onrender.com/api/logs/ingest",
    api_key="YOUR_API_KEY",
)
agent.run()
```

---

## How It Works

```
YOUR WINDOWS MACHINE                    LOGWATCH AI CLOUD SERVER
┌─────────────────────┐                 ┌──────────────────────┐
│  logwatch-ai agent  │── HTTPS POST ──▶│  FastAPI + ML Model  │
│  (this package)     │   X-API-Key     │  Isolation Forest    │
│                     │                 │  25-feature scoring  │
│  • Reads Event Logs │                 │  Anomaly detection   │
│  • Filters noise    │                 │  Email alerts        │
│  • Sends via HTTPS  │                 │  Dashboard           │
│  • ~20KB, no ML     │                 │                      │
└─────────────────────┘                 └──────────────────────┘
```

1. The agent reads Windows Application, System, and Security event logs.
2. A heuristic pre-filter drops known-benign Windows noise (WidgetService, routine SYSTEM logons, etc.).
3. Remaining logs are batched and sent to your cloud server via HTTPS with API key auth.
4. The server's ML model (Isolation Forest, 25 features) scores each log for anomalies.
5. Detected anomalies trigger email alerts and appear on the dashboard.

---

## Features

| Feature | Description |
|---------|-------------|
| **Lightweight** | No ML dependencies. Only `requests`, `psutil`, `pywin32`, `pyyaml`. |
| **Offline resilience** | If the server is unreachable, logs are buffered in a local SQLite database and replayed automatically when connectivity returns. |
| **Heuristic pre-filter** | Drops known-benign Windows noise before sending, reducing false positives and network traffic. |
| **CPU/RAM metrics** | Attaches real-time hardware usage to each log for velocity-based anomaly detection. |
| **Auto-restart** | Automatically recovers from crashes with a 5-second backoff. |
| **CLI + Python API** | Use from the command line or import into your own scripts. |

---

## Requirements

- **Windows 10/11** (uses Windows Event Log API via pywin32)
- **Python 3.10+**
- A LogWatch AI cloud server instance with a valid project API key

---

## License

MIT License
