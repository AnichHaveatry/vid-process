for f in *.{mp4,mkv,avi,mov,flv,webm}; do
[ -e "$f" ] || continue
ffmpeg -i "$f" -vf "scale=trunc(iw/2/2)*2:trunc(ih/2/2)*2" -c:v libx264 -crf 28 -preset veryslow -c:a copy "half_$f"
done

# 画质控制
# -crf 23
# CRF 数值：
# 18 = 高质量大文件
# 23 = 默认平衡
# 28 = 小文件低画质

# 编码速度
# -preset medium
# 速度/压缩率平衡：
# ultrafast（最快）
# fast
# medium（默认）
# slow
# veryslow（最省空间）