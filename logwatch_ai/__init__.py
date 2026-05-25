"""
logwatch-ai — Lightweight Cloud Agent for Windows Event Log Anomaly Detection

This package provides a lightweight agent that monitors Windows Event Logs
and sends them to the LogWatch AI cloud server for real-time ML analysis.

The ML model (Isolation Forest) runs on the server — NOT on your machine.
This agent is intentionally lightweight with minimal dependencies.

Usage (CLI):
    logwatch-ai --server https://your-server.com/api/logs/ingest --api-key YOUR_KEY

Usage (Python):
    from logwatch_ai import LogAgent

    agent = LogAgent(
        server_url="https://your-server.com/api/logs/ingest",
        api_key="your-project-api-key",
    )
    agent.run()
"""

from logwatch_ai.agent import LogAgent

__version__ = "2.0.0"
__all__ = ["LogAgent"]
