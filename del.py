import os
import pandas as pd

# 工作目录下的 CSV
csv_file = "video_report.csv"

# 读取 CSV
df = pd.read_csv(csv_file)

# 建立文件索引
files = {}

for _, row in df.iterrows():
    filename = os.path.basename(row["path"])

    files[filename] = {
        "path": row["path"],
        "size_mb": float(row["size_mb"])
    }


deleted = []

# 遍历 half_xxx 文件
for filename, info in list(files.items()):

    if not filename.startswith("half_"):
        continue

    # 去掉 half_ 得到原文件名
    original_name = filename[len("half_"):]

    # 查找对应原文件
    if original_name not in files:
        continue

    half_file = info
    original_file = files[original_name]

    # 比较大小，删除大的
    if half_file["size_mb"] > original_file["size_mb"]:
        delete_file = half_file
        keep_file = original_file
    else:
        delete_file = original_file
        keep_file = half_file

    print("=" * 60)
    print("发现匹配:")
    print(f"  {original_file['path']} : {original_file['size_mb']} MB")
    print(f"  {half_file['path']} : {half_file['size_mb']} MB")

    print(
        f"删除较大文件: {delete_file['path']} "
        f"({delete_file['size_mb']} MB)"
    )
    print(
        f"保留较小文件: {keep_file['path']} "
        f"({keep_file['size_mb']} MB)"
    )

    # 删除文件
    if os.path.exists(delete_file["path"]):
        os.remove(delete_file["path"])
        deleted.append(delete_file["path"])


print("\n处理完成")
print(f"删除文件数量: {len(deleted)}")



'''
这段代码的作用：

读取当前目录下的 `video_report.csv`，查找同一视频的原始版本和 `half_` 压缩版本，将 `half_xxx.mp4` 与对应的 `xxx.mp4` 配对，比较二者大小，并自动删除占用空间更大的文件，保留较小的版本。

主要流程：

1. 读取 CSV 文件
   - 加载 `video_report.csv`；
   - 获取每个视频的路径 (`path`) 和大小 (`size_mb`)。
2. 建立视频索引
   - 以文件名为索引，记录每个视频的位置和大小。
3. 寻找对应视频
   - 查找所有以 `half_` 开头的视频；
   - 例如：
     - `a.mp4` ↔ `half_a.mp4`
     - `b.mp4` ↔ `half_b.mp4`
4. 比较文件大小
   - 对每组对应视频：
     - 如果 `half_xxx.mp4` 更大，则删除 `half_xxx.mp4`；
     - 如果 `xxx.mp4` 更大，则删除 `xxx.mp4`。
5. 执行删除
   - 删除较大的视频文件；
   - 输出删除和保留的信息；
   - 最后统计删除数量。
'''
