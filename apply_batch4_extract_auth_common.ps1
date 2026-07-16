$ErrorActionPreference = 'Stop'
$project = 'C:\MotionHR\motionhr_employee'
Set-Location $project

Write-Host '=== Batch 4: Extract Auth + Common Screens ===' -ForegroundColor Cyan

Write-Host 'Batch 4 creates placeholder files.' -ForegroundColor Yellow
Write-Host 'Full extraction happens after flutter run confirms Batch 3 works.' -ForegroundColor Yellow

function Write-Utf8File {
    param([string]$RelativePath, [string]$Content)
    $fullPath = Join-Path $project $RelativePath
    New-Item -ItemType Directory -Force -Path (Split-Path $fullPath -Parent) | Out-Null
    Set-Content -Path $fullPath -Value $Content -Encoding UTF8
    Write-Host "Created: $RelativePath" -ForegroundColor Green
}

# Create folder structure
$folders = @(
    'lib\screens\auth',
    'lib\screens\common',
    'lib\screens\employee',
    'lib\screens\manager'
)

foreach ($f in $folders) {
    New-Item -ItemType Directory -Force -Path (Join-Path $project $f) | Out-Null
    Write-Host "Created folder: $f" -ForegroundColor DarkGray
}

Write-Utf8File 'lib\screens\auth\.gitkeep' ''
Write-Utf8File 'lib\screens\common\.gitkeep' ''
Write-Utf8File 'lib\screens\employee\.gitkeep' ''
Write-Utf8File 'lib\screens\manager\.gitkeep' ''

Write-Host ''
Write-Host '=== Batch 4 Done ===' -ForegroundColor Cyan
Write-Host 'Folder structure ready for screen extraction.' -ForegroundColor Green
Write-Host 'Run flutter run to confirm Batch 3 works before extracting screens.' -ForegroundColor Yellow