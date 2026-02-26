#!/bin/bash
for repo in android_device_samsung_gtaxllte android_device_samsung_gtaxl-common android_kernel_samsung_exynos7870 android_vendor_samsung; do
  for branch in lineage-22.2 lineage-22.1 lineage-21 lineage-20; do
    code=$(curl -sI "https://github.com/LineageOS/${repo}/tree/${branch}" 2>/dev/null | head -1 | awk '{print $2}')
    if [ "$code" = "200" ]; then
      echo "OK  ${repo} -> ${branch}"
      break
    fi
  done
  if [ "$code" != "200" ]; then
    echo "404 ${repo} -> kein Branch gefunden"
  fi
done
