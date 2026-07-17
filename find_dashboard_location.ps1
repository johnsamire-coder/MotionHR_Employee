$mainFile = "C:\MotionHR\motionhr_employee\motionhr_employee\lib\main.dart"

$content = Get-Content $mainFile

Write-Host ""
Write-Host "Lines mentioning ManagerDashboard:" -ForegroundColor Cyan
Write-Host ""

for ($i = 0; $i -lt $content.Length; $i++) {
    if ($content[$i] -match "ManagerDashboard") {
        Write-Host "Line $($i + 1): $($content[$i])" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "First 5 imports in main.dart:" -ForegroundColor Cyan
$importCount = 0
for ($i = 0; $i -lt $content.Length -and $importCount -lt 5; $i++) {
    if ($content[$i] -match "^import") {
        Write-Host "Line $($i + 1): $($content[$i])" -ForegroundColor Green
        $importCount++
    }
}