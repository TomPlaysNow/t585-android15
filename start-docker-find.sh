#!/bin/bash
MAC="thoma@192.168.188.166"
DOCKER="/Applications/Docker.app/Contents/Resources/bin/docker"

echo "=== Samsung Android/t585-android15 Inhalt ==="
ssh "$MAC" "ls -la '/Users/thoma/Samsung Android/t585-android15/'"

echo ""
echo "=== Docker VM Sparse Image ==="
ssh "$MAC" "find '/Users/thoma/Library/Containers/com.docker.docker/Data/vms' -name '*.raw' -o -name '*.img' -o -name '*.sparseimage' 2>/dev/null"

echo ""
echo "=== Docker starten und Container prüfen ==="
ssh "$MAC" "open -a Docker; sleep 5; $DOCKER ps -a 2>/dev/null | head -5 || echo 'Docker startet noch...'"

echo ""
echo "=== Suche AndroidBuild sparseimage ==="
ssh "$MAC" "find '/Users/thoma' '/Volumes/SSD' -name '*AndroidBuild*' -o -name '*android-build*' 2>/dev/null | grep -iv '.Trash'"
