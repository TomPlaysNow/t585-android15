#!/bin/bash
set -e

export PATH="$HOME/bin:$PATH"
export USE_CCACHE=1
export CCACHE_DIR="$HOME/.ccache"

echo "=== Python prüfen ==="
which python3 && python3 --version

echo "=== repo PATH setzen ==="
echo "$PATH"

echo "=== AOSP Verzeichnis ==="
mkdir -p ~/aosp
cd ~/aosp

echo "=== repo init (LineageOS 22.2) ==="
~/bin/repo init \
  -u https://github.com/LineageOS/android.git \
  -b lineage-22.2 \
  --depth=1

echo "=== Device Manifest anlegen ==="
mkdir -p .repo/local_manifests
cat > .repo/local_manifests/gtaxllte.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <project name="LineageOS/android_device_samsung_gtaxllte"
           path="device/samsung/gtaxllte"
           remote="github" revision="lineage-22.2" />
  <project name="LineageOS/android_device_samsung_gtaxl-common"
           path="device/samsung/gtaxl-common"
           remote="github" revision="lineage-22.2" />
  <project name="LineageOS/android_kernel_samsung_exynos7870"
           path="kernel/samsung/exynos7870"
           remote="github" revision="lineage-22.2" />
  <project name="LineageOS/android_vendor_samsung"
           path="vendor/samsung"
           remote="github" revision="lineage-22.2" />
</manifest>
EOF

echo "=== repo sync starten (dauert 2-8 Stunden) ==="
~/bin/repo sync -j12 --no-clone-bundle --no-tags --fail-fast 2>&1 | tee ~/repo-sync.log
echo "=== SYNC FERTIG ==="
