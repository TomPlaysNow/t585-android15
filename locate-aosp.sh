#!/bin/bash
MAC="thoma@192.168.188.166"

# Samsung Android Ordner
echo "=== Samsung Android Ordner ==="
ssh "$MAC" "ls '/Users/thoma/Samsung Android/' 2>/dev/null || echo 'nicht gefunden'"

echo ""
echo "=== hdiutil info (gemountete Images) ==="
ssh "$MAC" "hdiutil info 2>/dev/null | grep -E 'image-path|UDSP|sparseimage'"

echo ""
echo "=== Docker sparseimage in Library/Containers ==="
ssh "$MAC" "ls '/Users/thoma/Library/Containers/com.docker.docker/Data/' 2>/dev/null | head -10"

echo ""
echo "=== Docker executable ==="
ssh "$MAC" "ls /Applications/Docker.app/Contents/Resources/bin/docker 2>/dev/null && echo 'gefunden' || echo 'fehlt'"
