#!/bin/bash
MAC="thoma@192.168.188.166"

echo "=== SSD Inhalt ==="
ssh "$MAC" "ls '/Volumes/SSD/'"

echo ""
echo "=== Suche aosp Verzeichnis überall ==="
ssh "$MAC" "find '/Volumes/SSD' '/Volumes/Macintosh HD/Users/thoma' -maxdepth 5 -name 'aosp' -type d 2>/dev/null"

echo ""
echo "=== Docker Volumes ==="
ssh "$MAC" "docker volume ls 2>/dev/null || echo 'Docker nicht verfügbar'"

echo ""
echo "=== Docker Container Info ==="
ssh "$MAC" "docker inspect t585-android15 2>/dev/null | python3 -c \"import sys,json; d=json.load(sys.stdin); [print(m['Source'],'->', m['Destination']) for m in d[0].get('Mounts',[])]\" 2>/dev/null || echo 'Container nicht gefunden'"
