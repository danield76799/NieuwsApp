#!/bin/bash
# Genereer upload keystore voor Play Store

cd /tmp/nieuwsapp-temp/android/app

# Genereer keystore met keytool
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -storepass android \
  -keypass android \
  -dname "CN=PlusNews, OU=Development, O=PlusNews, L=Amsterdam, ST=NH, C=NL"

echo "Keystore aangemaakt!"
ls -la upload-keystore.jks