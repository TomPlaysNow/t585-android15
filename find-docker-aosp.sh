#!/bin/bash
MAC="thoma@192.168.188.166"

echo "=== Docker Pfade suchen ==="
ssh "$MAC" "ls /Applications/ | grep -i docker; ls /usr/local/bin/ | grep -i docker; ls ~/Library/Application\ Support/ | grep -i docker"

echo ""
echo "=== Synology SSD Inhalt ==="
ssh "$MAC" "ls -la '/Volumes/SSD/Synology SSD/'"

echo ""
echo "=== Suche sparseimage in Samsung Android Ordner ==="
ssh "$MAC" "find '/Users/thoma/Samsung Android' -maxdepth 5 -name '*.sparseimage' 2>/dev/null; ls '/Users/thoma/Samsung Android/' 2>/dev/null"

echo ""
echo "=== Docker sparseimage in Library ==="
ssh "$MAC" "find '/Users/thoma/Library/Containers' -maxdepth 5 -name '*.sparseimage' 2>/dev/null | head -5"
