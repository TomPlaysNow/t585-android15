#!/bin/bash
MAC="thoma@192.168.188.166"

echo "=== Alle Volumes ==="
ssh "$MAC" "ls -la /Volumes/"

echo ""
echo "=== Suche sparseimage auf ganzer SSD und Home ==="
ssh "$MAC" "find '/Volumes/SSD' '/Users/thoma' -name '*.sparseimage' 2>/dev/null; find '/Users/thoma' -name '*.img' 2>/dev/null | grep -i android"

echo ""
echo "=== Docker via voller Pfad ==="
ssh "$MAC" "/usr/local/bin/docker ps -a 2>/dev/null || /Applications/Docker.app/Contents/Resources/bin/docker ps -a 2>/dev/null || ~/.docker/bin/docker ps -a 2>/dev/null || echo 'Docker nicht gefunden'"

echo ""
echo "=== Hdiutil Info (gemountete Images) ==="
ssh "$MAC" "hdiutil info 2>/dev/null | grep -E 'image-path|/Volumes|sparseimage'"

echo ""
echo "=== Synology Drive Ordner ==="
ssh "$MAC" "ls '/Volumes/SSD/Synology SSD/' 2>/dev/null | head -20"
