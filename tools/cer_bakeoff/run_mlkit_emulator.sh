#!/usr/bin/env bash
# Build/install the ML Kit JA harness, push M0.2 crops, dump predictions JSON.
# Does not call Cloud Vision.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HARNESS="$ROOT/tools/cer_bakeoff/mlkit_harness"
PKG="dev.murilinhops.mlkit_harness"
AVD_NAME="${AVD_NAME:-mangajp_api30}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-/opt/android-sdk}}"
export ANDROID_SDK_ROOT ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:/usr/local/bin:$PATH"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk-amd64}"

GT_DIR="$ROOT/tools/cer_bakeoff/gt"
OUT="$ROOT/tools/cer_bakeoff/results/predictions_mlkit_ja.json"
BOOT_TIMEOUT=360
OCR_TIMEOUT=1800
START_EMU=1

usage() {
  cat <<EOF
Usage: $0 [--gt-dir DIR] [--out FILE] [--no-emulator]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --gt-dir) GT_DIR="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --no-emulator) START_EMU=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

CROPS="$GT_DIR/crops"
MANIFEST="$GT_DIR/manifest-kanji.csv"
if [[ ! -d "$CROPS" || ! -f "$MANIFEST" ]]; then
  echo "GT missing (need manifest-kanji.csv + crops/): $GT_DIR" >&2
  exit 1
fi

ensure_avd() {
  if avdmanager list avd 2>/dev/null | grep -q "Name: $AVD_NAME"; then
    return 0
  fi
  echo "Creating AVD $AVD_NAME (android-30 google_apis x86_64)"
  echo no | avdmanager create avd \
    --name "$AVD_NAME" \
    --package "system-images;android-30;google_apis;x86_64" \
    --device pixel \
    --force >/tmp/avd-create.log
  local cfg="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
  if [[ -f "$cfg" ]]; then
    {
      echo "hw.ramSize=2048"
      echo "hw.gpu.enabled=yes"
      echo "hw.gpu.mode=swiftshader_indirect"
      echo "hw.keyboard=yes"
    } >>"$cfg"
  fi
}

start_emulator() {
  if adb devices | awk 'NR>1 && $2=="device"{found=1} END{exit found?0:1}'; then
    echo "adb device already present"
    return 0
  fi
  ensure_avd
  mkdir -p /tmp/emulator-logs
  echo "Starting emulator $AVD_NAME"
  # Nested KVM on this host can BUG (qemu idle); TCG (-accel off) is the reliable path.
  local accel=( -accel off )
  if emulator -accel-check 2>/dev/null | grep -q 'is operational' \
    && ! dmesg 2>/dev/null | grep -q 'kvm_spurious_fault'; then
    accel=( -accel on )
  fi
  echo "accel flags: ${accel[*]}"
  emulator -avd "$AVD_NAME" \
    -no-window -no-audio -no-boot-anim \
    -gpu swiftshader_indirect \
    "${accel[@]}" \
    -no-snapshot \
    -memory 2048 \
    -cores 2 \
    -camera-back none -camera-front none \
    > /tmp/emulator-logs/emulator.out 2>&1 &
  echo $! > /tmp/emulator-logs/emulator.pid
  echo "emulator pid $(cat /tmp/emulator-logs/emulator.pid)"
}

wait_boot() {
  echo "Waiting for adb device"
  adb wait-for-device
  local i=0
  while true; do
    if adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' | grep -qx 1; then
      echo "boot completed"
      break
    fi
    i=$((i + 5))
    if [[ $i -ge $BOOT_TIMEOUT ]]; then
      echo "emulator boot timed out after ${BOOT_TIMEOUT}s" >&2
      tail -50 /tmp/emulator-logs/emulator.out >&2 || true
      exit 1
    fi
    sleep 5
  done
  adb shell settings put global window_animation_scale 0 || true
  adb shell settings put global transition_animation_scale 0 || true
  adb shell settings put global animator_duration_scale 0 || true
  echo "Waiting for package manager"
  local j=0
  while true; do
    if adb shell service check package 2>/dev/null | grep -q 'found'; then
      echo "package manager ready"
      break
    fi
    j=$((j + 5))
    if [[ $j -ge 180 ]]; then
      echo "package manager not ready" >&2
      exit 1
    fi
    sleep 5
  done
}

build_and_install() {
  echo "Building harness APK"
  (cd "$HARNESS" && flutter pub get && flutter build apk --debug --target-platform android-x64)
  local apk="$HARNESS/build/app/outputs/flutter-apk/app-debug.apk"
  if [[ ! -f "$apk" ]]; then
    apk="$HARNESS/build/app/outputs/flutter-apk/app-x64-debug.apk"
  fi
  adb install -r -d "$apk"
}

push_crops() {
  local dest="/data/user/0/$PKG/files/crops"
  echo "Pushing crops to $dest"
  adb root >/dev/null 2>&1 || true
  adb wait-for-device
  adb shell mkdir -p "$dest"
  adb push "$CROPS/." "$dest/"
  local app_uid
  app_uid="$(adb shell stat -c %u /data/user/0/$PKG 2>/dev/null | tr -d '\r')"
  if [[ "$app_uid" =~ ^[0-9]+$ ]]; then
    adb shell chown -R "${app_uid}:${app_uid}" "$dest"
  else
    adb shell chmod -R a+rX "$dest"
  fi
  local n
  n="$(adb shell "ls '$dest' | wc -l" | tr -d '\r[:space:]')"
  echo "device crop files: $n"
}

run_ocr_and_pull() {
  local remote_dir="/data/user/0/$PKG/files"
  adb shell rm -f "$remote_dir/DONE" "$remote_dir/mlkit_predictions.json" || true
  adb logcat -c || true
  adb shell am force-stop "$PKG" || true
  adb shell am start -n "$PKG/.MainActivity"
  echo "Waiting for OCR dump (${OCR_TIMEOUT}s max)"
  local i=0
  while true; do
    if adb shell "test -f '$remote_dir/DONE' && echo yes" | grep -q yes; then
      echo "DONE file present"
      break
    fi
    i=$((i + 3))
    if [[ $i -ge $OCR_TIMEOUT ]]; then
      echo "OCR timed out" >&2
      adb logcat -d -s MLKIT_CER flutter AndroidRuntime | tail -80 >&2 || true
      exit 1
    fi
    sleep 3
  done
  mkdir -p "$(dirname "$OUT")"
  adb pull "$remote_dir/mlkit_predictions.json" "$OUT"
  adb logcat -d -s MLKIT_CER | tail -60 || true
}

verify_dump() {
  python3 - "$OUT" "$MANIFEST" <<'PY'
import csv, json, sys
from pathlib import Path
dump_path, manifest_path = Path(sys.argv[1]), Path(sys.argv[2])
data = json.loads(dump_path.read_text(encoding="utf-8"))
if data.get("engine_id") != "mlkit_ja":
    raise SystemExit(f"engine_id {data.get('engine_id')!r} != mlkit_ja")
preds = data.get("predictions") or {}
errors = data.get("errors") or {}
with manifest_path.open(encoding="utf-8") as fh:
    ids = [row["crop_id"] for row in csv.DictReader(fh)]
missing = [i for i in ids if i not in preds]
print(f"dump {dump_path}: {len(preds)} predictions, {len(errors)} errors, {len(ids)} GT ids")
if errors:
    print("errors:", errors)
    raise SystemExit("OCR errors present; refusing CER")
if missing:
    print("missing crop_ids:", missing)
    raise SystemExit("not all GT crops recognized; refusing CER")
print("44/44 dump OK" if len(ids) == 44 else f"{len(ids)}/{len(ids)} dump OK")
PY
}

if [[ "$START_EMU" -eq 1 ]]; then
  start_emulator
  wait_boot
fi
build_and_install
push_crops
run_ocr_and_pull
verify_dump
echo "Wrote $OUT"
