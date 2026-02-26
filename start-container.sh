#!/bin/bash
MAC="thoma@192.168.188.166"
DOCKER="/Applications/Docker.app/Contents/Resources/bin/docker"
PROJ="/Users/thoma/Samsung Android/t585-android15"

echo "=== patches Ordner ==="
ssh "$MAC" "find '$PROJ/patches' -type f 2>/dev/null"

echo ""
echo "=== scripts Ordner ==="
ssh "$MAC" "ls -la '$PROJ/scripts/'"

echo ""
echo "=== Docker Desktop starten ==="
ssh "$MAC" "open -a Docker 2>/dev/null; echo 'Docker wird gestartet...'"

echo ""
echo "=== Warte 15 Sekunden auf Docker ==="
sleep 15

echo ""
echo "=== Docker Container starten ==="
ssh "$MAC" "$DOCKER start t585-android15 2>/dev/null && echo 'Container gestartet' || echo 'Fehler beim Starten'"

echo ""
echo "=== AOSP Größe im Container ==="
ssh "$MAC" "$DOCKER exec t585-android15 du -sh /aosp/device /aosp/vendor /aosp/kernel 2>/dev/null || echo 'Container noch nicht bereit'"
