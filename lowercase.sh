find . -type f | while read -r f; do
    ext="${f##*.}"
    new="${f%.*}.${ext,,}"

    if [ "$f" != "$new" ]; then
        tmp="$(mktemp "${f%/*}/.tmp_XXXXXX")"
        mv -- "$f" "$tmp"
        mv -- "$tmp" "$new"
    fi
done