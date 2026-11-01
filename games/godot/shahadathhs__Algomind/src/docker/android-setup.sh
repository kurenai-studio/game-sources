#!/usr/bin/env bash
# Prepares Godot's Android export inside the container: creates a debug
# keystore (once) and points Godot's editor settings at the SDK and JDK.
set -euo pipefail

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/usr/local/lib/android/sdk}}"
JDK="${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")}"
KEYSTORE=/root/.android/debug.keystore

[ -d "$SDK" ] || { echo "Android SDK not found at $SDK (set ANDROID_HOME)" >&2; exit 1; }

mkdir -p /root/.android /root/.config/godot
# CI passes a fixed key (base64) so every build is signed the same way and a newer
# APK installs over an older one. Without it, a throwaway key is made below.
if [ -n "${ANDROID_DEBUG_KEYSTORE_BASE64:-}" ] && [ ! -f "$KEYSTORE" ]; then
  # Use the last non-empty line and drop CR and spaces: a secret set from a pipe can carry
  # status text or line endings in front of the key.
  if ! printf '%s\n' "$ANDROID_DEBUG_KEYSTORE_BASE64" | grep -v '^[[:space:]]*$' | tail -n 1 \
      | tr -d '\r ' | base64 -d > "$KEYSTORE" 2>/dev/null \
    || ! keytool -list -keystore "$KEYSTORE" -storepass android >/dev/null 2>&1; then
    rm -f "$KEYSTORE"
    echo "ANDROID_DEBUG_KEYSTORE_BASE64 is not a valid base64 keystore. Re-create it with:" >&2
    echo "  make -s android-key | gh secret set ANDROID_DEBUG_KEYSTORE_BASE64" >&2
    exit 1
  fi
fi
if [ ! -f "$KEYSTORE" ]; then
  keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android \
    -keystore "$KEYSTORE" -storepass android \
    -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
fi

cat > /root/.config/godot/editor_settings-4.tres <<SETTINGS
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "$SDK"
export/android/java_sdk_path = "$JDK"
export/android/debug_keystore = "$KEYSTORE"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
SETTINGS
