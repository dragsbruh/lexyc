#!/usr/bin/env bash
set -euo pipefail

OUT_DIR=${OUT_DIR:-"_release/assets"}
CHANGELOG=${CHANGELOG:-"_release/CHANGELOG.md"}
IN_DIR=${IN_DIR:-"zig-out"}
REFNAME="${REFNAME:-HEAD}"

mkdir -p "$OUT_DIR"

prev_tag=$(git tag --list 'v*' --sort=-v:refname | grep -vx "$REFNAME" | head -n1 || true)

if [ -n "$prev_tag" ]; then
    range="$prev_tag..$REFNAME"
else
    range="$REFNAME"
fi

echo "# changelog" > "$CHANGELOG"
echo >> "$CHANGELOG"
git log "$range" --pretty=format:"- %s" | grep -vE "^- (ci:|docs:)" >> "$CHANGELOG"

echo "changelog written for range $range to $CHANGELOG"

for target in "$IN_DIR"/*; do
    [ -d "$target" ] || continue

    triplet="$(basename "$target")"

    arch="${triplet%%-*}"
    os="${triplet#*-}"

    if [[ "$os" == *windows* ]]; then
        exe="$target/lexyc.exe"
        raw="$OUT_DIR/lexyc-$os-$arch.exe"
    else
        exe="$target/lexyc"
        raw="$OUT_DIR/lexyc-$os-$arch"
    fi

    [ -f "$exe" ] || continue

    echo "packaging $raw"

    cp "$exe" "$raw"
    chmod +x "$raw" || true
    zstd -9 -f "$raw" -o "$raw.zst"
done

echo "release artifacts written to $OUT_DIR/"
