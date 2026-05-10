#!/bin/bash
# Genereer debug keystore voor CI builds

cd /tmp/nieuwsapp-temp/android/app

# Genereer debug keystore
keytool -genkey -v \
  -keystore debug.keystore \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias androiddebugkey \
  -storepass android \
  -keypass android \
  -dname "CN=Android Debug,O=Android,C=US"

echo "Debug keystore aangemaakt!"
ls -la debug.keystore