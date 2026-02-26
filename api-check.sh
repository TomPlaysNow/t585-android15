#!/bin/bash
# GitHub API - keine Credentials nötig für öffentliche Repos
export GIT_TERMINAL_PROMPT=0

echo "=== GitHub API Check ==="
for repo in \
  "LineageOS/android_device_samsung_gtaxllte" \
  "LineageOS/android_device_samsung_gtaxl-common" \
  "LineageOS/android_kernel_samsung_exynos7870" \
  "LineageOS/android_vendor_samsung"; do
  
  result=$(curl -sf "https://api.github.com/repos/${repo}" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK private=' + str(d.get('private','?')))" 2>/dev/null || echo "404/nicht gefunden")
  echo "${repo}: ${result}"
done
