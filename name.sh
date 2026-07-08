for file in half_*; do
    [ -e "$file" ] || continue
    new_name="${file#half_}"
    mv -- "$file" "$new_name"
done

# 将当前目录中文件名为half_*的文件全部改为*
