"""
LogWatch AI — Lightweight Cloud Agent for Windows Event Log Monitoring.

This module reads Windows Event Logs in real-time, applies a heuristic
pre-filter to drop known-benign noise, and sends the remaining logs
to the LogWatch AI cloud server via HTTPS for ML anomaly detection.

The ML model (Isolation Forest) runs EXCLUSIVELY on the server.
This agent is intentionally lightweight — no ML dependencies required.
"""

import json
import os
import sqlite3
import time
from typing import Dict, List, Tuple

import psutil
import requests
import yaml

try:
    import win32evtlog
except ImportError as exc:
    raise SystemExit(
        "pywin32 is required. Install it with: pip install pywin32\n"
        "Note: This agent only runs on Windows 10/11."
    ) from exc

from logwatch_ai.filters import is_known_noise


# =========================================================
# Windows Event Log Level Mapping
# =========================================================
EVENT_TYPE_MAP = {
    win32evtlog.EVENTLOG_ERROR_TYPE: "ERROR",
    win32evtlog.EVENTLOG_WARNING_TYPE: "WARNING",
    win32evtlog.EVENTLOG_INFORMATION_TYPE: "INFO",
    win32evtlog.EVENTLOG_AUDIT_SUCCESS: "INFO",
    win32evtlog.EVENTLOG_AUDIT_FAILURE: "WARNING",
}

TARGET_LOGS = ["Application", "System", "Security"]


class LogAgent:
    """
    Lightweight Windows Event Log agent that streams logs to a cloud server.

    Usage:
        agent = LogAgent(
            server_url="https://your-server.onrender.com/api/logs/ingest",
            api_key="your-project-api-key",
        )
        agent.run()  # Starts the monitoring loop

    The agent:
    - Monitors Application, System, and Security event logs
    - Applies heuristic pre-filtering to drop known-benign noise
    - Batches logs and sends them via HTTPS POST
    - Buffers logs locally in SQLite if the server is unreachable
    - Attaches CPU/RAM usage metrics to each log
    """

    def __init__(
        self,
        server_url: str,
        api_key: str,
        batch_size: int = 100,
        poll_interval_seconds: int = 5,
        flush_interval_seconds: int = 5,
        sqlite_db_path: str = "local_buffer.db",
    ):
        self.server_url = server_url
        self.api_key = api_key
        self.batch_size = batch_size
        self.poll_interval_seconds = poll_interval_seconds
        self.flush_interval_seconds = flush_interval_seconds
        self.sqlite_db_path = sqlite_db_path

        self.headers = {
            "Content-Type": "application/json",
            "X-API-Key": self.api_key,
        }

    @classmethod
    def from_yaml(cls, config_path: str = "logagent.yaml") -> "LogAgent":
        """
        Create a LogAgent from a YAML configuration file.

        Expected YAML structure:
            server_url: "https://your-server.onrender.com/api/logs/ingest"
            api_key: "your-project-api-key"
            batch_size: 100
            poll_interval_seconds: 5
            flush_interval_seconds: 60
            sqlite_db_path: "local_buffer.db"
        """
        if not os.path.exists(config_path):
            default_yaml = (
                '# LogWatch AI Agent Configuration\n'
                'server_url: "https://your-server.onrender.com/api/logs/ingest"\n'
                'api_key: "PUT_YOUR_PROJECT_API_KEY_HERE"\n'
                'batch_size: 100\n'
                'poll_interval_seconds: 5\n'
                'flush_interval_seconds: 60\n'
                'sqlite_db_path: "local_buffer.db"\n'
            )
            with open(config_path, "w", encoding="utf-8") as f:
                f.write(default_yaml)
            raise SystemExit(
                f"[CRITICAL] Config file '{config_path}' not found. "
                f"A default has been created. Please edit it with your "
                f"server URL and API key, then restart."
            )

        with open(config_path, "r", encoding="utf-8") as f:
            config = yaml.safe_load(f)

        if not isinstance(config, dict):
            raise SystemExit(
                f"[CRITICAL] Config file '{config_path}' must be a YAML dictionary."
            )

        api_key_value = config.get("api_key")
        if not api_key_value or api_key_value == "PUT_YOUR_PROJECT_API_KEY_HERE":
            raise SystemExit(
                "[CRITICAL] Missing or placeholder api_key in config. "
                "Get a valid key from the LogWatch AI dashboard."
            )

        return cls(
            server_url=config.get("server_url", "https://localhost:8000/api/logs/ingest"),
            api_key=str(api_key_value),
            batch_size=config.get("batch_size", 100),
            poll_interval_seconds=config.get("poll_interval_seconds", 5),
            flush_interval_seconds=config.get("flush_interval_seconds", 60),
            sqlite_db_path=config.get("sqlite_db_path", "local_buffer.db"),
        )

    # ---------------------------------------------------------
    # Local SQLite Buffer (Offline Resilience)
    # ---------------------------------------------------------
    def _init_local_buffer(self) -> None:
        """Create the local SQLite buffer table if it does not exist."""
        conn = sqlite3.connect(self.sqlite_db_path)
        try:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS logs_buffer (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    payload_json TEXT NOT NULL
                )
                """
            )
            conn.commit()
        finally:
            conn.close()

    def _buffer_payloads(self, payloads: List[Dict]) -> None:
        """Store payloads locally for retry when server is unavailable."""
        if not payloads:
            return
        conn = sqlite3.connect(self.sqlite_db_path)
        try:
            rows = [(json.dumps(p),) for p in payloads]
            conn.executemany("INSERT INTO logs_buffer(payload_json) VALUES (?)", rows)
            conn.commit()
        finally:
            conn.close()
        print(f"[BUFFER] Saved {len(payloads)} logs locally for retry")

    def _read_buffer(self) -> Tuple[List[int], List[Dict]]:
        """Read buffered payloads from SQLite."""
        conn = sqlite3.connect(self.sqlite_db_path)
        try:
            rows = conn.execute(
                "SELECT id, payload_json FROM logs_buffer ORDER BY id ASC"
            ).fetchall()
        finally:
            conn.close()

        ids, payloads = [], []
        for row_id, payload_json in rows:
            try:
                parsed = json.loads(payload_json)
                if isinstance(parsed, dict):
                    ids.append(int(row_id))
                    payloads.append(parsed)
            except json.JSONDecodeError:
                print(f"[WARN] Skipping corrupted buffer entry id={row_id}")
        return ids, payloads

    def _delete_buffered(self, ids: List[int]) -> None:
        """Remove successfully sent payloads from the buffer."""
        if not ids:
            return
        conn = sqlite3.connect(self.sqlite_db_path)
        try:
            conn.executemany(
                "DELETE FROM logs_buffer WHERE id = ?",
                [(i,) for i in ids],
            )
            conn.commit()
        finally:
            conn.close()

    def _replay_buffer(self) -> bool:
        """Try sending buffered payloads. Returns True if buffer is empty or replay succeeded."""
        ids, payloads = self._read_buffer()
        if not payloads:
            return True

        print(f"[AGENT] Replaying {len(payloads)} buffered logs...")
        if self._post_batch(payloads):
            self._delete_buffered(ids)
            print(f"[OK] Replayed {len(payloads)} buffered logs")
            return True

        print("[WARN] Replay failed; keeping buffer for next retry")
        return False

    # ---------------------------------------------------------
    # Network Communication
    # ---------------------------------------------------------
    def _post_batch(self, payloads: List[Dict]) -> bool:
        """Send a batch of log payloads to the cloud server."""
        if not payloads:
            return True

        try:
            response = requests.post(
                self.server_url,
                json=payloads,
                headers=self.headers,
                timeout=10,
            )
            if response.status_code == 200:
                print(f"[OK] Sent batch of {len(payloads)} logs to server")
                return True
            else:
                print(f"[WARN] Server response {response.status_code}: {response.text[:120]}")
                return False
        except requests.exceptions.RequestException as exc:
            print(f"[WARN] Could not reach server: {exc}")
            return False

    # ---------------------------------------------------------
    # Windows Event Log Reading
    # ---------------------------------------------------------
    @staticmethod
    def _get_latest_record(log_name: str) -> int:
        """Return the latest record number in a Windows event log."""
        handle = win32evtlog.OpenEventLog(None, log_name)
        try:
            oldest = int(win32evtlog.GetOldestEventLogRecord(handle))
            total = int(win32evtlog.GetNumberOfEventLogRecords(handle))
            if total <= 0:
                return oldest
            return oldest + total - 1
        finally:
            win32evtlog.CloseEventLog(handle)

    @staticmethod
    def _read_new_events(log_name: str, last_record: int) -> Tuple[List[dict], int]:
        """
        Read events newer than last_record from the given log by reading backwards.
        Returns (payloads, new_last_record).
        """
        handle = win32evtlog.OpenEventLog(None, log_name)
        payloads: List[dict] = []
        new_last_record = last_record

        try:
            flags = (
                win32evtlog.EVENTLOG_BACKWARDS_READ
                | win32evtlog.EVENTLOG_SEQUENTIAL_READ
            )
            
            try:
                events = win32evtlog.ReadEventLog(handle, flags, 0)
            except Exception as e:
                print(f"[WARN] Failed initial read for {log_name}: {e}")
                events = ()

            if events:
                # The very first event we see when reading backwards is the newest in the log
                new_last_record = max(last_record, int(events[0].RecordNumber))

            done = False
            while events and not done:
                for event in events:
                    record_number = int(event.RecordNumber)
                    
                    # Stop if we hit an event we've already seen
                    if record_number <= last_record:
                        done = True
                        break

                    level = EVENT_TYPE_MAP.get(event.EventType, "INFO")
                    inserts = event.StringInserts or []
                    message = " | ".join(str(part) for part in inserts).strip()
                    if not message:
                        message = f"EventID={event.EventID} Source={event.SourceName}"

                    source_name = str(event.SourceName or log_name)

                    # --- HEURISTIC PRE-FILTER ---
                    if is_known_noise(message, source_name):
                        print(f"  FILTERED | {log_name}: {source_name}")
                        continue

                    payloads.append(
                        {
                            "timestamp": str(event.TimeGenerated),
                            "level": level,
                            "source": source_name,
                            "message": message,
                        }
                    )

                if not done:
                    try:
                        events = win32evtlog.ReadEventLog(handle, flags, 0)
                    except Exception:
                        events = ()
                        
        finally:
            win32evtlog.CloseEventLog(handle)

        # Because we read backwards, the payloads list has newest-first. Reverse it to send oldest-first.
        payloads.reverse()
        return payloads, new_last_record

    # ---------------------------------------------------------
    # Main Agent Loop
    # ---------------------------------------------------------
    def run(self) -> None:
        """Start the agent monitoring loop. Runs indefinitely."""
        self._init_local_buffer()

        print("=" * 60)
        print("  LogWatch AI Agent — Cloud Edition")
        print(f"  Server: {self.server_url}")
        print(f"  Batch size: {self.batch_size}")
        print(f"  Poll interval: {self.poll_interval_seconds}s")
        print("=" * 60)

        while True:
            try:
                # Initialize cursors at current tail
                last_seen: Dict[str, int] = {}
                pending: List[Dict] = []
                last_flush = time.monotonic()

                for log_name in TARGET_LOGS:
                    try:
                        last_seen[log_name] = self._get_latest_record(log_name)
                        print(f"[INIT] {log_name} cursor at record {last_seen[log_name]}")
                    except Exception as exc:
                        last_seen[log_name] = 0
                        print(f"[WARN] Could not init {log_name} cursor: {exc}")

                print("[AGENT] Monitoring Windows event logs...")

                while True:
                    # Sample CPU/RAM once per cycle
                    current_cpu = psutil.cpu_percent()
                    current_ram = psutil.virtual_memory().percent

                    replay_ok = self._replay_buffer()

                    for log_name in TARGET_LOGS:
                        try:
                            payloads, new_last = self._read_new_events(
                                log_name, last_seen[log_name]
                            )
                            last_seen[log_name] = new_last

                            for payload in payloads:
                                payload["cpu_percent"] = current_cpu
                                payload["ram_percent"] = current_ram
                                pending.append(payload)

                        except Exception as exc:
                            print(f"[WARN] Failed to read {log_name}: {exc}")

                    # Check if we should flush
                    elapsed = time.monotonic() - last_flush
                    should_flush = (
                        len(pending) >= self.batch_size
                        or (pending and elapsed >= self.flush_interval_seconds)
                    )

                    if should_flush:
                        if replay_ok and self._post_batch(pending):
                            pending.clear()
                        else:
                            self._buffer_payloads(pending)
                            pending.clear()
                        last_flush = time.monotonic()

                    time.sleep(self.poll_interval_seconds)

            except Exception as e:
                print(f"[CRITICAL] Agent crashed, restarting in 5s: {e}")
                time.sleep(5)
