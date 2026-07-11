for f in *.{mp4,mkv,avi,mov,flv,webm}; do
    [ -e "$f" ] || continue
    ffmpeg -hide_banner \
        -threads 0 \
        -i "$f" \
        -vf "scale=trunc(iw/2/2)*2:trunc(ih/2/2)*2" \
        -c:v h264_nvenc \
        -b:v 3M \
        -c:a copy "half_$f"
done

# -b:v 4M
# 设置视频目标码率，单位 Mb/s（兆比特每秒）。

# 如需进一步提升速度，可增加：
# -preset p1
# p1 最快，p7 画质最高但速度最慢，默认一般为 p4。

# -threads 0
# 这项原本没有，0 为默认值，但是有时候出问题设为 1 试试。

# 因为遇到 NVIDIA 硬件解码器（NVDEC）出错，所以不用硬解码，而是使用 CPU 解码，用 NVENC 编码
