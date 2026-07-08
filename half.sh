for f in *.{mp4,mkv,avi,mov,flv,webm}; do
    [ -e "$f" ] || continue
    ffmpeg -threads 0 \
        -hwaccel mediacodec \
        -i "$f" \
        -vf "scale=trunc(iw/2/2)*2:trunc(ih/2/2)*2" \
        -c:v h264_mediacodec \
        -b:v 4M \
        -c:a copy "half_$f"
done

# MediaCodec 在 FFmpeg 里有个限制：某些滤镜（包括部分 scale）可能会导致回退到 CPU
# 如果发现速度不明显提升，可以试着删除这一行
# -vf "scale=trunc(iw/2/2)*2:trunc(ih/2/2)*2" \
# 删除这一行的版本在 noscale.sh

# -b:v 4M
# 调视频码率，单位 Mb/s（兆比特每秒）
