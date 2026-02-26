#!/bin/bash
echo "=== GitHub Code Search: gtaxllte ==="
curl -sf "https://api.github.com/search/repositories?q=gtaxllte+android&sort=updated&per_page=20" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('Gefunden:', data.get('total_count', 0), 'Repos')
for r in data.get('items', []):
    print(' -', r['full_name'], '| Branch:', r.get('default_branch','?'), '| Updated:', r['updated_at'][:10])
"

echo ""
echo "=== GitHub Search: exynos7870 android15 ==="
curl -sf "https://api.github.com/search/repositories?q=exynos7870+android15&sort=updated&per_page=10" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data.get('items', []):
    print(' -', r['full_name'], '| Branch:', r.get('default_branch','?'))
"
