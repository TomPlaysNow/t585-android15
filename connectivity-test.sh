#!/bin/bash
echo "=== GitHub API Konnektivität ==="
result=$(curl -sf "https://api.github.com/repos/LineageOS/android" 2>/dev/null)
if [ -z "$result" ]; then
  echo "FEHLER: GitHub API nicht erreichbar oder Rate-Limit"
  echo "Rate-Limit Info:"
  curl -sI "https://api.github.com/repos/LineageOS/android" 2>/dev/null | grep -i "x-ratelimit"
else
  echo "OK: LineageOS/android erreichbar"
  echo "$result" | python3 -c "import sys,json; d=json.load(sys.stdin); print('Default branch:', d.get('default_branch'))"
fi

echo ""
echo "=== Suche samsung gtaxl Device Trees direkt ==="
# Direkter Test mit korrekten htts
for name in \
  "android_device_samsung_gtaxllte" \
  "android_device_samsung_universal7870-common" \
  "android_kernel_samsung_universal7870"; do
  code=$(curl -so /dev/null -w "%{http_code}" "https://api.github.com/repos/LineageOS/${name}")
  echo "LineageOS/${name}: HTTP ${code}"
done
