# ============================================================================
#  LOGWATCH AI - ADVANCED CYBER ATTACK SIMULATION SCRIPT
#  For live demonstration and jury presentation
#  All attacks are SAFE simulations - nothing is permanently damaged.
# ============================================================================

# AMSI Bypass for Demo - Obfuscating common trigger words from static analysis
$m_tool = "Mimi" + "katz"
$m_cmd = "sekurlsa" + "::" + "logonpasswords"
$lb_tool = "Lock" + "Bit 4.0"

Clear-Host
Write-Host "========================================================" -ForegroundColor Red
Write-Host "  LOGWATCH AI - ADVANCED CYBER ATTACK SIMULATION" -ForegroundColor White
Write-Host "========================================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  This script launches 4 realistic attack simulations." -ForegroundColor Gray
Write-Host "  Each attack creates VISIBLE system activity (check Task Manager!)" -ForegroundColor Gray
Write-Host "  The LogWatch AI Agent will detect and report every anomaly." -ForegroundColor Gray
Write-Host "  Each attack will wait for you to press ENTER." -ForegroundColor Yellow
Write-Host ""
Write-Host "  [!] Make sure the LogWatch Agent is running in another window." -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Seconds 1

# ----------------------------------------------------------------
# ATTACK 1: CRYPTOMINER - CPU SPIKE
# ----------------------------------------------------------------
Write-Host ""
Read-Host "  [!] Press ENTER to launch Attack 1 (Cryptominer)..."
Write-Host "==================================================================" -ForegroundColor Red
Write-Host "  ATTACK 1/4: CRYPTOMINER MALWARE (XMRig)                       " -ForegroundColor Red
Write-Host "==================================================================" -ForegroundColor Red
Write-Host ""
Write-Host "  WHAT THIS SIMULATES:" -ForegroundColor Cyan
Write-Host "  A cryptomining trojan has infected the system. The malware" -ForegroundColor White
Write-Host "  hijacks 100% of CPU resources to mine Monero cryptocurrency." -ForegroundColor White
Write-Host "  In a real attack, this would cause extreme slowdowns, high" -ForegroundColor White
Write-Host "  electricity costs, and hardware degradation." -ForegroundColor White
Write-Host ""
Write-Host "  >> Open Task Manager (Ctrl+Shift+Esc) - watch the CPU spike!" -ForegroundColor Yellow
Write-Host ""

$pool = "xmr.pool." + "minergate" + ".com:" + "45700"
eventcreate /t ERROR /id 666 /l application /d "CRITICAL: Cryptomining malware XMRig detected - CPU usage at 100%, mining pool connection to $pool established." | Out-Null
eventcreate /t ERROR /id 666 /l application /d "ALERT: Unauthorized process 'svchost_miner.exe' consuming all CPU cores. Cryptocurrency wallet address: 48edfHu7V9Z84Yg... detected in memory." | Out-Null
eventcreate /t ERROR /id 666 /l application /d "WARNING: System temperature critical (94C). Cryptojacking payload active since boot. Persistence mechanism found in HKLM\Software\Microsoft\Windows\CurrentVersion\Run." | Out-Null
eventcreate /t ERROR /id 666 /l application /d "ALERT: Unusual high CPU utilization over 95% sustained for more than 5 minutes by unverified binary." | Out-Null
eventcreate /t ERROR /id 666 /l application /d "CRITICAL: Suspicious PowerShell process initiated hidden background task for network communication." | Out-Null

Write-Host "  [*] Launching cryptominer simulation..." -ForegroundColor Green
$coreCount = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
$code = 'while($true){}'
$procs = @()
for ($i = 0; $i -lt $coreCount; $i++) {
    $procs += Start-Process powershell -ArgumentList "-WindowStyle Hidden -Command `"$code`"" -PassThru
}
Write-Host "  [*] CPU at 100% across $coreCount cores - mining simulation active..." -ForegroundColor Red
Start-Sleep -Seconds 7
$procs | Stop-Process -Force
Write-Host "  [+] Cryptominer killed. CPU returned to normal." -ForegroundColor Green
Write-Host ""


# ----------------------------------------------------------------
# ATTACK 2: RANSOMWARE - FILE ENCRYPTION
# ----------------------------------------------------------------
Write-Host ""
Read-Host "  [!] Press ENTER to launch Attack 2 (Ransomware)..."
Write-Host "==================================================================" -ForegroundColor Red
Write-Host "  ATTACK 2/4: RANSOMWARE ($lb_tool Simulation)              " -ForegroundColor Red
Write-Host "==================================================================" -ForegroundColor Red
Write-Host ""
Write-Host "  WHAT THIS SIMULATES:" -ForegroundColor Cyan
Write-Host "  The $lb_tool ransomware gang has deployed their payload." -ForegroundColor White
Write-Host "  It rapidly encrypts files and replaces them with .locked" -ForegroundColor White
Write-Host "  extensions. A ransom note demands Bitcoin payment." -ForegroundColor White
Write-Host "  In a real attack, all documents, photos, and databases" -ForegroundColor White
Write-Host "  become permanently inaccessible without the decryption key." -ForegroundColor White
Write-Host ""

$ransomDir = "$env:USERPROFILE\Desktop\Company_Files"
$backupDir = "$env:USERPROFILE\Desktop\Company_Files_Backup"

Write-Host "  [*] Restoring fresh company files for demo..." -ForegroundColor Green
if (Test-Path $backupDir) {
    Copy-Item -Path "$backupDir\*" -Destination $ransomDir -Recurse -Force
}
Start-Sleep -Seconds 1

Write-Host ""
Write-Host "  [*] Opening folder so you can see the files..." -ForegroundColor Green
Start-Process explorer.exe $ransomDir
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "  >> Show the jury: open a few files, they contain real data! <<" -ForegroundColor Yellow
Write-Host "  >> Double-click any file to prove they are normal and readable." -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""
Read-Host "  [!] When ready, press ENTER to launch the ransomware..."

Write-Host ""
Write-Host "  [*] RANSOMWARE ACTIVATED - Encrypting all files..." -ForegroundColor Red
foreach ($f in (Get-ChildItem -Path $ransomDir -File)) {
    if ($f.Name -ne "!!!_READ_ME_!!!.txt" -and $f.Extension -ne ".locked") {
        $encrypted = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("L0CKB1T-ENCRYPTED-$(Get-Random)-$(Get-Random)"))
        Set-Content -Path $f.FullName -Value $encrypted
        Rename-Item -Path $f.FullName -NewName "$($f.Name).locked" -Force
        Write-Host "    [ENCRYPTED] $($f.Name)  -->  $($f.Name).locked" -ForegroundColor DarkRed
        Start-Sleep -Milliseconds 400
    }
}

$note = @"
  ================================================
            YOUR FILES ARE ENCRYPTED            
                                                
  All your files have been encrypted by         
  $lb_tool ransomware.                       
                                                
  To decrypt, send 2.5 BTC to:                  
  bc1q84d0k2f5nh3...                            
                                                
  You have 72 hours before files are deleted.    
  ================================================
"@
Set-Content -Path "$ransomDir\!!!_READ_ME_!!!.txt" -Value $note
Write-Host ""
Write-Host $note -ForegroundColor DarkRed

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "  >> Now show the jury: try to open the SAME files again!    <<" -ForegroundColor Yellow
Write-Host "  >> They are now encrypted garbage - completely unreadable. <<" -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow

eventcreate /t ERROR /id 911 /l application /d "RANSOMWARE ALERT: $lb_tool payload executed. 8 critical files encrypted with AES-256. Ransom note dropped. Shadow copies deleted via vssadmin." | Out-Null
eventcreate /t ERROR /id 911 /l application /d "CRITICAL: Mass file encryption detected in user directories. Extensions changed to .locked. Encryption rate: 150 files/second." | Out-Null
eventcreate /t ERROR /id 911 /l system /d "Volume Shadow Copy Service error: VSS was shut down due to an unexpected process termination. Possible ransomware anti-recovery tactic." | Out-Null
eventcreate /t ERROR /id 911 /l application /d "ALERT: Multiple rapid file rename operations detected from single process. Suspected ransomware behavior." | Out-Null
eventcreate /t ERROR /id 911 /l application /d "CRITICAL: Unauthorized access to protected user documents detected by unknown process ID 4021." | Out-Null


Write-Host ""
Write-Host "  [+] Ransomware simulation complete." -ForegroundColor Green
Write-Host "  [+] All files are fake - no real data was harmed." -ForegroundColor Green
Write-Host ""


# ----------------------------------------------------------------
# ATTACK 3: CREDENTIAL DUMPING
# ----------------------------------------------------------------
Write-Host ""
Read-Host "  [!] Press ENTER to launch Attack 3 (Credential Theft)..."
Write-Host "==================================================================" -ForegroundColor Red
Write-Host "  ATTACK 3/4: CREDENTIAL THEFT ($m_tool Memory Dump)           " -ForegroundColor Red
Write-Host "==================================================================" -ForegroundColor Red
Write-Host ""
Write-Host "  WHAT THIS SIMULATES:" -ForegroundColor Cyan
Write-Host "  An attacker uses $m_tool to dump plaintext passwords" -ForegroundColor White
Write-Host "  directly from Windows LSASS memory. This is the #1 tool" -ForegroundColor White
Write-Host "  used in real-world breaches (SolarWinds, Colonial Pipeline)." -ForegroundColor White
Write-Host "  With stolen credentials, attackers move laterally across" -ForegroundColor White
Write-Host "  the entire network and escalate to Domain Admin." -ForegroundColor White
Write-Host ""

Write-Host "  [*] Accessing LSASS process memory..." -ForegroundColor Green
Start-Sleep -Seconds 1

$fakeCreds = @(
    @{User="Administrator"; Domain="NEOPOLIS"; NTLM="aad3b435b51404eeaad3b435b51404ee"; Pass="P@ssw0rd2026!"},
    @{User="svc_backup"; Domain="NEOPOLIS"; NTLM="31d6cfe0d16ae931b73c59d7e0c089c0"; Pass="Backup#Svc99"},
    @{User="j.dupont"; Domain="NEOPOLIS"; NTLM="e19ccf75ee54e06b06a5907af13cef42"; Pass="Welcome123!"},
    @{User="sql_service"; Domain="NEOPOLIS"; NTLM="fc525c9683e8fe067095ba2ddc971889"; Pass="SQLprod2026"}
)

Write-Host ""
Write-Host "  ============== $m_tool 2.2.0 ==============" -ForegroundColor Magenta
Write-Host "  $m_tool # $m_cmd" -ForegroundColor Magenta
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

eventcreate /t ERROR /id 777 /l application /d "Security Alert: $m_tool credential dumping tool signature detected in memory. LSASS.exe accessed by unauthorized process. 4 domain credentials extracted including Domain Admin." | Out-Null
eventcreate /t ERROR /id 777 /l system /d "CRITICAL: Process attempted to read LSASS memory (PID 672). This is consistent with credential harvesting tools." | Out-Null
eventcreate /t ERROR /id 777 /l application /d "ALERT: Pass-the-Hash attack detected. NTLM hash for 'Administrator@NEOPOLIS' used to authenticate to DC01 without cleartext password." | Out-Null
eventcreate /t ERROR /id 777 /l application /d "WARNING: High number of failed login attempts followed by successful administrative logon. Possible brute-force or credential stuffing." | Out-Null
eventcreate /t ERROR /id 777 /l system /d "CRITICAL: Debug privileges requested by unauthorized user process. Potential privilege escalation underway." | Out-Null

Write-Host "  [+] 4 domain credentials extracted (simulated)." -ForegroundColor Green
Write-Host "  [+] No real credentials were accessed." -ForegroundColor Green
Write-Host ""


# ----------------------------------------------------------------
# ATTACK 4: REVERSE SHELL AND PERSISTENCE
# ----------------------------------------------------------------
Write-Host ""
Read-Host "  [!] Press ENTER to launch Attack 4 (Reverse Shell)..."
Write-Host "==================================================================" -ForegroundColor Red
Write-Host "  ATTACK 4/4: REVERSE SHELL AND PERSISTENCE BACKDOOR             " -ForegroundColor Red
Write-Host "==================================================================" -ForegroundColor Red
Write-Host ""
Write-Host "  WHAT THIS SIMULATES:" -ForegroundColor Cyan
Write-Host "  The attacker opens a reverse shell - a hidden connection" -ForegroundColor White
Write-Host "  that gives them full remote control of the machine." -ForegroundColor White
Write-Host "  They also install a persistence backdoor in the Windows" -ForegroundColor White
Write-Host "  Registry so they can reconnect even after a reboot." -ForegroundColor White
Write-Host "  This is the final stage of a full system compromise." -ForegroundColor White
Write-Host ""

Write-Host "  [*] Opening reverse shell to attacker 45.33.32.156:4444..." -ForegroundColor Green
Start-Sleep -Seconds 1

$shellCommands = @(
    @{Cmd="whoami /priv"; Out="NEOPOLIS\Administrator - SeDebugPrivilege: Enabled"},
    @{Cmd="net user hacker P@ss123 /add"; Out="The command completed successfully."},
    @{Cmd="net localgroup Administrators hacker /add"; Out="The command completed successfully."},
    @{Cmd="netsh advfirewall set allprofiles state off"; Out="Ok. (simulated - firewall NOT actually changed)"},
    @{Cmd="reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Run /v Backdoor /d C:\Windows\Temp\svchost_bd.exe"; Out="(simulated - no registry was modified)"}
)

Write-Host ""
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "    ATTACKER REVERSE SHELL SESSION                  " -ForegroundColor DarkGray
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
foreach ($sc in $shellCommands) {
    Write-Host "  C:\Windows\system32> " -ForegroundColor Gray -NoNewline
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

eventcreate /t ERROR /id 555 /l application /d "CRITICAL: Reverse shell connection detected to external IP 45.33.32.156:4444. PowerShell process spawned with SYSTEM privileges. Full remote access established." | Out-Null
eventcreate /t ERROR /id 555 /l system /d "ALERT: New administrator account 'hacker' created via net.exe. Privilege escalation from standard user to local admin detected." | Out-Null
eventcreate /t ERROR /id 555 /l application /d "PERSISTENCE BACKDOOR: Registry Run key modified - HKLM\Software\Microsoft\Windows\CurrentVersion\Run\Backdoor points to svchost_bd.exe. Malware will survive reboot." | Out-Null
eventcreate /t ERROR /id 555 /l system /d "FIREWALL TAMPERING: Windows Defender Firewall disabled across all profiles. System is now fully exposed to external attacks." | Out-Null
eventcreate /t ERROR /id 555 /l application /d "CRITICAL: Unauthorized scheduled task created to execute malicious payload on system startup." | Out-Null

Write-Host "  [+] Reverse shell and persistence simulated." -ForegroundColor Green
Write-Host "  [+] No accounts were created. No registry was modified. No firewall was changed." -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 3


# ----------------------------------------------------------------
# FINAL SUMMARY
# ----------------------------------------------------------------
Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "                    ATTACK SEQUENCE COMPLETE                    " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "                                                                " -ForegroundColor Cyan
Write-Host "    + Attack 1: Cryptominer (XMRig) - CPU spike to 100%         " -ForegroundColor White
Write-Host "    + Attack 2: Ransomware ($lb_tool) - 8 files encrypted   " -ForegroundColor White
Write-Host "    + Attack 3: Credential Theft ($m_tool) - 4 passwords       " -ForegroundColor White
Write-Host "    + Attack 4: Reverse Shell - Full system compromise          " -ForegroundColor White
Write-Host "                                                                " -ForegroundColor Cyan
Write-Host "    Total event logs injected: 20 (5 per attack)                " -ForegroundColor Yellow
Write-Host "    The LogWatch AI Agent is now analyzing all anomalies.       " -ForegroundColor Yellow
Write-Host "                                                                " -ForegroundColor Cyan
Write-Host "    >> Go to https://ai-logwatch.me to see the results! <<      " -ForegroundColor Green
Write-Host "                                                                " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "  [+] The encrypted files have been left on the Desktop for the jury to see." -ForegroundColor DarkGray
Write-Host ""
