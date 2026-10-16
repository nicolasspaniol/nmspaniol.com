#!/usr/bin/env bash
set -euo pipefail

DEST="src/nmspaniol_com/static/pictures"
JSON="data/pictures.json"

mkdir -p "$(dirname "$JSON")" "$DEST"

# will hold one jq object per processed image
entries=()

for f in "$@"; do
    if [[ ! -f "$f" ]]; then
        echo "skipping: '$f' not found"
        continue
    fi

    base="$(basename "$f")"
    base="${base%.*}"
    ext="${f##*.}"
    ext="${ext,,}"

    # convert to png, whatever the input format
    case "$ext" in
        heic|heif)
            heif-convert "$f" "$DEST/$base.png"
            ;;
        jpg|jpeg)
            magick "$f" "$DEST/$base.png"
            ;;
        png)
            cp "$f" "$DEST/$base.png"
            ;;
        *)
            echo "[ERR] '$f' is not a .heic/.heif/.jpg/.png file"
            exit 1
            ;;
    esac

    # generate thumbnail in the same folder
    magick "$DEST/$base.png" -resize 400x400 "$DEST/$base.thumb.png" -auto-orient

    # resize original too
    magick "$DEST/$base.png" -resize 1920x1920 "$DEST/$base.png" -auto-orient

    # encode lossless JPEG XL versions for the website
    cjxl --distance=0 --quiet "$DEST/$base.png" "$DEST/$base.jxl"
    cjxl --distance=0 --quiet "$DEST/$base.thumb.png" "$DEST/$base.thumb.jxl"

    # get resolution of the (auto-oriented) image
    res=$(identify -format "%w %h" "$DEST/$base.png")
    width=$(echo "$res" | cut -d' ' -f1)
    height=$(echo "$res" | cut -d' ' -f2)

    # build the json entry for this image
    entries+=("$(jq -n \
        --arg path "pictures/$base.jxl" \
        --arg thumb "pictures/$base.thumb.jxl" \
        --argjson width "$width" \
        --argjson height "$height" \
        '{"path": $path, "thumb": $thumb, "title": null, "width": $width, "height": $height}')")

    echo "[OK] added $base.jxl (+ thumbnail)"
done

# merge all new entries into the existing json (or empty array) in one pass
existing=$(cat "$JSON" 2>/dev/null || echo "[]")
printf '%s\n' "${entries[@]}" | jq -s '.' | jq --argjson existing "$existing" '$existing + .' > "$JSON"

echo "[OK] updated $JSON"
