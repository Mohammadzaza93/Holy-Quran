#!/usr/bin/env bash
# يجهّز المنصات الناقصة ويضيف أذونات الإنترنت والميكروفون والتعرف الصوتي، ثم يثبّت الحزم.
# آمن للتكرار: لا يعيد إنشاء منصة موجودة ولا يكرر الإضافات.
set -e

for platform in android ios; do
  if [ ! -d "$platform" ]; then
    flutter create --org com.holyquran --project-name tajweed_quiz --platforms "$platform" .
  fi
done

# ───────── أندرويد ─────────
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  python3 - "$MANIFEST" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
head = '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
for perm in ("INTERNET", "RECORD_AUDIO"):
    tag = f'<uses-permission android:name="android.permission.{perm}"/>'
    if tag not in s:
        s = s.replace(head, head + "\n    " + tag, 1)
if "android.speech.RecognitionService" not in s:
    q = '''<queries>
        <intent>
            <action android:name="android.speech.RecognitionService"/>
        </intent>'''
    if "<queries>" in s:
        s = s.replace("<queries>", q, 1)
    else:
        s = s.replace("</manifest>", "    " + q + "\n    </queries>\n</manifest>", 1)
open(p, "w", encoding="utf-8").write(s)
PY
fi

# ───────── iOS ─────────
PLIST="ios/Runner/Info.plist"
if [ -f "$PLIST" ]; then
  python3 - "$PLIST" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
add = {
    "NSMicrophoneUsageDescription": "يستخدم التطبيق الميكروفون للاستماع إلى قراءتك وتصحيحها.",
    "NSSpeechRecognitionUsageDescription": "يستخدم التطبيق التعرف على الكلام لمقارنة قراءتك بنص الآية.",
}
for k, v in add.items():
    if k not in s:
        s = s.replace("</dict>\n</plist>", f"\t<key>{k}</key>\n\t<string>{v}</string>\n</dict>\n</plist>", 1)
open(p, "w", encoding="utf-8").write(s)
PY
fi

flutter pub get
echo "تم. شغّل التطبيق بالأمر: flutter run"
