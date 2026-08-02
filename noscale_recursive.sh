find . -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.flv" -o -iname "*.webm" \) -print0 | while IFS= read -r -d '' f; do
    dir=$(dirname "$f")
    filename=$(basename "$f")
    ffmpeg -hide_banner \
        -nostdin -y \
        -threads 0 \
        -i "$f" \
        -c:v h264_nvenc \
        -pix_fmt yuv420p \
        -preset p7 \
        -cq 35 \
        -c:a copy "$dir/half_$filename"
done
