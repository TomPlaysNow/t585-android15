#!/usr/bin/env bash
# start-sync.sh — repo sync im Hintergrund starten

cd ~/aosp

echo "=== Starte repo sync im Hintergrund ==="
echo "Log: ~/sync.log"

nohup ~/bin/repo sync \
    --jobs=8 \
    --current-branch \
    --no-tags \
    --fail-fast \
    --force-sync \
    > ~/sync.log 2>&1 &

SYNC_PID=$!
echo "SYNC_PID=$SYNC_PID"
echo $SYNC_PID > ~/sync.pid

echo ""
echo "=== k9100ii Download Status ==="
if [ -f ~/k9100ii-download.pid ]; then
    K_PID=$(cat ~/k9100ii-download.pid)
    if kill -0 "$K_PID" 2>/dev/null; then
        echo "k9100ii Download läuft (PID: $K_PID)"
        ls -lh ~/k9100ii-gtaxllte-sources.tar.gz 2>/dev/null || echo "Datei noch nicht vorhanden"
    else
        echo "k9100ii Download fertig oder abgebrochen"
        ls -lh ~/k9100ii-gtaxllte-sources.tar.gz 2>/dev/null
    fi
fi

echo ""
echo "=== Status überwachen mit: ==="
echo "  tail -f ~/sync.log"
echo "  cat ~/sync.pid"
echo "  ls -lh ~/k9100ii-gtaxllte-sources.tar.gz"
