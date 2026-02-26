#!/bin/bash
MAC="thoma@192.168.188.166"

echo "=== Volumes auf dem Mac ==="
ssh "$MAC" "ls /Volumes/"

echo ""
echo "=== Sparse Images auf SSD ==="
ssh "$MAC" "find '/Volumes/SSD' -maxdepth 6 \( -name '*.sparseimage' -o -name '*.dmg' \) 2>/dev/null"

echo ""
echo "=== Sparse Images auf Macintosh HD ==="
ssh "$MAC" "find '/Volumes/Macintosh HD' -maxdepth 6 \( -name '*.sparseimage' -o -name '*.dmg' \) 2>/dev/null | grep -i android"
