for f in *.{mp4,mkv,avi,mov,flv,webm}; do
    [ -e "$f" ] || continue
    fps=$(ffprobe -v 0 -select_streams v:0 \
        -show_entries stream=r_frame_rate \
        -of default=noprint_wrappers=1:nokey=1 "$f")
    # 转换分数形式，例如 120/1 -> 120
    fps_num=$(echo "$fps" | awk -F'/' '{print $1}')
    fps_den=$(echo "$fps" | awk -F'/' '{print $2}')
    # 计算真实帧率
    real_fps=$(awk "BEGIN {print $fps_num/$fps_den}")
    # 判断是否大于60
    need=$(awk "BEGIN {print ($real_fps>60)?1:0}")
    if [ "$need" -eq 1 ]; then
        new_fps=$(awk "BEGIN {print $real_fps/2}")
        echo "$f: ${real_fps}fps -> ${new_fps}fps"
        ffmpeg -hide_banner \
            -threads 0 \
            -hwaccel cuda \
            -hwaccel_output_format cuda \
            -i "$f" \
            -vf "fps=$new_fps" \
            -c:v h264_nvenc \
            -c:a copy "half_$f"
    else
        echo "$f: ${real_fps}fps, skip"
    fi
done