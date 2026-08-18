import os
import csv
import json
import subprocess

VIDEO_EXTENSIONS = {
    ".mp4", ".mkv", ".mov", ".avi",
    ".webm", ".flv", ".wmv", ".m4v",
    ".ts", ".mts", ".3gp"
}


def get_audio_info(filepath):
    """
    使用 ffprobe 获取音频流信息
    """
    cmd = [
        "ffprobe",
        "-v", "quiet",
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

        data = json.loads(result.stdout)
        audio_stream = None
        for stream in data.get("streams", []):
            if stream.get("codec_type") == "audio":
                audio_stream = stream
                break
        if not audio_stream:
            return {
                "has_audio": False
            }
        fmt = data.get("format", {})

        return {
            "has_audio": True,
            "audio_codec":
                audio_stream.get("codec_name"),
            "audio_codec_long":
                audio_stream.get("codec_long_name"),
            "audio_profile":
                audio_stream.get("profile"),
            "sample_rate":
                audio_stream.get("sample_rate"),
            "channels":
                audio_stream.get("channels"),
            "channel_layout":
                audio_stream.get("channel_layout"),
            "bit_rate":
                audio_stream.get("bit_rate"),
            "sample_fmt":
                audio_stream.get("sample_fmt"),
            "bits_per_sample":
                audio_stream.get("bits_per_sample"),
            "audio_duration":
                audio_stream.get("duration"),
            "audio_tags":
                json.dumps(
                    audio_stream.get("tags", {}),
                    ensure_ascii=False
                ),
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


def scan_videos(root_folder, output_csv):
    rows = []
    for root, dirs, files in os.walk(root_folder):
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext not in VIDEO_EXTENSIONS:
                continue

            filepath = os.path.join(root, file)
            print("Processing:", filepath)

            try:
                size = os.path.getsize(filepath)
            except:
                size = None

            info = {
                "file_path": filepath,
                "file_size_bytes": size
            }
            audio_info = get_audio_info(filepath)
            info.update(audio_info)
            rows.append(info)


    # 自动生成所有字段
    keys = set()

    for r in rows:
        keys.update(r.keys())
    keys = list(keys)

    with open(
        output_csv,
        "w",
        newline="",
        encoding="utf-8-sig"
    ) as f:
        writer = csv.DictWriter(
            f,
            fieldnames=keys
        )
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    # 使用当前工作目录
    input_folder = os.getcwd()
    output_file = "audio_info.csv"
    scan_videos(
        input_folder,
        output_file
    )
    print("完成:", output_file)
