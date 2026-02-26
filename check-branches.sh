#!/bin/bash
# Prüft ob Git-Repos direkt klonierbar sind
for repo in android_device_samsung_gtaxllte android_device_samsung_gtaxl-common android_kernel_samsung_exynos7870; do
  echo -n "LineageOS/${repo}: "
  git ls-remote --heads "https://github.com/LineageOS/${repo}.git" 2>/dev/null | grep -E "lineage-22|lineage-21|lineage-20" | head -3
  echo ""
done
