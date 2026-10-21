#!/usr/bin/env bash
# يجهّز مجلدات أندرويد وiOS ثم يضيف صلاحية الإنترنت ويثبّت الحزم.
set -e

flutter create --org com.example --project-name tajweed_quiz --platforms android,ios .

MANIFEST="android/app/src/main/AndroidManifest.xml"
if ! grep -q 'android.permission.INTERNET' "$MANIFEST"; then
  sed -i 's#<manifest xmlns:android="http://schemas.android.com/apk/res/android">#&\n    <uses-permission android:name="android.permission.INTERNET"/>#' "$MANIFEST"
fi

flutter pub get
echo "تم. شغّل التطبيق بالأمر: flutter run"
