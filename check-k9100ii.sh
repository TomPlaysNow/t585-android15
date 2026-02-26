#!/usr/bin/env bash
# Prüfe XDA-Archiv und k9100ii-GitHub-Repos

echo "=== XDA-Archiv Header ==="
curl -sI 'https://xdaforums.com/attachments/gtaxl_lineage_source_archive-tar-gz.6210266/' | head -8

echo ""
echo "=== k9100ii GitHub Repos ==="
curl -sf 'https://api.github.com/users/k9100ii/repos?per_page=50' | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data:
    print(r['name'], '|', r.get('default_branch',''), '|', r.get('pushed_at','')[:10])
" 2>/dev/null || echo "Keine Repos oder Fehler"

echo ""
echo "=== Suche k9100ii gtaxllte Repos direkt ==="
for repo in android_device_samsung_gtaxllte android_device_samsung_exynos7870-common android_kernel_samsung_exynos7870 android_vendor_samsung_gtaxllte; do
    code=$(curl -sIL "https://github.com/k9100ii/${repo}" 2>/dev/null | head -1 | awk '{print $2}')
    echo "k9100ii/${repo}: HTTP ${code}"
done

echo ""
echo "=== Prüfe InfinityX-Alternative-Forks ==="
for org in ProjectInfinity-X InfinityX-Project; do
    code=$(curl -sI "https://github.com/${org}/manifest" 2>/dev/null | head -1 | awk '{print $2}')
    echo "${org}/manifest: HTTP ${code}"
done
