#!/bin/bash
echo "=== Suche gtaxllte Device Trees ==="

# ProjectInfinityX direkt prüfen
for name in \
  "android_device_samsung_gtaxllte" \
  "android_device_samsung_gtaxl-common" \
  "android_kernel_samsung_exynos7870" \
  "android_vendor_samsung"; do
  for org in ProjectInfinityX infinity-x-project SamsungOpenSourceProject; do
    code=$(curl -so /dev/null -w "%{http_code}" "https://api.github.com/repos/${org}/${name}")
    if [ "$code" = "200" ]; then
      echo "GEFUNDEN: ${org}/${name}"
    fi
  done
done

echo ""
echo "=== Suche ProjectInfinityX Repo-Liste ==="
curl -sf "https://api.github.com/orgs/ProjectInfinityX/repos?per_page=100&type=public" 2>/dev/null | python3 -c "
import sys, json
repos = json.load(sys.stdin)
for r in repos:
    if 'samsung' in r['name'].lower() or 'gtax' in r['name'].lower() or 'exynos' in r['name'].lower():
        print(r['name'], '->', r.get('default_branch','?'))
" 2>/dev/null || echo "ProjectInfinityX Org nicht abrufbar"
