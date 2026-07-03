for f in *.{mp4,mkv,avi,mov,flv,webm}; do
[ -e "$f" ] || continue
ffmpeg -i "$f" -c:v libx264 -crf 28 -preset veryslow -c:a copy "half_$f"
done
