$ErrorActionPreference = 'Stop'
$project = 'C:\MotionHR\motionhr_employee'
Set-Location $project

Write-Host '=== Batch 0: Android Fix ===' -ForegroundColor Cyan

# Fix android/app/build.gradle
$buildGradle = Join-Path $project 'android\app\build.gradle'

$newContent = @'
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.motionhr_employee"
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.motionhr_employee"
        minSdk = 21
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
}
'@

Set-Content -Path $buildGradle -Value $newContent -Encoding UTF8
Write-Host 'android/app/build.gradle fixed' -ForegroundColor Green

# Check pubspec.yaml has file_picker
$pubspec = Join-Path $project 'pubspec.yaml'
$pubContent = Get-Content $pubspec -Raw

if ($pubContent -notmatch 'file_picker') {
    $pubContent = $pubContent -replace '(  http:)', "  file_picker: ^8.1.2`n`$1"
    Set-Content -Path $pubspec -Value $pubContent -Encoding UTF8
    Write-Host 'file_picker added to pubspec.yaml' -ForegroundColor Green
} else {
    Write-Host 'file_picker already in pubspec.yaml' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Now run:' -ForegroundColor Cyan
Write-Host '  flutter clean' -ForegroundColor White
Write-Host '  flutter pub get' -ForegroundColor White
Write-Host '  flutter run' -ForegroundColor White
Write-Host ''
Write-Host '=== Batch 0 Done ===' -ForegroundColor Cyan