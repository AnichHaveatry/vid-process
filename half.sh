for f in *.{mp4,mkv,avi,mov,flv,webm}; do
    [ -e "$f" ] || continue
    ffmpeg -hide_banner \
        -threads 0 \
        -i "$f" \
        -vf "scale=trunc(iw/2/2)*2:trunc(ih/2/2)*2" \
        -c:v h264_nvenc \
        -pix_fmt yuv420p \
        -preset p7 \
        -cq 35 \
        -c:a copy "half_$f"
done

# -threads 0
# CPU线程数
# 0 自动选择（默认值）；1 单线程；8 使用8线程

# -c:v h264_nvenc
# 选择视频编码器
# libx264：CPU H264；h264_nvenc：NVIDIA GPU H264；
# hevc_nvenc：NVIDIA GPU H265；libx265：CPU H265；
# av1_nvenc：NVIDIA GPU AV1
# 因为遇到 NVIDIA 硬件解码器（NVDEC）出错，所以不用硬解码，而是使用 CPU 解码，用 NVENC 编码

# -pix_fmt yuv420p
# 指定像素格式
# yuv420p 8-bit SDR，兼容性最好;
# yuv420p10le 10-bit;
# p010le 10-bit HDR常用
# 因为转换遇到问题，加上此参数，将10-bit输入转换为8-bit，避免H264 NVENC失败。

# -preset p7
# NVENC编码预设
# p1 速度最快压缩效率最低，p7 画质最高，最大压缩效率，但编码速度最低，默认一般为 p4。

# -cq 35
# NVENC编码质量控制参数
# 范围 0-51，数值越小质量越高，文件越大，数值越大质量越低，文件越小。
