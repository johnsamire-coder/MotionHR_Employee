$mainFile = "C:\MotionHR\motionhr_employee\motionhr_employee\lib\main.dart"

$content = Get-Content $mainFile

Write-Host ""
Write-Host "===== Lines 2886 -> 3050 =====" -ForegroundColor Cyan
Write-Host ""

for ($i = 2885; $i -lt 3050 -and $i -lt $content.Length; $i++) {
    $lineNum = $i + 1
    Write-Host "$lineNum : $($content[$i])"
}