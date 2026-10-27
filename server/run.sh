#!/usr/bin/env bash
# تشغيل خادم quran-muaalem (المحرّك + واجهة التصحيح) لاستعماله من التطبيق.
set -euo pipefail
python3 -m venv .venv-muaalem
source .venv-muaalem/bin/activate
pip install --quiet "quran-muaalem[engine]==0.2.2"
trap 'kill 0' EXIT
quran-muaalem-engine &   # المحرّك على المنفذ 8000
sleep 5
quran-muaalem-app        # الواجهة على المنفذ 8001
