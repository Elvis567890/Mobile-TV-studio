#!/bin/bash
set -e

echo "======================================"
echo " Mobile TV Studio — Codespace setup"
echo "======================================"

# ---------- Flutter ----------
if [ ! -d "/opt/flutter" ]; then
  echo "Installing Flutter 3.19.0..."
  sudo git clone --depth 1 --branch 3.19.0 \
    https://github.com/flutter/flutter.git /opt/flutter
  sudo chown -R "$(whoami):$(whoami)" /opt/flutter
fi

export PATH="$PATH:/opt/flutter/bin"

# Add Flutter to PATH permanently
if ! grep -q "/opt/flutter/bin" ~/.bashrc; then
  echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
fi

flutter --version

# ---------- Android SDK ----------
if [ -z "$ANDROID_HOME" ]; then
  echo "Installing Android SDK command-line tools..."
  sudo mkdir -p /opt/android-sdk/cmdline-tools
  cd /tmp
  sudo wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip
  sudo unzip -q cmdline-tools.zip -d /opt/android-sdk/cmdline-tools
  sudo mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest
  sudo chown -R "$(whoami):$(whoami)" /opt/android-sdk

  if ! grep -q "ANDROID_HOME" ~/.bashrc; then
    echo 'export ANDROID_HOME=/opt/android-sdk' >> ~/.bashrc
    echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"' >> ~/.bashrc
  fi

  export ANDROID_HOME=/opt/android-sdk
  export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

  yes | sdkmanager --licenses > /dev/null 2>&1 || true
  sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" > /dev/null
fi

# ---------- Flutter config ----------
flutter config --android-sdk /opt/android-sdk > /dev/null 2>&1 || true
flutter config --no-analytics > /dev/null 2>&1 || true

# ---------- Project deps ----------
if [ -f "pubspec.yaml" ]; then
  echo "Fetching Dart packages..."
  flutter pub get || true
fi

echo ""
echo "======================================"
echo " Setup complete."
echo " Run:  flutter doctor -v"
echo " Run:  flutter run"
echo "======================================"
