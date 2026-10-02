#!/usr/bin/env bash
# Cloud Agent `install`: toolchain (if missing) + pub get + codegen.
# Must terminate. Do not run tests or long-lived servers here.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -x "$ROOT/scripts/bootstrap-flutter-android.sh" ]]; then
  # shellcheck disable=SC1091
  bash "$ROOT/scripts/bootstrap-flutter-android.sh"
fi

flutter pub get
dart run build_runner build
