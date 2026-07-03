for f in *.{mp4,mkv,avi,mov,flv,webm}; do
[ -e "$f" ] || continue
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i "$f" \
-vf "scale_cuda=trunc(iw/2/2)*2:trunc(ih/2/2)*2" \
-c:v h264_nvenc -b:v 4M \
-c:a copy "half_$f"
done

# CUDA/NVENC 支持 GPU 缩放，使用 scale_cuda 可避免回退到 CPU。
# 如果发现速度仍然不理想，可以删除下面这一行进行对比测试：
# -vf "scale_cuda=trunc(iw/2/2)*2:trunc(ih/2/2)*2" \
# 删除这一行的版本可保存为 noscale.sh。

# -b:v 4M
# 设置视频目标码率，单位 Mb/s（兆比特每秒）。

# 如需进一步提升速度，可增加：
# -preset p1
# p1 最快，p7 画质最高但速度最慢，默认一般为 p4。
