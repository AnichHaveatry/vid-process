#!/bin/bash

INPUT="movie.mp4"

# ================================此处有参数修改================================
# 广告开始附近搜索范围
START_SEARCH="00:06:49"
START_END="00:06:51"

# 广告结束附近搜索范围
END_SEARCH="00:07:11"
END_END="00:07:13"
# ================================此处结束参数修改================================


echo "===== 检测广告开始点 ====="

ffmpeg \
-ss $START_SEARCH \
-to $START_END \
-i "$INPUT" \
-vf "select='gt(scene,0.35)',showinfo" \
-f null - 2>&1 \
| grep pts_time > start_detect.txt


echo "===== 检测广告结束点 ====="

ffmpeg \
-ss $END_SEARCH \
-to $END_END \
-i "$INPUT" \
-vf "select='gt(scene,0.35)',showinfo" \
-f null - 2>&1 \
| grep pts_time > end_detect.txt



echo ""
echo "开始检测结果:"
cat start_detect.txt

echo ""
echo "结束检测结果:"
cat end_detect.txt


# 提取第一个检测时间
START_OFFSET=$(grep -o 'pts_time:[0-9.]*' start_detect.txt | head -1 | cut -d: -f2)

END_OFFSET=$(grep -o 'pts_time:[0-9.]*' end_detect.txt | head -1 | cut -d: -f2)


# ================================此处有参数修改================================
# 加上搜索起始时间
START_SEC=$(python3 - <<EOF
print(6*60+49+$START_OFFSET)
EOF
)

END_SEC=$(python3 - <<EOF
print(7*60+11+$END_OFFSET)
EOF
)
# ================================此处结束参数修改================================


echo ""
echo "广告开始:"
echo $START_SEC

echo "广告结束:"
echo $END_SEC



echo ""
echo "===== 开始剪切 ====="


ffmpeg \
-i "$INPUT" \
-t $START_SEC \
-c:v libx264 \
-preset fast \
-crf 23 \
-c:a copy part1.mp4


ffmpeg \
-i "$INPUT" \
-ss $END_SEC \
-c:v libx264 \
-preset fast \
-crf 23 \
-c:a copy part2.mp4



echo "file 'part1.mp4'" > concat.txt
echo "file 'part2.mp4'" >> concat.txt



echo "===== 合并 ====="

ffmpeg \
-f concat \
-safe 0 \
-i concat.txt \
-c copy \
output_no_ad.mp4


echo ""
echo "完成:"
echo output_no_ad.mp4


# 需要找到广告开始或结束的附近时间点，填到代码的参数里。
# 代码通过检测场景变化，精确定位广告开始结束位置。
