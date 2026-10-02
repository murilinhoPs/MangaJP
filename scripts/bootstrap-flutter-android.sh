#!/usr/bin/env bash
# Idempotent Flutter stable + Android SDK bootstrap for Cloud Agents.
# Cheap no-op when toolchains are already present.
set -euo pipefail

FLUTTER_HOME="${FLUTTER_HOME:-/opt/flutter}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/opt/android-sdk}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export ANDROID_SDK_ROOT
export PATH="/usr/local/bin:${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

sudo_if_needed() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

ensure_path_symlinks() {
  if [[ -x "$FLUTTER_HOME/bin/flutter" ]]; then
    sudo_if_needed ln -sfn "$FLUTTER_HOME/bin/flutter" /usr/local/bin/flutter
    sudo_if_needed ln -sfn "$FLUTTER_HOME/bin/dart" /usr/local/bin/dart
  fi
  if [[ -x "$ANDROID_SDK_ROOT/platform-tools/adb" ]]; then
    sudo_if_needed ln -sfn "$ANDROID_SDK_ROOT/platform-tools/adb" /usr/local/bin/adb
  fi
}

android_sdk_ready() {
  [[ -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]] &&
    [[ -d "$ANDROID_SDK_ROOT/platforms/android-36" ]] &&
    [[ -d "$ANDROID_SDK_ROOT/platforms/android-35" ]] &&
    [[ -d "$ANDROID_SDK_ROOT/build-tools/36.0.0" ]] &&
    [[ -d "$ANDROID_SDK_ROOT/ndk/28.2.13676358" ]] &&
    [[ -d "$ANDROID_SDK_ROOT/cmake/3.22.1" ]]
}

accept_android_licenses() {
  mkdir -p "$ANDROID_SDK_ROOT/licenses"
  printf '24333f8a63b6825ea9c5514f83c2829b004d1fee\n' >"$ANDROID_SDK_ROOT/licenses/android-sdk-license"
  printf '84831b9409646161cecb09b7bd5a6dc3\n' >"$ANDROID_SDK_ROOT/licenses/android-sdk-preview-license"
}

if ! command -v flutter >/dev/null 2>&1 && [[ ! -x "$FLUTTER_HOME/bin/flutter" ]]; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo_if_needed apt-get update -qq
    sudo_if_needed apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip zip xz-utils \
      openjdk-21-jdk-headless libsqlite3-dev
  fi
  sudo_if_needed mkdir -p "$(dirname "$FLUTTER_HOME")"
  sudo_if_needed git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  sudo_if_needed chown -R "$(id -u):$(id -g)" "$FLUTTER_HOME" || true
fi
ensure_path_symlinks

if ! android_sdk_ready; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo_if_needed apt-get update -qq
    sudo_if_needed apt-get install -y --no-install-recommends \
      ca-certificates curl unzip zip openjdk-21-jdk-headless libsqlite3-dev
  fi
  sudo_if_needed mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
  sudo_if_needed chown -R "$(id -u):$(id -g)" "$ANDROID_SDK_ROOT"
  accept_android_licenses
  if [[ ! -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]]; then
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/cmdline-tools.zip" \
      "https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip"
    unzip -q "$tmp/cmdline-tools.zip" -d "$tmp"
    rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    mv "$tmp/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
    rm -rf "$tmp"
  fi
  sdkmanager="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
  yes | "$sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null || true
  "$sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" \
    "platform-tools" \
    "platforms;android-36" \
    "platforms;android-35" \
    "build-tools;36.0.0" \
    "cmake;3.22.1" \
    "ndk;28.2.13676358"
  ensure_path_symlinks
fi

if command -v flutter >/dev/null 2>&1; then
  flutter config --no-analytics >/dev/null || true
  flutter config --android-sdk "$ANDROID_SDK_ROOT" >/dev/null || true
fi

sudo_if_needed tee /etc/profile.d/mangajp-android.sh >/dev/null <<EOF
export ANDROID_HOME=$ANDROID_SDK_ROOT
export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT
export PATH="/usr/local/bin:${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:\${PATH}"
EOF
if [[ -f /etc/environment ]] && ! grep -q '^ANDROID_SDK_ROOT=' /etc/environment; then
  echo "ANDROID_HOME=$ANDROID_SDK_ROOT" | sudo_if_needed tee -a /etc/environment >/dev/null
  echo "ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" | sudo_if_needed tee -a /etc/environment >/dev/null
fi
