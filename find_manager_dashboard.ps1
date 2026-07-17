$mainFile = "C:\MotionHR\motionhr_employee\motionhr_employee\lib\main.dart"

Write-Host ""
Write-Host "Searching in main.dart..." -ForegroundColor Cyan
Write-Host ""

$content = Get-Content $mainFile -Raw

if ($content -match "ManagerDashboard") {
    Write-Host "FOUND: ManagerDashboard exists in main.dart" -ForegroundColor Green
} else {
    Write-Host "NOT FOUND: ManagerDashboard is not in main.dart" -ForegroundColor Red
}

if ($content -match "ManagerHome") {
    Write-Host "FOUND: ManagerHome exists in main.dart" -ForegroundColor Green
}

if ($content -match "ManagerShell") {
    Write-Host "FOUND: ManagerShell exists in main.dart" -ForegroundColor Green
}

Write-Host ""
Write-Host "File size: $((Get-Item $mainFile).Length / 1024) KB" -ForegroundColor Yellow