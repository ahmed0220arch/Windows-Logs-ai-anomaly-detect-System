"""
Heuristic Pre-Filter for Windows Event Logs.

Purpose: Drop known-legitimate Windows system noise BEFORE
it reaches the cloud ML model. This reduces false positives,
unnecessary network traffic, and keeps the database clean.

SAFETY: If a log LOOKS like system noise but has a suspicious
path or arguments, it is NOT dropped — it goes straight
to the ML model for anomaly scoring.
"""

import re

# Legitimate WidgetService path regex (Microsoft Store app)
_WIDGET_SERVICE_LEGIT_PATH = re.compile(
    r"C:\\Program Files\\WindowsApps\\Microsoft\.WidgetsPlatformRuntime_[^\\]+_x64__8wekyb3d8bbwe\\WidgetService\\WidgetService\.exe",
    re.IGNORECASE,
)
_WIDGET_SERVICE_LEGIT_ARGS = "-RegisterProcessAsComServer -Embedding"

# Suspicious paths that malware uses to disguise as system processes
_SUSPICIOUS_PATHS = re.compile(
    r"(C:\\Temp|\\AppData\\|C:\\Users\\[^\\]+\\Downloads|C:\\ProgramData\\(?!Microsoft))",
    re.IGNORECASE,
)

# Known safe Windows Security audit patterns (AUTORITE NT / SYSTEM logons)
_SAFE_SYSTEM_LOGON = re.compile(
    r"S-1-5-18\s*\|.*(?:AUTORITE NT|NT AUTHORITY).*\|.*0x3e7",
    re.IGNORECASE,
)
_SAFE_PRIVILEGE_ASSIGN = re.compile(
    r"S-1-5-18\s*\|.*(?:Système|SYSTEM).*\|.*Se\w+Privilege",
    re.IGNORECASE,
)
_SAFE_SERVICES_EXE_LOGON = re.compile(
    r"C:\\Windows\\System32\\services\.exe.*%%1833",
    re.IGNORECASE,
)

# svchost SID-enumeration / account-audit noise
_SAFE_SVCHOST_ACCOUNT_ENUM = re.compile(
    r"S-1-5-21-\d+-\d+-\d+-\d+\s*\|\s*S-1-5-18\s*\|.*WORKGROUP.*svchost\.exe",
    re.IGNORECASE,
)

# Standard user logon audit events with MicrosoftAccount or interactive logon
_SAFE_LOGON_AUDIT = re.compile(
    r"S-1-5-21-\d+-\d+-\d+-\d+\s*\|.*\|.*0x[0-9a-f]+\s*\|.*MicrosoftAccount:",
    re.IGNORECASE,
)

# Builtin Windows account enumeration
_SAFE_BUILTIN_ACCOUNT_NAMES = re.compile(
    r"^(?:Administrateur|Invité|DefaultAccount|Administrator|Guest|WDAGUtilityAccount|CodexSandbox\w*)\s*\|",
    re.IGNORECASE,
)

# Generic WORKGROUP svchost audits with 0x2020 logon type
_SAFE_WORKGROUP_AUDIT = re.compile(
    r"WORKGROUP\s*\|\s*0x3e7\s*\|\s*0x2020\s*\|",
    re.IGNORECASE,
)


def is_known_noise(message: str, source_name: str) -> bool:
    """
    Returns True if the log is known-legitimate Windows noise
    that should be DROPPED (not sent to the cloud ML model).

    Returns False if the log should be SENT for ML scoring.
    """
    text = message or ""

    # --- WidgetService Heuristic ---
    if "WidgetService" in text or "WidgetService" in source_name:
        has_legit_path = bool(_WIDGET_SERVICE_LEGIT_PATH.search(text))
        has_legit_args = _WIDGET_SERVICE_LEGIT_ARGS in text
        has_suspicious_path = bool(_SUSPICIOUS_PATHS.search(text))

        if has_legit_path and has_legit_args and not has_suspicious_path:
            return True  # Safe: drop it
        else:
            return False  # Suspicious variant: SEND TO ML!

    # --- svchost.exe SID-Enumeration / Account Audit Noise ---
    if _SAFE_SVCHOST_ACCOUNT_ENUM.search(text):
        if not _SUSPICIOUS_PATHS.search(text):
            return True

    # --- Builtin Account Name Enumeration ---
    if _SAFE_BUILTIN_ACCOUNT_NAMES.search(text):
        if "svchost.exe" in text.lower() or "lsass.exe" in text.lower():
            return True

    # --- WORKGROUP 0x2020 Audit Logs ---
    if _SAFE_WORKGROUP_AUDIT.search(text):
        if not _SUSPICIOUS_PATHS.search(text):
            return True

    # --- MicrosoftAccount Login Events ---
    if _SAFE_LOGON_AUDIT.search(text):
        if not _SUSPICIOUS_PATHS.search(text):
            return True

    # --- Windows SYSTEM Account Routine Audit Logs ---
    if _SAFE_SYSTEM_LOGON.search(text):
        if _SUSPICIOUS_PATHS.search(text):
            return False  # Suspicious: SEND TO ML!

        if _SAFE_PRIVILEGE_ASSIGN.search(text):
            return True

        if _SAFE_SERVICES_EXE_LOGON.search(text):
            return True

    # Not recognized as noise — send to ML
    return False
