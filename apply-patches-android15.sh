#!/usr/bin/env bash
# apply-patches-android15.sh
# Wendet BPF-Kompatibilitäts-Patches für Exynos 7870 (Kernel 3.18) auf Android 15 an.
#
# HINWEIS: Patches 1-6 sind in LineageOS 22.1 gemerged (Stand Nov 2024).
# Wenn repo sync mit lineage-22.1 Branches lief, sind sie bereits enthalten!
# Dieses Skript prüft das und wendet nur fehlende Patches an.
#
# Verwendung: bash apply-patches-android15.sh
# Voraussetzung: repo sync muss abgeschlossen sein!

set -euo pipefail

AOSP_DIR=~/aosp
PATCHES_DIR=~/aosp-patches
K9100II_PATCHES=~/k9100ii-sources/gtaxl_lineage_source_archive/framework_patches

echo "════════════════════════════════════════════════════"
echo "  Android 15 BPF-Patches für Exynos 7870 / SM-T585"
echo "════════════════════════════════════════════════════"
echo ""

# Hilfsfunktion: Prüfe ob Commit schon im Repo
commit_exists() {
    git log --oneline 2>/dev/null | grep -q "$1" 2>/dev/null
}

# Hilfsfunktion: Patch sicher anwenden
apply_patch() {
    local patch_file="$1"
    local patch_name=$(basename "$patch_file")
    
    if git apply --check "$patch_file" 2>/dev/null; then
        git apply "$patch_file"
        echo "    ✓ $patch_name angewendet"
    else
        echo "    ↻ $patch_name übersprungen (bereits angewendet oder Konflikt)"
    fi
}

# ─── Schritt 1: system/bpf ───────────────────────────────────────────────────
echo "=== system/bpf (Patches 1-4) ==="
BPF_DIR="$AOSP_DIR/system/bpf"

if [ ! -d "$BPF_DIR" ]; then
    echo "  ⚠  system/bpf nicht gefunden — repo sync noch nicht fertig?"
    echo "  Überspringe..."
else
    cd "$BPF_DIR"
    
    # Prüfe ob Patch 1 (bpfloader 4.9T support, commit 643339ec) bereits da
    if git log --oneline 2>/dev/null | grep -q "643339e\|4\.9-T kernel\|4\.9 T kernel" 2>/dev/null; then
        echo "  ✓ Patches 1-4 bereits in system/bpf enthalten (lineage-22.1 merge)"
    else
        echo "  → Wende Patches auf system/bpf an..."
        for patch in "$PATCHES_DIR"/000[1-4]-*.patch; do
            [ -f "$patch" ] && apply_patch "$patch"
        done
    fi
    cd - > /dev/null
fi
echo ""

# ─── Schritt 2: packages/modules/Connectivity ────────────────────────────────
echo "=== packages/modules/Connectivity (Patches 5-6) ==="
CONN_DIR="$AOSP_DIR/packages/modules/Connectivity"

if [ ! -d "$CONN_DIR" ]; then
    echo "  ⚠  Connectivity nicht gefunden — repo sync noch nicht fertig?"
    echo "  Überspringe..."
else
    cd "$CONN_DIR"
    
    # Prüfe ob Patch 5 (netd kver 4.19, commit 3b4ae197) bereits da
    if git log --oneline 2>/dev/null | grep -q "3b4ae19\|4\.19.*cgroup\|kver.*4\.19\|Require 4\.19" 2>/dev/null; then
        echo "  ✓ Patch 5 (netd kver 4.19) bereits in Connectivity enthalten"
    else
        echo "  → Wende Patch 5 auf Connectivity an..."
        for patch in "$PATCHES_DIR"/0005-*.patch; do
            [ -f "$patch" ] && apply_patch "$patch"
        done
    fi
    
    # Prüfe ob Patch 6 (BpfHandler kver checks) bereits da
    if git log --oneline 2>/dev/null | grep -q "407763\|kver.*BPF attach\|BpfHandler.*kver" 2>/dev/null; then
        echo "  ✓ Patch 6 (BpfHandler kver) bereits in Connectivity enthalten"
    else
        echo "  → Wende Patch 6 auf Connectivity an..."
        for patch in "$PATCHES_DIR"/0006-*.patch; do
            [ -f "$patch" ] && apply_patch "$patch"
        done
    fi
    cd - > /dev/null
fi
echo ""

# ─── Schritt 3: Kernel Config prüfen ─────────────────────────────────────────
echo "=== Kernel-Defconfig prüfen (CONFIG für Android 15) ==="
DEFCONFIG="$AOSP_DIR/kernel/samsung/exynos7870/arch/arm64/configs/exynos7870-gtaxllte_defconfig"

if [ ! -f "$DEFCONFIG" ]; then
    # Suche nach möglichem defconfig
    DEFCONFIG=$(find "$AOSP_DIR/kernel/samsung/exynos7870/arch/arm64/configs/" -name "*gtaxl*" 2>/dev/null | head -1)
    if [ -z "$DEFCONFIG" ]; then
        echo "  ⚠  Defconfig nicht gefunden"
        ls "$AOSP_DIR/kernel/samsung/exynos7870/arch/arm64/configs/" 2>/dev/null | head -10
    fi
fi

if [ -n "${DEFCONFIG:-}" ] && [ -f "$DEFCONFIG" ]; then
    echo "  Defconfig: $(basename $DEFCONFIG)"
    
    REQUIRED_CONFIGS=(
        "CONFIG_BPF=y"
        "CONFIG_BPF_SYSCALL=y"
        "CONFIG_USER_NS=y"
        "CONFIG_DEVTMPFS=y"
        "CONFIG_TMPFS=y"
    )
    
    for cfg in "${REQUIRED_CONFIGS[@]}"; do
        if grep -q "^${cfg}" "$DEFCONFIG" 2>/dev/null; then
            echo "    ✓ $cfg"
        else
            echo "    ⚠  $cfg FEHLT — könnte Bootprobleme verursachen"
        fi
    done
fi
echo ""

# ─── Schritt 4: Build-Vorbereitung prüfen ────────────────────────────────────
echo "=== Build-Vorbereitung ==="
echo ""

# Prüfe ob lunch target existiert
if [ -f "$AOSP_DIR/build/envsetup.sh" ]; then
    echo "✓ build/envsetup.sh vorhanden"
else
    echo "⚠  build/envsetup.sh fehlt — repo sync noch nicht fertig?"
fi

if [ -d "$AOSP_DIR/device/samsung/gtaxllte" ]; then
    echo "✓ device/samsung/gtaxllte vorhanden"
    # Suche nach AndroidProducts.mk
    if find "$AOSP_DIR/device/samsung/gtaxllte" -name "AndroidProducts.mk" | grep -q .; then
        echo "✓ AndroidProducts.mk gefunden"
        grep -r "PRODUCT_NAME" "$AOSP_DIR/device/samsung/gtaxllte/AndroidProducts.mk" 2>/dev/null | head -5
    fi
fi

echo ""
echo "════════════════════════════════════════════════════"
echo "  Patches abgeschlossen!"
echo "════════════════════════════════════════════════════"
echo ""
echo "Build-Befehle:"
echo "  cd ~/aosp"
echo "  source build/envsetup.sh"
echo "  lunch lineage_gtaxllte-userdebug"
echo "  mka bacon -j\$(nproc --all)"
