#!/usr/bin/env bash
# clone-device-trees.sh
# Klont alle Samsung/gtaxllte Device Trees aus dem k9100ii-Archiv in den AOSP-Tree.
# Kann parallel zu repo sync laufen, da diese Pfade nicht im InfinityX-Manifest sind.

set -euo pipefail

AOSP_DIR=~/aosp
MIRRORS=~/k9100ii-sources/gtaxl_lineage_source_archive/git_mirrors
BRANCH="lineage-21"

echo "════════════════════════════════════════════════════"
echo "  T585/gtaxllte Device Trees klonen"
echo "  Branch: $BRANCH"
echo "════════════════════════════════════════════════════"
echo ""

if [ ! -d "$MIRRORS" ]; then
    echo "FEHLER: Mirrors-Verzeichnis nicht gefunden: $MIRRORS"
    exit 1
fi

# Hilfsfunktion: Repo klonen oder aktualisieren
clone_or_update() {
    local repo_name="$1"
    local dest_path="$2"
    local branch="${3:-$BRANCH}"
    local src="${MIRRORS}/${repo_name}.git"
    local full_dest="${AOSP_DIR}/${dest_path}"
    
    if [ ! -d "$src" ]; then
        echo "  ⚠  Mirror nicht gefunden: $src"
        return
    fi
    
    if [ -d "${full_dest}/.git" ]; then
        echo "  ↻  Existiert: $dest_path (überspringe)"
        return
    fi
    
    echo "  →  Klone: $dest_path ($branch)"
    mkdir -p "$(dirname "$full_dest")"
    git clone --quiet "$src" -b "$branch" "$full_dest" 2>&1 | grep -v "^$" || true
    echo "  ✓  Fertig: $dest_path"
}

# ─── Kernel ──────────────────────────────────────────────────────────────────
echo "=== Kernel ==="
clone_or_update "android_kernel_samsung_exynos7870" "kernel/samsung/exynos7870"
echo ""

# ─── Device Trees ────────────────────────────────────────────────────────────
echo "=== Device Trees ==="
clone_or_update "android_device_samsung_gtaxl-common"  "device/samsung/gtaxl-common"
clone_or_update "android_device_samsung_gtaxllte"      "device/samsung/gtaxllte"
echo ""

# ─── Vendor Blobs ────────────────────────────────────────────────────────────
echo "=== Vendor ==="
clone_or_update "android_vendor_samsung_gtaxl-common"  "vendor/samsung/gtaxl-common"
clone_or_update "android_vendor_samsung_gtaxllte"      "vendor/samsung/gtaxllte"
echo ""

# ─── Samsung Hardware HALs ───────────────────────────────────────────────────
echo "=== Hardware Samsung SLSI-Linaro HALs ==="
clone_or_update "android_hardware_samsung"                         "hardware/samsung"
clone_or_update "android_hardware_samsung_slsi-linaro_codec2"     "hardware/samsung_slsi-linaro/codec2"
clone_or_update "android_hardware_samsung_slsi-linaro_config"     "hardware/samsung_slsi-linaro/config"
clone_or_update "android_hardware_samsung_slsi-linaro_exynos"     "hardware/samsung_slsi-linaro/exynos"
clone_or_update "android_hardware_samsung_slsi-linaro_exynos5"    "hardware/samsung_slsi-linaro/exynos5"
clone_or_update "android_hardware_samsung_slsi-linaro_graphics"   "hardware/samsung_slsi-linaro/graphics"
clone_or_update "android_hardware_samsung_slsi-linaro_interfaces" "hardware/samsung_slsi-linaro/interfaces"
clone_or_update "android_hardware_samsung_slsi-linaro_openmax"    "hardware/samsung_slsi-linaro/openmax"
echo ""

# ─── Optional: aptX =─────────────────────────────────────────────────────────
echo "=== Optional: aptX ==="
clone_or_update "android_external_aptxenc" "external/aptxenc" 2>/dev/null || true
echo ""

# ─── Ergebnis prüfen ─────────────────────────────────────────────────────────
echo "=== Ergebnis ==="
REQUIRED=(
    "kernel/samsung/exynos7870"
    "device/samsung/gtaxl-common"
    "device/samsung/gtaxllte"
    "vendor/samsung/gtaxl-common"
    "vendor/samsung/gtaxllte"
)

ALL_OK=true
for path in "${REQUIRED[@]}"; do
    if [ -d "${AOSP_DIR}/${path}/.git" ]; then
        FILES=$(ls "${AOSP_DIR}/${path}" | wc -l)
        echo "  ✓  $path ($FILES Dateien)"
    else
        echo "  ✗  FEHLT: $path"
        ALL_OK=false
    fi
done

echo ""
if $ALL_OK; then
    echo "════════════════════════════════════════════════════"
    echo "  ✓ Alle erforderlichen Device Trees geklont!"
    echo "════════════════════════════════════════════════════"
    echo ""
    echo "Nächste Schritte (NACH repo sync):"
    echo "  1. Framework-Patches anwenden:"
    echo "     bash /mnt/c/Users/thoma/Projects/t585-android15/apply-patches.sh"
    echo ""
    echo "  2. Build starten:"
    echo "     cd ~/aosp"
    echo "     source build/envsetup.sh"
    echo "     lunch lineage_gtaxllte-user"
    echo "     mka bacon -j\$(nproc)"
else
    echo "⚠  Einige Device Trees fehlen!"
fi
