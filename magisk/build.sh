#!/bin/sh
# Build the Magisk module zip from ../blobs. Usage: ./build.sh  -> Bitra-Portrait-Fix-<version>.zip
set -e
cd "$(dirname "$0")"
VER=$(grep '^version=' module.prop | cut -d= -f2)
OUT="$PWD/Bitra-Portrait-Fix-$VER.zip"
TMP=$(mktemp -d)
cp -r module.prop customize.sh post-fs-data.sh META-INF "$TMP/"
mkdir -p "$TMP/files"
cp ../blobs/odm/lib64/*.so ../blobs/odm/lib/rfsa/adsp/*.so "$TMP/files/"
rm -f "$OUT"
(cd "$TMP" && zip -r -X -q "$OUT" .)
rm -rf "$TMP"
echo "$OUT"
