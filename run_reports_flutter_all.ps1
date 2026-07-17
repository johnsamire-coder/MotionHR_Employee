$ErrorActionPreference = "Stop"

$projectRoot = "C:\MotionHR\motionhr_employee\motionhr_employee"
Set-Location $projectRoot

Write-Host "🚀 Running Reports Flutter batches..." -ForegroundColor Cyan

& "$projectRoot\apply_reports_flutter_batch1.ps1"
& "$projectRoot\apply_reports_flutter_batch2.ps1"
& "$projectRoot\apply_reports_flutter_batch3.ps1"

Write-Host "📦 Running flutter pub get..." -ForegroundColor Yellow
flutter pub get

Write-Host "✅ All reports batches finished successfully" -ForegroundColor Green
Write-Host "▶️ Now run: flutter run" -ForegroundColor Cyan