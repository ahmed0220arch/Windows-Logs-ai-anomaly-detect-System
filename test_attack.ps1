# LogWatch AI - Presentation Demo Script
# This script simulates a realistic cyber attack sequence to demonstrate the AI anomaly detection.
# Run this while the LogWatch Agent is running in another window.

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   LOGWATCH AI - LIVE PRESENTATION DEMO SCRIPT" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will generate a series of critical security events"
Write-Host "to trigger the AI's anomaly detection algorithms."
Write-Host "Make sure your LogWatch Agent is running in another PowerShell window!"
Write-Host ""
Pause

Write-Host "[1/3] Initiating Brute Force RDP Attack..." -ForegroundColor Yellow
1..15 | ForEach-Object { 
    eventcreate /t ERROR /id 999 /l application /d "CRITICAL SECURITY ALERT: Unauthorized remote execution attempt detected on port 3389." | Out-Null
    Start-Sleep -Milliseconds 200
}
Write-Host "  -> 15 Brute Force logs injected." -ForegroundColor Green
Write-Host "  -> The Agent will send these to the cloud in exactly 5 seconds." -ForegroundColor Gray
Write-Host ""
Start-Sleep -Seconds 5


Write-Host "[2/3] Initiating Print Spooler Exploit (PrintNightmare)..." -ForegroundColor Yellow
1..5 | ForEach-Object { 
    eventcreate /t ERROR /id 998 /l system /d "The Print Spooler service terminated unexpectedly. It has done this 1 time(s). The following corrective action will be taken in 60000 milliseconds: Restart the service." | Out-Null
    Start-Sleep -Milliseconds 500
}
Write-Host "  -> 5 Print Spooler exploit logs injected." -ForegroundColor Green
Write-Host "  -> Sending to cloud..." -ForegroundColor Gray
Write-Host ""
Start-Sleep -Seconds 5


Write-Host "[3/3] Initiating SQL Injection Database Attack..." -ForegroundColor Yellow
1..10 | ForEach-Object { 
    eventcreate /t ERROR /id 997 /l application /d "FATAL: Massive SQL Injection pattern detected in incoming HTTP request to backend database." | Out-Null
    Start-Sleep -Milliseconds 300
}
Write-Host "  -> 10 SQL Injection logs injected." -ForegroundColor Green
Write-Host "  -> Sending to cloud..." -ForegroundColor Gray
Write-Host ""
Start-Sleep -Seconds 5

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "ATTACK SEQUENCE COMPLETE!" -ForegroundColor Green
Write-Host "Go check your live Render dashboard!" -ForegroundColor White
Write-Host "========================================================" -ForegroundColor Cyan
