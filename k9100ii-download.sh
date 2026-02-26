#!/usr/bin/env bash
# k9100ii-download.sh — XDA-Archiv im Hintergrund herunterladen

ARCHIVE_FILE=~/k9100ii-gtaxllte-sources.tar.gz
LOG_FILE=~/k9100ii-download.log

if [ -f "$ARCHIVE_FILE" ]; then
    SIZE=$(stat -c%s "$ARCHIVE_FILE" 2>/dev/null || echo 0)
    if [ "$SIZE" -gt 300000000 ]; then
        echo "Archiv bereits vollständig: $(ls -lh $ARCHIVE_FILE)"
        exit 0
    else
        echo "Archiv unvollständig ($SIZE Bytes) — starte neu"
        rm -f "$ARCHIVE_FILE"
    fi
fi

echo "Starte Download (374 MB)..."
nohup curl -L \
    --retry 5 \
    --retry-delay 10 \
    --continue-at - \
    -o "$ARCHIVE_FILE" \
    'https://xdaforums.com/attachments/gtaxl_lineage_source_archive-tar-gz.6210266/' \
    > "$LOG_FILE" 2>&1 &

K_PID=$!
echo $K_PID > ~/k9100ii-download.pid
echo "k9100ii Download gestartet (PID: $K_PID)"
echo "Log: $LOG_FILE"
echo ""
echo "=== repo sync Status ==="
ps aux | grep 'repo.*sync' | grep -v grep | head -3
echo ""
echo "=== sync.log (letzte 10 Zeilen) ==="
tail -10 ~/sync.log 2>/dev/null
