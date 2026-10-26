$ErrorActionPreference = "Stop"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter belum ditemukan. Instal Flutter dan tambahkan flutter\bin ke PATH, lalu buka PowerShell baru."
    exit 1
}

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackupDir = Join-Path ([System.IO.Path]::GetTempPath()) ("pelajarku_" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $BackupDir | Out-Null

try {
    Copy-Item (Join-Path $RootDir "pubspec.yaml") $BackupDir
    Copy-Item (Join-Path $RootDir "analysis_options.yaml") $BackupDir
    Copy-Item (Join-Path $RootDir "lib") $BackupDir -Recurse
    if (Test-Path (Join-Path $RootDir "test")) {
        Copy-Item (Join-Path $RootDir "test") $BackupDir -Recurse
    }

    Push-Location $RootDir

    flutter create --platforms=android,ios --org=id.pelajarku --project-name=pelajarku .
    if ($LASTEXITCODE -ne 0) { throw "flutter create gagal." }

    Remove-Item (Join-Path $RootDir "lib") -Recurse -Force
    if (Test-Path (Join-Path $RootDir "test")) {
        Remove-Item (Join-Path $RootDir "test") -Recurse -Force
    }

    Copy-Item (Join-Path $BackupDir "pubspec.yaml") (Join-Path $RootDir "pubspec.yaml") -Force
    Copy-Item (Join-Path $BackupDir "analysis_options.yaml") (Join-Path $RootDir "analysis_options.yaml") -Force
    Copy-Item (Join-Path $BackupDir "lib") $RootDir -Recurse
    if (Test-Path (Join-Path $BackupDir "test")) {
        Copy-Item (Join-Path $BackupDir "test") $RootDir -Recurse
    }

    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get gagal." }

    Write-Host ""
    Write-Host "Kerangka Android dan iOS berhasil dibuat." -ForegroundColor Green
    Write-Host "Berikutnya jalankan:"
    Write-Host "  flutter analyze"
    Write-Host "  flutter test"
    Write-Host "  flutter run"
}
finally {
    Pop-Location -ErrorAction SilentlyContinue
    Remove-Item $BackupDir -Recurse -Force -ErrorAction SilentlyContinue
}
