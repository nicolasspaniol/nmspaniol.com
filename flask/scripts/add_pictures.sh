#!/usr/bin/env bash
set -euo pipefail

DEST="src/nmspaniol_com/static/pictures"
JSON="data/pictures.json"

mkdir -p "$(dirname "$JSON")" "$DEST"

# the pngs we work on are only intermediates; keeping them in a scratch
# directory means nothing but the .jxl files ends up in "$DEST"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

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

    png="$workdir/$base.png"
    thumb_png="$workdir/$base.thumb.png"

    # convert to png, whatever the input format
    case "$ext" in
        heic|heif)
            heif-convert "$f" "$png"
            ;;
        jpg|jpeg|png)
            magick "$f" "$png"
            ;;
        *)
            echo "[ERR] '$f' is not a .heic/.heif/.jpg/.png file"
            exit 1
            ;;
    esac

    # generate thumbnail from the full resolution image, applying the exif
    # rotation so the pixels match the resolution we store below
    magick "$png" -auto-orient -resize '400x400>' "$thumb_png"

    # resize original too
    magick "$png" -auto-orient -resize '1920x1920>' "$png"

    # get resolution of the (auto-oriented) image
    res=$(identify -format "%w %h" "$png")
    width=$(echo "$res" | cut -d' ' -f1)
    height=$(echo "$res" | cut -d' ' -f2)

    # drop the pngs older versions of this script left in the static directory
    rm -f "$DEST/$base.png" "$DEST/$base.thumb.png"

    # encode lossless JPEG XL for the website; the full size one is progressive
    # so browsers can start rendering it while it downloads
    cjxl --distance=0 --progressive --quiet "$png" "$DEST/$base.jxl"
    cjxl --distance=0 --quiet "$thumb_png" "$DEST/$base.thumb.jxl"

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
