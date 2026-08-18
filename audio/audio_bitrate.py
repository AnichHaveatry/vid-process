import os
import csv
import json
import subprocess

VIDEO_EXTENSIONS = {
    ".mp4", ".mkv", ".mov", ".avi",
    ".webm", ".flv", ".wmv", ".m4v",
    ".ts", ".mts", ".3gp"
}

CSV_FIELDS = [
    "file_path",
    "file_size_bytes",
    "has_audio",
    "audio_codec",
    "audio_codec_long",
    "audio_profile",
    "sample_rate",
    "channels",
    "channel_layout",
    "bit_rate",
    "sample_fmt",
    "bits_per_sample",
    "audio_duration",
    "format_name",
    "container_duration",
    "file_bit_rate",
    "error"
]


def get_audio_info(filepath):
    cmd = [
        "ffprobe",
        "-v", "error",
        "-print_format", "json",
        "-show_streams",
        "-show_format",
        filepath
    ]

    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        if result.returncode != 0:
            return {
                "error": result.stderr.strip()
            }

        data = json.loads(result.stdout)
        audio = None

        for stream in data.get("streams", []):
            if stream.get("codec_type") == "audio":
                audio = stream
                break

        if audio is None:
            return {
                "has_audio": False
            }

        fmt = data.get("format", {})

        return {
            "has_audio": True,
            "audio_codec":
                audio.get("codec_name"),
            "audio_codec_long":
                audio.get("codec_long_name"),
            "audio_profile":
                audio.get("profile"),
            "sample_rate":
                audio.get("sample_rate"),
            "channels":
                audio.get("channels"),
            "channel_layout":
                audio.get("channel_layout"),
            "bit_rate":
                audio.get("bit_rate"),
            "sample_fmt":
                audio.get("sample_fmt"),
            "bits_per_sample":
                audio.get("bits_per_sample"),
            "audio_duration":
                audio.get("duration"),
            "format_name":
                fmt.get("format_name"),
            "container_duration":
                fmt.get("duration"),
            "file_bit_rate":
                fmt.get("bit_rate")
        }

    except Exception as e:
        return {
            "error": str(e)
        }


def scan_videos(folder):
    rows = []
    count = 0

    for root, _, files in os.walk(folder):
        for name in files:
            ext = os.path.splitext(name)[1].lower()
            if ext not in VIDEO_EXTENSIONS:
                continue
            count += 1
            path = os.path.join(root, name)
            print("扫描:", path)
            relative_path = os.path.relpath(path, folder)
            row = {
                "file_path": "./" + relative_path.replace("\\", "/"),
                "file_size_bytes": os.path.getsize(path)
            }
            row.update(get_audio_info(path))
            rows.append(row)

    print(f"\n找到视频数量: {count}")
    return rows


def save_csv(rows, filename):
    with open(
        filename,
        "w",
        newline="",
        encoding="utf-8-sig"
    ) as f:
        writer = csv.DictWriter(
            f,
            fieldnames=CSV_FIELDS,
            extrasaction="ignore"
        )
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    # 未指定目录时使用当前工作目录
    input_folder = os.getcwd()
    output_file = "audio_info.csv"
    print("当前扫描目录:")
    print(input_folder)
    data = scan_videos(input_folder)
    save_csv(
        data,
        output_file
    )
    print("\n完成:")
    print(
        os.path.abspath(output_file)
    )