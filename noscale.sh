for f in *.{mp4,mkv,avi,mov,flv,webm}; do
    [ -e "$f" ] || continue
    ffmpeg -hide_banner \
        -threads 0 \
        -i "$f" \
        -c:v h264_nvenc \
        -pix_fmt yuv420p \
        -preset p7 \
        -cq 35 \
        -c:a copy "half_$f"
done