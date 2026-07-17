$ErrorActionPreference = "Stop"

$mainFile = "C:\MotionHR\motionhr_employee\motionhr_employee\lib\main.dart"

if (-not (Test-Path $mainFile)) {
    Write-Host "ERROR: main.dart not found" -ForegroundColor Red
    exit 1
}

# Backup
Copy-Item $mainFile "$mainFile.bak_before_reports_button" -Force
Write-Host "Backup created" -ForegroundColor Yellow

$content = Get-Content $mainFile -Raw

# 1) اضافة import للتقارير في اول الملف
$importLine = "import 'screens/manager/reports/reports_hub_screen.dart';"

if ($content -notmatch [regex]::Escape($importLine)) {
    $content = $content -replace "import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';`r`n$importLine"
    Write-Host "Import added" -ForegroundColor Green
} else {
    Write-Host "Import already exists" -ForegroundColor Cyan
}

# 2) اضافة الكارت الجديد قبل السطر الاخير في الكروت
$oldBlock = @"
      _card('نطاق موقع الشركة', 'إعدادات', Icons.fence, Colors.teal,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerGeofenceScreen())))]));
"@

$newBlock = @"
      _card('نطاق موقع الشركة', 'إعدادات', Icons.fence, Colors.teal,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerGeofenceScreen()))),
      const SizedBox(height: 12),
      _card('التقارير', 'عرض', Icons.analytics, Colors.indigo,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsHubScreen())))]));
"@

if ($content -match [regex]::Escape($oldBlock)) {
    $content = $content -replace [regex]::Escape($oldBlock), $newBlock
    Write-Host "Reports card added successfully" -ForegroundColor Green
} else {
    Write-Host "WARNING: Could not find the exact block. Trying manual approach..." -ForegroundColor Yellow
}

# حفظ الملف
Set-Content -Path $mainFile -Value $content -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Done! Now run: flutter run" -ForegroundColor Cyan