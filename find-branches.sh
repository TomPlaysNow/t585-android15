#!/bin/bash
# Suche gtaxllte Repos auf GitHub
echo "=== Suche nach gtaxllte Device Trees ==="

# LineageOS Repos prüfen (alle Branches)
for repo in android_device_samsung_gtaxllte android_device_samsung_gtaxl-common; do
  echo "--- LineageOS/${repo} ---"
  git ls-remote --heads "https://github.com/LineageOS/${repo}.git" 2>/dev/null | awk '{print $2}' | sed 's|refs/heads/||' | sort
  echo ""
done

# Kernel
echo "--- Kernel exynos7870 ---"
git ls-remote --heads "https://github.com/LineageOS/android_kernel_samsung_exynos7870.git" 2>/dev/null | awk '{print $2}' | sed 's|refs/heads/||' | sort
