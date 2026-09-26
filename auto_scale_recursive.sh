#!/usr/bin/env bash
#
# auto_scale_recursive.sh
#
# 基于 half-recursive.sh 改写：不再"无论分辨率一律减半"，而是按需等比缩小。
#
# 规则：
#   1. 用 ffprobe 读取分辨率 W x H，计算"等效分辨率" sqrt(W*H)。
#      （1920x1080 的 sqrt(W*H) 正好 = 1440）
#   2. 若 W*H <= 1920*1080（即 sqrt(W*H) <= 1440，例如 1080p 及以下），
#      不缩放（不加 -vf），但**仍然照常重新压缩**。
#   3. 若超过，则在一批"简单的整数比" p/q（p<q，分母 q <= MAX_Q）里挑一个。
#      候选比例必须同时满足（缺一不可）：
#         a) W*p/q 与 H*p/q 都能整除 —— **不做任何取整**，输出尺寸一定是整数；
#         b) 结果宽高都是偶数（yuv420p / H.264 的硬性要求，否则编码直接报错）；
#         c) 缩放后的等效分辨率 sqrt((W*p/q)*(H*p/q)) 不超过 1440；
#         d) 在这些候选里，缩放后尽量接近 1440，且系数尽量简单。
#      评分 = 面积相对误差(千分比) * 1000 + COMPLEXITY_PENALTY * q，取评分最小者。
#      若连"不缩放"评分都更低（例如只超一点点、没有合适的简单比例），
#      则同样不缩放（不加 -vf），照常重新压缩。这类视频缩放后等效分辨率
#      仍会大于 1440，就是"本来就接近 1440、豁免缩放"的那种。
#   4. 所有视频都用与 half-recursive.sh 完全相同的参数重新编码
#      （h264_nvenc / yuv420p / p7 / cq 35 / 音频 copy），
#      区别只在于"要不要多加一个 -vf scale 滤镜"。
#
# 用法：
#   ./auto_scale_recursive.sh               # 处理当前目录（递归所有子目录）
#   ./auto_scale_recursive.sh /path/to/dir  # 处理指定目录
#
# 依赖：ffmpeg / ffprobe / awk
#

set -u

WORK_DIR="${1:-.}"

# -------------------------------- 可调参数 --------------------------------
TARGET_GM=1440           # 目标"等效分辨率" sqrt(宽*高)；1440 对应 1920x1080
MAX_Q=8                  # 缩放系数 p/q 的最大分母：越大越精确，但比例越"复杂"
COMPLEXITY_PENALTY=10    # 复杂度惩罚：分母每 +1，相当于抵扣多少"千分比"的误差
                         #   调大 => 更偏好简单比例（1/2、2/3、3/4…）
                         #   调小 => 更偏好缩放后分辨率接近 1440
                         #   设为 0 => 只看分辨率最接近，比例可能变得很复杂
OUTPUT_PREFIX="half_"    # 输出文件名前缀（沿用你其他脚本的命名习惯，可改成 scaled_ 等）

NVENC_PRESET="p7"
NVENC_CQ=35
# -------------------------------------------------------------------------

TARGET_AREA=$(( TARGET_GM * TARGET_GM ))   # 1440^2 = 2073600 = 1920*1080

# 读取第一个视频流的宽高；成功输出 "W H"，失败（无视频流 / 读取不到）无输出
get_wh() {
    ffprobe -v error -select_streams v:0 \
            -show_entries stream=width,height \
            -of default=nokey=1:noprint_wrappers=1 "$1" 2>/dev/null |
    awk 'NR == 1 { w = $1; next }
         NR == 2 { h = $1
                   if (w ~ /^[0-9]+$/ && h ~ /^[0-9]+$/ && w > 0 && h > 0) print w, h
                   exit }'
}

# 选出缩放系数 p/q：输出 "<p> <q>"（p < q）；不需要缩放时无输出
choose_scale() {
    awk -v w="$1" -v h="$2" -v T="$TARGET_AREA" -v maxq="$MAX_Q" -v pen="$COMPLEXITY_PENALTY" '
    BEGIN {
        P = w * h
        if (P <= T) exit 0                      # 不比 1920x1080 大，不处理

        best_p = 1; best_q = 1                  # 候选 0：不缩放（只超一点点时的豁免）
        best_score = (P - T) / T * 1000         # 不缩放时面积的相对误差（千分比）

        for (q = 2; q <= maxq; q++) {           # 枚举所有 p/q < 1 的简单整数比
            for (p = 1; p < q; p++) {
                if ((p * w) % q != 0) continue          # 宽必须整除，不允许取整
                if ((p * h) % q != 0) continue          # 高必须整除，不允许取整
                nw = p * w / q
                nh = p * h / q
                if (nw % 2 != 0 || nh % 2 != 0) continue # yuv420p 要求宽高都为偶数
                if (p * p * P > q * q * T) continue     # 缩放后等效分辨率必须 <= 1440
                                                        # （把 > 改成 >= 就是严格小于 1440）
                err = (q * q * T - p * p * P) / (q * q * T)
                score = err * 1000 + pen * q
                if (score < best_score) {
                    best_score = score
                    best_p = p
                    best_q = q
                }
            }
        }

        if (best_q > 1) print best_p, best_q    # 只有确实要缩小才输出
    }'
}

# 等效分辨率 sqrt(a*b)，保留整数
gm() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.0f", sqrt(a * b) }'; }

echo "工作目录           : $WORK_DIR"
echo "目标等效分辨率     : sqrt(宽*高) ≈ $TARGET_GM  (像素数 > $TARGET_AREA 才缩放)"
echo "整数比分母上限     : $MAX_Q    复杂度惩罚 = $COMPLEXITY_PENALTY"
echo

find "$WORK_DIR" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" \
    -o -iname "*.mov" -o -iname "*.flv" -o -iname "*.webm" \) -print0 |
while IFS= read -r -d '' f; do
    dir=$(dirname "$f")
    filename=$(basename "$f")
    out="$dir/${OUTPUT_PREFIX}${filename}"

    read -r w h < <(get_wh "$f")

    # 判断：是否需要缩放。只有"等效分辨率 > 1440"且"能找到合适的简单整数比"时才加 -vf，
    # 其余情况一律不加缩放滤镜，但仍然照常用完全相同的参数重新压缩。
    vf=()
    desc="不缩放"
    if [[ -n ${w:-} && -n ${h:-} ]] && (( w * h > TARGET_AREA )); then
        read -r p q < <(choose_scale "$w" "$h")
        if [[ -n ${p:-} && -n ${q:-} ]]; then
            # 上面的比例已经保证整除且结果为偶数，这里直接算，不做任何取整
            nw=$(( w * p / q ))
            nh=$(( h * p / q ))
            vf=(-vf "scale=iw*${p}/${q}:ih*${p}/${q}")
            desc="缩放 ${w}x${h} → ${nw}x${nh} (系数 ${p}/${q}, 等效 $(gm "$w" "$h") → $(gm "$nw" "$nh"))"
        else
            desc="不缩放 [${w}x${h}, 等效 $(gm "$w" "$h")，没有合适的简单整数比]"
        fi
    else
        desc="不缩放 [${w}x${h}, 等效 $(gm "$w" "$h") <= $TARGET_GM]"
    fi

    echo "压缩      ${desc}  $f"

    ffmpeg -hide_banner \
        -nostdin -y \
        -threads 0 \
        -i "$f" \
        ${vf[@]+"${vf[@]}"} \
        -c:v h264_nvenc \
        -pix_fmt yuv420p \
        -preset "$NVENC_PRESET" \
        -cq "$NVENC_CQ" \
        -c:a copy "$out" || echo "  ！ffmpeg 处理失败: $f"
done
