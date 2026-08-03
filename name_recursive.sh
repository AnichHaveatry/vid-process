find . -type f -name 'half_*' -print0 | while IFS= read -r -d '' file; do
    dir=$(dirname "$file")
    base=$(basename "$file")
    new_name="${base#half_}"
    mv -- "$file" "$dir/$new_name"
done

# 递归删除所有子文件夹中的文件文件名前面的 half_ 前缀
