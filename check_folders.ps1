Write-Host ""
Write-Host "=== Checking C:\MotionHR\motionhr_employee\lib ===" -ForegroundColor Cyan
if (Test-Path "C:\MotionHR\motionhr_employee\lib") {
    Get-ChildItem "C:\MotionHR\motionhr_employee\lib" | Format-Table Name, Length, LastWriteTime
} else {
    Write-Host "NOT FOUND" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Checking C:\MotionHR\motionhr_employee\motionhr_employee\lib ===" -ForegroundColor Cyan
if (Test-Path "C:\MotionHR\motionhr_employee\motionhr_employee\lib") {
    Get-ChildItem "C:\MotionHR\motionhr_employee\motionhr_employee\lib" | Format-Table Name, Length, LastWriteTime
} else {
    Write-Host "NOT FOUND" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Looking for core folder anywhere ===" -ForegroundColor Cyan
Get-ChildItem "C:\MotionHR" -Recurse -Directory -Filter "core" -ErrorAction SilentlyContinue | Select-Object FullName

Write-Host ""
Write-Host "=== Looking for widgets folder ===" -ForegroundColor Cyan
Get-ChildItem "C:\MotionHR" -Recurse -Directory -Filter "widgets" -ErrorAction SilentlyContinue | Select-Object FullName