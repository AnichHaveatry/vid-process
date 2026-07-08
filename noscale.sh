for f in *.{mp4,mkv,avi,mov,flv,webm}; do
    [ -e "$f" ] || continue
    ffmpeg -hide_banner \
        -threads 0 \
        -hwaccel cuda \
        -hwaccel_output_format cuda \
        -i "$f" \
        -c:v h264_nvenc \
        -b:v 3M \
        -c:a copy "half_$f"
done