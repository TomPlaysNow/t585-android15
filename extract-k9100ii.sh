#!/usr/bin/env bash
# extract-k9100ii.sh — k9100ii-Archiv extrahieren und Inhalt prüfen

set -e

ARCHIVE=~/k9100ii-gtaxllte-sources.tar.gz
EXTRACT_DIR=~/k9100ii-sources

echo "=== SHA256 prüfen ==="
ACTUAL=$(sha256sum "$ARCHIVE" | awk '{print $1}')
EXPECTED="20e558213749743a1d3f6ce47fc8aef4e8266c52188e8054b4def93a6cfa31b7"
if [ "$ACTUAL" = "$EXPECTED" ]; then
    echo "SHA256 OK: $ACTUAL"
else
    echo "SHA256 ABWEICHEND: $ACTUAL (erwartet: $EXPECTED)"
    echo "Fortfahren..."
fi

echo ""
echo "=== Extrahiere nach $EXTRACT_DIR ==="
mkdir -p "$EXTRACT_DIR"

# Prüfe ob bereits extrahiert
if [ "$(ls -A $EXTRACT_DIR 2>/dev/null)" ]; then
    echo "Verzeichnis schon befüllt, überspringe Extraktion"
else
    tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR" \
        2>&1 | grep -v "LIBARCHIVE\|Removing leading" || true
    echo "Extraktion abgeschlossen"
fi

echo ""
echo "=== Inhalt von $EXTRACT_DIR (erste 2 Ebenen) ==="
find "$EXTRACT_DIR" -maxdepth 2 | head -40
echo ""

echo "=== Alle Git-Repos im Archiv ==="
find "$EXTRACT_DIR" -name "HEAD" -type f | while read f; do
    dir=$(dirname "$f")
    echo "  $dir"
done
echo ""

echo "=== Alle .git-Bundles oder Bare-Repos ==="
find "$EXTRACT_DIR" -name "config" -path "*/git*" -type f | head -20
