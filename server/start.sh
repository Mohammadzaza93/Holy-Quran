#!/usr/bin/env bash
# المحرّك داخلياً على 8000، والواجهة العامة على $PORT (7860 في Hugging Face).
quran-muaalem-engine &
sleep 5
exec quran-muaalem-app
