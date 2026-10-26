#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter belum ditemukan. Instal Flutter stable, lalu jalankan kembali skrip ini."
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$(mktemp -d)"
trap 'rm -rf "$BACKUP_DIR"' EXIT

cp "$ROOT_DIR/pubspec.yaml" "$BACKUP_DIR/pubspec.yaml"
cp "$ROOT_DIR/analysis_options.yaml" "$BACKUP_DIR/analysis_options.yaml"
cp -R "$ROOT_DIR/lib" "$BACKUP_DIR/lib"
if [ -d "$ROOT_DIR/test" ]; then cp -R "$ROOT_DIR/test" "$BACKUP_DIR/test"; fi

cd "$ROOT_DIR"
flutter create \
  --platforms=android,ios \
  --org=id.pelajarku \
  --project-name=pelajarku \
  .

rm -rf "$ROOT_DIR/lib" "$ROOT_DIR/test"
cp "$BACKUP_DIR/pubspec.yaml" "$ROOT_DIR/pubspec.yaml"
cp "$BACKUP_DIR/analysis_options.yaml" "$ROOT_DIR/analysis_options.yaml"
cp -R "$BACKUP_DIR/lib" "$ROOT_DIR/lib"
if [ -d "$BACKUP_DIR/test" ]; then cp -R "$BACKUP_DIR/test" "$ROOT_DIR/test"; fi

flutter pub get

echo
printf '%s\n' \
  "Kerangka platform Android dan iOS sudah dibuat." \
  "Lanjutkan konfigurasi pada docs/PANDUAN_MEMBANGUN.md bagian 4." \
  "Kemudian jalankan: flutter analyze && flutter test && flutter run"
