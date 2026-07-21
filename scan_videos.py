import os
import csv
import json
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
import math

# 注意，这个代码只能在linux中运行。windows中运行无输出

VIDEO_EXTS = {
    ".mp4", ".mkv", ".avi", ".mov", ".flv",
    ".wmv", ".webm", ".m4v", ".ts", ".3gp"
}

MAX_WORKERS = min(32, (os.cpu_count() or 4) * 2)


def find_videos(root="."):
    stack = [root]
    while stack:
        path = stack.pop()
        try:
            with os.scandir(path) as it:
                for entry in it:
                    if entry.is_dir(follow_symlinks=False):
                        stack.append(entry.path)
                    elif entry.is_file():
                        ext = os.path.splitext(entry.name)[1].lower()
                        if ext in VIDEO_EXTS:
                            yield entry.path
        except Exception:
            pass


def parse_fps(value):
    """
    解析 ffprobe 的 fps 格式:
    30000/1001 -> 29.97
    """
    try:
        num, den = map(int, value.split("/"))
        if den != 0:
            return num / den
    except Exception:
        pass
    return 0

def ffprobe_video(path):
    cmd = [
        "ffprobe",
        "-v", "quiet",
        "-print_format", "json",
        "-show_format",
        "-show_streams",
        path
    ]

    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True
        )

        data = json.loads(result.stdout)

        fmt = data.get("format", {})
        streams = data.get("streams", [])

        duration = float(fmt.get("duration", 0))
        bitrate = int(fmt.get("bit_rate", 0))

        width = 0
        height = 0
        fps = 0
        r_fps = 0

        for s in streams:
            if s.get("codec_type") == "video":
                width = s.get("width", 0)
                height = s.get("height", 0)
                # 真实平均帧率
                fps = parse_fps(s.get("avg_frame_rate", "0/1"))
                # metadata声明帧率
                r_fps = parse_fps(s.get("r_frame_rate", "0/1"))
                break

        size_bytes = os.path.getsize(path)

        # 如果 ffprobe 没返回码率，则自行计算
        if bitrate == 0 and duration > 0:
            bitrate = int((size_bytes * 8) / duration)

        # 分辨率尺度
        pixel_scale = round(math.sqrt(width * height), 2) if width and height else 0

        return {
            "path": path,
            "size_mb": round(size_bytes / 1024 / 1024, 2),
            "duration_sec": round(duration, 2),
            # "bitrate_kbps": round(bitrate / 1000, 2),
            "bitrate_mbps": round(bitrate / 1_000_000, 2),
            "resolution": f"{width}x{height}",
            "resolution_scale": pixel_scale,
            # 平均真实fps
            "fps": round(fps, 2),
            # 文件声明fps
            "r_fps": round(r_fps, 2)
        }

    except Exception:
        return None


def main():
    videos = list(find_videos("."))
    results = []

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = [executor.submit(ffprobe_video, v) for v in videos]

        for future in as_completed(futures):
            r = future.result()
            if r:
                results.append(r)

    # 默认按照码率从高到低排序
    # results.sort(key=lambda x: x["bitrate_kbps"], reverse=True)
    results.sort(key=lambda x: x["bitrate_mbps"], reverse=True)

    with open("video_report.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "path",
                "size_mb",
                "duration_sec",
                # "bitrate_kbps",
                "bitrate_mbps",
                "resolution",
                "resolution_scale",
                "fps",
                "r_fps"
            ]
        )
        writer.writeheader()
        writer.writerows(results)

    print(f"Done. {len(results)} videos scanned.")
    print("Saved to video_report.csv")


if __name__ == "__main__":
    main()
