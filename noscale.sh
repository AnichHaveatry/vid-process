for f in *.{mp4,mkv,avi,mov,flv,webm}; do
[ -e "$f" ] || continue
ffmpeg -hwaccel cuda -i "$f" -c:v libx264 -crf 26 -preset slow -c:a copy "half_$f"
done
