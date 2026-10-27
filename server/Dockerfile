# صورة لتشغيل خادم quran-muaalem على Hugging Face Spaces (أو أي استضافة Docker).
FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Hugging Face يشغّل الحاوية بمستخدم غير جذري رقمه 1000
RUN useradd -m -u 1000 user
USER user
ENV PATH="/home/user/.local/bin:$PATH" \
    HF_HOME=/home/user/.cache/huggingface \
    PORT=7860 HOST=0.0.0.0

WORKDIR /home/user/app
RUN pip install --no-cache-dir "quran-muaalem[engine]==0.2.2"
COPY --chown=user start.sh .

EXPOSE 7860
CMD ["bash", "start.sh"]
