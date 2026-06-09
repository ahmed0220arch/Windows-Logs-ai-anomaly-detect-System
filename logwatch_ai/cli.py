"""
LogWatch AI Agent — CLI Entry Point.

Usage:
    # Using a config file:
    logwatch-ai

    # Using command-line arguments:
    logwatch-ai --server https://your-server.com/api/logs/ingest --api-key YOUR_KEY

    # Custom config file path:
    logwatch-ai --config /path/to/logagent.yaml
"""

import argparse
import sys

from logwatch_ai.agent import LogAgent


def main():
    """CLI entry point for the LogWatch AI agent."""
    parser = argparse.ArgumentParser(
        prog="logwatch-ai",
        description=(
            "LogWatch AI Agent — Lightweight Windows Event Log monitor. "
            "Collects system logs and sends them to the LogWatch AI cloud "
            "server for real-time ML anomaly detection."
        ),
    )

    parser.add_argument(
        "--server",
        type=str,
        default=None,
        help="Cloud server URL (e.g. https://your-app.onrender.com/api/logs/ingest)",
    )
    parser.add_argument(
        "--api-key",
        type=str,
        default=None,
        help="Project API key from the LogWatch AI dashboard",
    )
    parser.add_argument(
        "--config",
        type=str,
        default="logagent.yaml",
        help="Path to YAML config file (default: logagent.yaml)",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=100,
        help="Max logs per batch (default: 100)",
    )
    parser.add_argument(
        "--poll-interval",
        type=int,
        default=5,
        help="Seconds between log checks (default: 5)",
    )

    parser.add_argument(
        "--install-startup",
        action="store_true",
        help="Install the agent to run silently in the background on Windows startup",
    )

    args = parser.parse_args()

    if args.install_startup:
        import winreg
        import os
        try:
            pythonw_path = sys.executable.replace("python.exe", "pythonw.exe")
            if not os.path.exists(pythonw_path):
                pythonw_path = sys.executable
                
            # The command to run silently
            command = f'"{pythonw_path}" -c "from logwatch_ai.cli import main; main()"'
            
            key_path = r"Software\Microsoft\Windows\CurrentVersion\Run"
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path, 0, winreg.KEY_SET_VALUE)
            winreg.SetValueEx(key, "LogWatchAIAgent", 0, winreg.REG_SZ, command)
            winreg.CloseKey(key)
            print("==========================================================")
            print("[SUCCESS] LogWatch AI Agent added to Windows Startup!")
            print("It will now run silently in the background every time you")
            print("turn on your computer.")
            print("==========================================================")
        except Exception as e:
            print(f"[ERROR] Failed to add to Windows Startup: {e}")
        sys.exit(0)

    # If --server and --api-key are provided, use them directly
    if args.server and args.api_key:
        agent = LogAgent(
            server_url=args.server,
            api_key=args.api_key,
            batch_size=args.batch_size,
            poll_interval_seconds=args.poll_interval,
            flush_interval_seconds=5,
        )
    else:
        # Fall back to YAML config file
        try:
            agent = LogAgent.from_yaml(args.config)
        except SystemExit as e:
            print(str(e))
            sys.exit(1)

    try:
        agent.run()
    except KeyboardInterrupt:
        print("\n[AGENT] Stopped by user.")


if __name__ == "__main__":
    main()
