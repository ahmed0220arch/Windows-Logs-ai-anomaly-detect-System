# ============================================================================
#  LOGWATCH AI — ADVANCED CYBER ATTACK SIMULATION SCRIPT
#  For live demonstration & jury presentation
#  All attacks are SAFE simulations — nothing is permanently damaged.
# ============================================================================

$banner = @"

  ██╗  ██╗ █████╗  ██████╗██╗  ██╗    ██╗      █████╗ ██████╗ 
  ██║  ██║██╔══██╗██╔════╝██║ ██╔╝    ██║     ██╔══██╗██╔══██╗
  ███████║███████║██║     █████╔╝     ██║     ███████║██████╔╝
  ██╔══██║██╔══██║██║     ██╔═██╗     ██║     ██╔══██║██╔══██╗
  ██║  ██║██║  ██║╚██████╗██║  ██╗    ███████╗██║  ██║██████╔╝
  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚═╝  ╚═╝╚═════╝
                                                                 
"@

Clear-Host
Write-Host $banner -ForegroundColor Red
Write-Host "  LOGWATCH AI — ADVANCED CYBER ATTACK SIMULATION" -ForegroundColor White
Write-Host "  ================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  This script launches 6 realistic attack simulations." -ForegroundColor Gray
Write-Host "  Each attack creates VISIBLE system activity (check Task Manager!)" -ForegroundColor Gray
Write-Host "  The LogWatch AI Agent will detect and report every anomaly." -ForegroundColor Gray
Write-Host ""
Write-Host "  [!] Make sure the LogWatch Agent is running in another window." -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Seconds 3

# ────────────────────────────────────────────────────────────────
# ATTACK 1: CRYPTOMINER — CPU SPIKE
# ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║  ATTACK 1/6: CRYPTOMINER MALWARE (XMRig)                       ║" -ForegroundColor Red
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""
Write-Host "  WHAT THIS SIMULATES:" -ForegroundColor Cyan
Write-Host "  A cryptomining trojan has infected the system. The malware" -ForegroundColor White
Write-Host "  hijacks 100% of CPU resources to mine Monero cryptocurrency." -ForegroundColor White
Write-Host "  In a real attack, this would cause extreme slowdowns, high" -ForegroundColor White
Write-Host "  electricity costs, and hardware degradation." -ForegroundColor White
Write-Host ""
Write-Host "  >> Open Task Manager (Ctrl+Shift+Esc) — watch the CPU spike!" -ForegroundColor Yellow
Write-Host ""

# Inject event logs for the agent to detect
eventcreate /t ERROR /id 666 /l application /d "CRITICAL: Cryptomining malware XMRig detected — CPU usage at 100%, mining pool connection to xmr.pool.minergate.com:45700 established." | Out-Null
eventcreate /t ERROR /id 666 /l application /d "ALERT: Unauthorized process 'svchost_miner.exe' consuming all CPU cores. Cryptocurrency wallet address: 48edfHu7V9Z84Yg... detected in memory." | Out-Null
eventcreate /t ERROR /id 666 /l application /d "WARNING: System temperature critical (94°C). Cryptojacking payload active since boot. Persistence mechanism found in HKLM\Software\Microsoft\Windows\CurrentVersion\Run." | Out-Null

# Actually spike the CPU so it shows in Task Manager (8 seconds, then auto-kill)
Write-Host "  [*] Launching cryptominer simulation..." -ForegroundColor Green
$cpuJobs = @()
$coreCount = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
for ($i = 0; $i -lt $coreCount; $i++) {
    $cpuJobs += Start-Job -ScriptBlock {
        $end = (Get-Date).AddSeconds(8)
        while ((Get-Date) -lt $end) { [Math]::Sqrt(12345.6789) | Out-Null }
    }
}
Write-Host "  [*] CPU at 100% across $coreCount cores — mining simulation active..." -ForegroundColor Red
Start-Sleep -Seconds 8
$cpuJobs | Stop-Job -PassThru | Remove-Job -Force
Write-Host "  [✓] Cryptominer killed. CPU returned to normal." -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 3


# ────────────────────────────────────────────────────────────────
# ATTACK 2: RANSOMWARE — FILE ENCRYPTION
# ────────────────────────────────────────────────────────────────
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║  ATTACK 2/6: RANSOMWARE (LockBit 4.0 Simulation)              ║" -ForegroundColor Red
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""
Write-Host "  WHAT THIS SIMULATES:" -ForegroundColor Cyan
Write-Host "  The LockBit ransomware gang has deployed their payload." -ForegroundColor White
Write-Host "  It rapidly encrypts files and replaces them with .locked" -ForegroundColor White
Write-Host "  extensions. A ransom note demands Bitcoin payment." -ForegroundColor White
Write-Host "  In a real attack, all documents, photos, and databases" -ForegroundColor White
Write-Host "  become permanently inaccessible without the decryption key." -ForegroundColor White
Write-Host ""

# Create a temporary folder with fake company files, then "encrypt" them
$ransomDir = "$env:TEMP\LogWatch_RansomwareDemo"
New-Item -ItemType Directory -Path $ransomDir -Force | Out-Null

$fakeFiles = @(
    "Q4_Financial_Report.xlsx",
    "Employee_Database.csv",
    "Client_Contracts_2026.docx",
    "Server_Backup_Config.json",
    "CEO_Inbox_Export.pst",
    "Production_Database_Dump.sql",
    "HR_Salary_Records.xlsx",
    "Source_Code_Repository.zip"
)

Write-Host "  [*] Creating target files..." -ForegroundColor Green
foreach ($f in $fakeFiles) {
    Set-Content -Path "$ransomDir\$f" -Value "CONFIDENTIAL COMPANY DATA — $(Get-Date)"
}

Start-Sleep -Seconds 1

Write-Host "  [*] Encrypting files..." -ForegroundColor Red
foreach ($f in $fakeFiles) {
    $src = "$ransomDir\$f"
    if (Test-Path $src) {
        # Overwrite content with "encrypted" gibberish
        $encrypted = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("LOCKBIT4-ENCRYPTED-$(Get-Random)-$(Get-Random)"))
        Set-Content -Path $src -Value $encrypted
        Rename-Item -Path $src -NewName "$f.locked" -Force
        Write-Host "    [ENCRYPTED] $f  -->  $f.locked" -ForegroundColor DarkRed
        Start-Sleep -Milliseconds 300
    }
}

# Drop a ransom note
$note = @"
  ╔════════════════════════════════════════════════╗
  ║            YOUR FILES ARE ENCRYPTED            ║
  ║                                                ║
  ║  All your files have been encrypted by         ║
  ║  LockBit 4.0 ransomware.                       ║
  ║                                                ║
  ║  To decrypt, send 2.5 BTC to:                  ║
  ║  bc1q84d0k2f5nh3...                            ║
  ║                                                ║
  ║  You have 72 hours before files are deleted.    ║
  ╚════════════════════════════════════════════════╝
"@
Set-Content -Path "$ransomDir\!!!_READ_ME_!!!.txt" -Value $note
Write-Host ""
Write-Host $note -ForegroundColor DarkRed

# Inject event logs
eventcreate /t ERROR /id 911 /l application /d "RANSOMWARE ALERT: LockBit 4.0 payload executed. 8 critical files encrypted with AES-256. Ransom note dropped. Shadow copies deleted via vssadmin." | Out-Null
eventcreate /t ERROR /id 911 /l application /d "CRITICAL: Mass file encryption detected in user directories. Extensions changed to .locked. Encryption rate: 150 files/second." | Out-Null
eventcreate /t ERROR /id 911 /l system /d "Volume Shadow Copy Service error: VSS was shut down due to an unexpected process termination. Possible ransomware anti-recovery tactic." | Out-Null

Write-Host ""
Write-Host "  [✓] Ransomware simulation complete. Files at: $ransomDir" -ForegroundColor Green
Write-Host "  [✓] All files are fake — no real data was harmed." -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 5


# ────────────────────────────────────────────────────────────────
# ATTACK 3: CREDENTIAL DUMPING (Mimikatz-style)
# ────────────────────────────────────────────────────────────────
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║  ATTACK 3/6: CREDENTIAL THEFT (Mimikatz Memory Dump)           ║" -ForegroundColor Red
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""
Write-Host "  WHAT THIS SIMULATES:" -ForegroundColor Cyan
Write-Host "  An attacker uses Mimikatz to dump plaintext passwords" -ForegroundColor White
Write-Host "  directly from Windows LSASS memory. This is the #1 tool" -ForegroundColor White
Write-Host "  used in real-world breaches (SolarWinds, Colonial Pipeline)." -ForegroundColor White
Write-Host "  With stolen credentials, attackers move laterally across" -ForegroundColor White
Write-Host "  the entire network and escalate to Domain Admin." -ForegroundColor White
Write-Host ""

# Simulate Mimikatz-style output
Write-Host "  [*] Accessing LSASS process memory..." -ForegroundColor Green
Start-Sleep -Seconds 1

$fakeCreds = @(
    @{User="Administrator"; Domain="NEOPOLIS"; NTLM="aad3b435b51404eeaad3b435b51404ee"; Pass="P@ssw0rd2026!"},
    @{User="svc_backup"; Domain="NEOPOLIS"; NTLM="31d6cfe0d16ae931b73c59d7e0c089c0"; Pass="Backup#Svc99"},
    @{User="j.dupont"; Domain="NEOPOLIS"; NTLM="e19ccf75ee54e06b06a5907af13cef42"; Pass="Welcome123!"},
    @{User="sql_service"; Domain="NEOPOLIS"; NTLM="fc525c9683e8fe067095ba2ddc971889"; Pass="SQLprod2026"}
)

Write-Host ""
Write-Host "  ============== Mimikatz 2.2.0 ==============" -ForegroundColor Magenta
Write-Host "  mimikatz # sekurlsa::logonpasswords" -ForegroundColor Magenta
Write-Host ""
foreach ($cred in $fakeCreds) {
    Write-Host "    Authentication Id : 0 ; $(Get-Random -Min 100000 -Max 999999)" -ForegroundColor White
    Write-Host "    Session           : Interactive" -ForegroundColor White
    Write-Host "    User Name         : $($cred.User)" -ForegroundColor Yellow
    Write-Host "    Domain            : $($cred.Domain)" -ForegroundColor Yellow
    Write-Host "    NTLM              : $($cred.NTLM)" -ForegroundColor Red
    Write-Host "    Password          : $($cred.Pass)" -ForegroundColor Red
    Write-Host ""
    Start-Sleep -Milliseconds 500
}

# Inject event logs
eventcreate /t ERROR /id 777 /l application /d "Security Alert: Mimikatz credential dumping tool signature detected in memory. LSASS.exe accessed by unauthorized process. 4 domain credentials extracted including Domain Admin." | Out-Null
eventcreate /t ERROR /id 777 /l system /d "CRITICAL: Process attempted to read LSASS memory (PID 672). This is consistent with credential harvesting tools (Mimikatz, LaZagne, fgdump)." | Out-Null
eventcreate /t ERROR /id 777 /l application /d "ALERT: Pass-the-Hash attack detected. NTLM hash for 'Administrator@NEOPOLIS' used to authenticate to DC01 without cleartext password." | Out-Null

Write-Host "  [✓] 4 domain credentials extracted (simulated)." -ForegroundColor Green
Write-Host "  [✓] No real credentials were accessed." -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 5


# ────────────────────────────────────────────────────────────────
# ATTACK 4: DATA EXFILTRATION — MASSIVE NETWORK UPLOAD
# ────────────────────────────────────────────────────────────────
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║  ATTACK 4/6: DATA EXFILTRATION (Covert Upload to C2 Server)    ║" -ForegroundColor Red
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""
Write-Host "  WHAT THIS SIMULATES:" -ForegroundColor Cyan
Write-Host "  After stealing credentials, the attacker exfiltrates" -ForegroundColor White
Write-Host "  sensitive company data to an external Command & Control" -ForegroundColor White
Write-Host "  server. They use DNS tunneling and encrypted HTTPS to" -ForegroundColor White
Write-Host "  bypass the firewall. 2.3 GB of data is being uploaded" -ForegroundColor White
Write-Host "  including database dumps, source code, and client records." -ForegroundColor White
Write-Host ""

Write-Host "  [*] Establishing covert C2 channel to 185.220.101.42..." -ForegroundColor Green
Start-Sleep -Seconds 1
Write-Host "  [*] C2 connection established via DNS tunneling." -ForegroundColor Green
Write-Host ""

# Simulate a progress bar for data exfiltration
$totalMB = 2300
$steps = 20
$mbPerStep = $totalMB / $steps

for ($i = 1; $i -le $steps; $i++) {
    $currentMB = [math]::Round($mbPerStep * $i)
    $pct = [math]::Round(($i / $steps) * 100)
    $bar = ("█" * $i) + ("░" * ($steps - $i))
    $fileName = @("database_dump.sql","client_records.csv","source_code.tar.gz","financial_reports.xlsx","email_archive.pst","vpn_configs.ovpn","ssh_keys.tar","api_secrets.env")[$i % 8]
    Write-Host "`r  Uploading: [$bar] $pct%  ($currentMB MB / $totalMB MB)  $fileName    " -ForegroundColor Red -NoNewline
    Start-Sleep -Milliseconds 400
}
Write-Host ""
Write-Host ""

# Simulate RAM usage by allocating a large array (visible in Task Manager under PowerShell)
Write-Host "  [*] Buffering exfiltrated data in memory..." -ForegroundColor Green
$memoryBlob = New-Object byte[] (50MB)
[System.Random]::new().NextBytes($memoryBlob)
Start-Sleep -Seconds 3

# Inject event logs
eventcreate /t ERROR /id 888 /l application /d "DATA EXFILTRATION ALERT: 2.3 GB of data uploaded to external IP 185.220.101.42 (Tor exit node). DNS tunneling detected on port 53." | Out-Null
eventcreate /t ERROR /id 888 /l application /d "CRITICAL: Outbound data transfer anomaly — 2,300 MB uploaded in 15 minutes to unknown external server. Files include database dumps and SSH private keys." | Out-Null
eventcreate /t ERROR /id 888 /l system /d "ALERT: Unusual DNS query volume detected. 45,000 TXT record queries to suspicious domain c2.darknet-relay.ru in the last 10 minutes. Possible DNS tunneling exfiltration." | Out-Null

# Free the memory
$memoryBlob = $null
[GC]::Collect()

Write-Host "  [✓] 2.3 GB exfiltration simulated." -ForegroundColor Green
Write-Host "  [✓] No real data was sent anywhere." -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 5


# ────────────────────────────────────────────────────────────────
# ATTACK 5: REVERSE SHELL & PERSISTENCE
# ────────────────────────────────────────────────────────────────
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║  ATTACK 5/6: REVERSE SHELL & PERSISTENCE BACKDOOR             ║" -ForegroundColor Red
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""
Write-Host "  WHAT THIS SIMULATES:" -ForegroundColor Cyan
Write-Host "  The attacker opens a reverse shell — a hidden connection" -ForegroundColor White
Write-Host "  that gives them full remote control of the machine." -ForegroundColor White
Write-Host "  They also install a persistence backdoor in the Windows" -ForegroundColor White
Write-Host "  Registry so they can reconnect even after a reboot." -ForegroundColor White
Write-Host "  This is the final stage of a full system compromise." -ForegroundColor White
Write-Host ""

Write-Host "  [*] Opening reverse shell to attacker 45.33.32.156:4444..." -ForegroundColor Green
Start-Sleep -Seconds 1

# Simulate the attacker running commands through the reverse shell
$shellCommands = @(
    @{Cmd="whoami /priv"; Out="NEOPOLIS\Administrator — SeDebugPrivilege: Enabled"},
    @{Cmd="net user hacker P@ss123 /add"; Out="The command completed successfully."},
    @{Cmd="net localgroup Administrators hacker /add"; Out="The command completed successfully."},
    @{Cmd="netsh advfirewall set allprofiles state off"; Out="Ok. (simulated — firewall NOT actually changed)"},
    @{Cmd="reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Run /v Backdoor /d C:\Windows\Temp\svchost_bd.exe"; Out="(simulated — no registry was modified)"}
)

Write-Host ""
Write-Host "  ┌──────────────────────────────────────────────────┐" -ForegroundColor DarkGray
Write-Host "  │  ATTACKER REVERSE SHELL SESSION                  │" -ForegroundColor DarkGray
Write-Host "  └──────────────────────────────────────────────────┘" -ForegroundColor DarkGray
foreach ($sc in $shellCommands) {
    Write-Host "  C:\Windows\system32> " -ForegroundColor Gray -NoNewline
    # Type out the command character by character
    foreach ($char in $sc.Cmd.ToCharArray()) {
        Write-Host $char -ForegroundColor White -NoNewline
        Start-Sleep -Milliseconds 30
    }
    Write-Host ""
    Start-Sleep -Milliseconds 300
    Write-Host "  $($sc.Out)" -ForegroundColor Yellow
    Write-Host ""
    Start-Sleep -Milliseconds 500
}

# Inject event logs
eventcreate /t ERROR /id 555 /l application /d "CRITICAL: Reverse shell connection detected to external IP 45.33.32.156:4444. PowerShell process spawned with SYSTEM privileges. Full remote access established." | Out-Null
eventcreate /t ERROR /id 555 /l system /d "ALERT: New administrator account 'hacker' created via net.exe. Privilege escalation from standard user to local admin detected." | Out-Null
eventcreate /t ERROR /id 555 /l application /d "PERSISTENCE BACKDOOR: Registry Run key modified — HKLM\Software\Microsoft\Windows\CurrentVersion\Run\Backdoor points to svchost_bd.exe. Malware will survive reboot." | Out-Null
eventcreate /t ERROR /id 555 /l system /d "FIREWALL TAMPERING: Windows Defender Firewall disabled across all profiles. System is now fully exposed to external attacks." | Out-Null

Write-Host "  [✓] Reverse shell & persistence simulated." -ForegroundColor Green
Write-Host "  [✓] No accounts were created. No registry was modified. No firewall was changed." -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 3


# ────────────────────────────────────────────────────────────────
# ATTACK 6: LIVE VIRUS DOWNLOAD (EICAR Test File)
# ────────────────────────────────────────────────────────────────
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║  ATTACK 6/6: LIVE MALWARE DOWNLOAD (EICAR Test Virus)          ║" -ForegroundColor Red
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""
Write-Host "  WHAT THIS SIMULATES:" -ForegroundColor Cyan
Write-Host "  A trojan downloader is fetching a malware payload from" -ForegroundColor White
Write-Host "  the internet. We use the EICAR test file — an industry-" -ForegroundColor White
Write-Host "  standard 'safe virus' recognized by EVERY antivirus in" -ForegroundColor White
Write-Host "  the world. It is completely harmless but will trigger" -ForegroundColor White
Write-Host "  a REAL Windows Defender alert on screen." -ForegroundColor White
Write-Host ""
Write-Host "  >> Watch for the Windows Security notification popup!" -ForegroundColor Yellow
Write-Host ""

Write-Host "  [*] Downloading malware payload from remote server..." -ForegroundColor Green
Start-Sleep -Seconds 1

# The EICAR test string — every antivirus on earth detects this as malware
# It is the official test file from eicar.org — 100% safe, 0% harmful
$eicarString = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
$eicarPath = "$env:TEMP\totally_not_a_virus.exe"

try {
    # Write the EICAR test file — Windows Defender should instantly detect and quarantine it
    [System.IO.File]::WriteAllText($eicarPath, $eicarString)
    Write-Host "  [*] Malware payload written to: $eicarPath" -ForegroundColor Red
    Start-Sleep -Seconds 3
    
    if (Test-Path $eicarPath) {
        Write-Host "  [!] WARNING: Antivirus did NOT detect the payload!" -ForegroundColor DarkYellow
        Write-Host "  [*] Cleaning up manually..." -ForegroundColor Gray
        Remove-Item $eicarPath -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "  [✓] Windows Defender DETECTED and QUARANTINED the malware!" -ForegroundColor Green
        Write-Host "  [✓] This proves real-time protection is working." -ForegroundColor Green
    }
} catch {
    Write-Host "  [✓] Windows Defender BLOCKED the malware before it could be written!" -ForegroundColor Green
    Write-Host "  [✓] Real-time protection intercepted the file creation." -ForegroundColor Green
}

# Inject event logs
eventcreate /t ERROR /id 444 /l application /d "MALWARE DETECTED: Trojan downloader fetched payload from hxxps://malware-cdn.darkweb.ru/payload.exe. File written to TEMP directory. Windows Defender quarantine triggered." | Out-Null
eventcreate /t ERROR /id 444 /l system /d "CRITICAL: Windows Defender Real-Time Protection detected 'Trojan:Win32/EicarTest' in C:\Users\TEMP\totally_not_a_virus.exe. Threat severity: SEVERE. Action taken: Quarantine." | Out-Null
eventcreate /t ERROR /id 444 /l application /d "ALERT: Outbound connection to known malware distribution server detected. URL: hxxps://malware-cdn.darkweb.ru. IP: 91.215.85.22 (Russia). Threat intelligence match: 98% confidence." | Out-Null

Write-Host ""
Write-Host "  [✓] Virus download simulation complete." -ForegroundColor Green
Write-Host "  [✓] The EICAR file is an industry-standard safe test — zero risk." -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 3


# ────────────────────────────────────────────────────────────────
# FINAL SUMMARY
# ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    ATTACK SEQUENCE COMPLETE                    ║" -ForegroundColor Cyan
Write-Host "╠══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "║   ✓ Attack 1: Cryptominer (XMRig) — CPU spike to 100%         ║" -ForegroundColor White
Write-Host "║   ✓ Attack 2: Ransomware (LockBit 4.0) — 8 files encrypted   ║" -ForegroundColor White
Write-Host "║   ✓ Attack 3: Credential Theft (Mimikatz) — 4 passwords       ║" -ForegroundColor White
Write-Host "║   ✓ Attack 4: Data Exfiltration — 2.3 GB to C2 server        ║" -ForegroundColor White
Write-Host "║   ✓ Attack 5: Reverse Shell — Full system compromise          ║" -ForegroundColor White
Write-Host "║   ✓ Attack 6: Live Virus — Windows Defender triggered!        ║" -ForegroundColor White
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "║   Total event logs injected: 19                               ║" -ForegroundColor Yellow
Write-Host "║   The LogWatch AI Agent is now analyzing all anomalies.       ║" -ForegroundColor Yellow
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "║   >> Go to https://ai-logwatch.me to see the results! <<      ║" -ForegroundColor Green
Write-Host "║                                                                ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Cleanup the ransomware demo folder
Remove-Item -Path "$env:TEMP\LogWatch_RansomwareDemo" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  [Cleanup] Ransomware demo files deleted." -ForegroundColor DarkGray
Write-Host ""

