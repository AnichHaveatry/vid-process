for f in *.{mp4,mkv,avi,mov,flv,webm}; do
    [ -e "$f" ] || continue
    ffmpeg -threads 0 \
        -hwaccel mediacodec \
        -i "$f" \
        -c:v h264_mediacodec \
        -b:v 4M \
        -c:a copy "half_$f"
done