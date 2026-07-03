import os
import csv
import json
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed

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

        for s in streams:
            if s.get("codec_type") == "video":
                width = s.get("width", 0)
                height = s.get("height", 0)
                break

        size_bytes = os.path.getsize(path)

        if bitrate == 0 and duration > 0:
            bitrate = int((size_bytes * 8) / duration)

        return {
            "path": path,
            "size_mb": round(size_bytes / 1024 / 1024, 2),
            "duration_sec": round(duration, 2),
            "bitrate_kbps": round(bitrate / 1000, 2),
            "resolution": f"{width}x{height}"
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

    results.sort(key=lambda x: x["bitrate_kbps"], reverse=True)

    with open("video_bitrate_report.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "path",
                "size_mb",
                "duration_sec",
                "bitrate_kbps",
                "resolution"
            ]
        )
        writer.writeheader()
        writer.writerows(results)

    print(f"Done. {len(results)} videos scanned.")
    print("Saved to video_bitrate_report.csv")


if __name__ == "__main__":
    main()
