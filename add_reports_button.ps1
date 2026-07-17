$ErrorActionPreference = "Stop"

$mainFile = "C:\MotionHR\motionhr_employee\motionhr_employee\lib\main.dart"

if (-not (Test-Path $mainFile)) {
    Write-Host "ERROR: main.dart not found" -ForegroundColor Red
    exit 1
}

# Backup
Copy-Item $mainFile "$mainFile.bak_before_reports_v2" -Force
Write-Host "Backup created" -ForegroundColor Yellow

$content = Get-Content $mainFile -Raw

# 1) Add import at the top
$importLine = "import 'screens/manager/reports/reports_hub_screen.dart';"

if ($content -notmatch [regex]::Escape($importLine)) {
    $content = $content -replace "(import 'package:flutter/material.dart';)", "`$1`r`n$importLine"
    Write-Host "[1/2] Import added" -ForegroundColor Green
} else {
    Write-Host "[1/2] Import exists" -ForegroundColor Cyan
}

# 2) Add reports card
$oldPattern = "_card\('نطاق موقع الشركة', 'إعدادات', Icons\.fence, Colors\.teal,\s*\(\) => Navigator\.push\(context, MaterialPageRoute\(builder: \(_\) => const ManagerGeofenceScreen\(\)\)\)\)\]\)\);"

$newBlock = @"
_card('نطاق موقع الشركة', 'إعدادات', Icons.fence, Colors.teal,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerGeofenceScreen()))),
      const SizedBox(height: 12),
      _card('التقارير', 'عرض', Icons.analytics, Colors.indigo,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsHubScreen())))]));
"@

if ($content -match $oldPattern) {
    $content = [regex]::Replace($content, $oldPattern, $newBlock)
    Write-Host "[2/2] Reports card added" -ForegroundColor Green
} else {
    Write-Host "[2/2] WARNING: Pattern not found" -ForegroundColor Yellow
    Write-Host "Trying alternative method..." -ForegroundColor Yellow

    $simpleOld = "() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerGeofenceScreen())))]));"
    $simpleNew = @"
() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerGeofenceScreen()))),
      const SizedBox(height: 12),
      _card('التقارير', 'عرض', Icons.analytics, Colors.indigo,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsHubScreen())))]));
"@

    if ($content.Contains($simpleOld)) {
        $content = $content.Replace($simpleOld, $simpleNew)
        Write-Host "[2/2] Reports card added (alternative)" -ForegroundColor Green
    } else {
        Write-Host "[2/2] FAILED - manual edit needed" -ForegroundColor Red
    }
}

Set-Content -Path $mainFile -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "=== Done! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Now run:" -ForegroundColor Yellow
Write-Host "  flutter run" -ForegroundColor White