#!/usr/bin/env bash
# integrate-device-trees.sh
# Integriert k9100ii Samsung Device Trees in den AOSP-Tree nach repo sync.
#
# Verwendung:
#   bash integrate-device-trees.sh
#
# Voraussetzungen:
#   - ~/k9100ii-gtaxllte-sources.tar.gz muss vorhanden sein
#   - ~/aosp/ muss via repo sync synchronisiert sein

set -euo pipefail

AOSP_DIR=~/aosp
ARCHIVE=~/k9100ii-gtaxllte-sources.tar.gz
EXTRACT_DIR=~/k9100ii-sources
PATCHES_DIR=~/aosp-patches

echo "════════════════════════════════════════════════════"
echo "  T585 / gtaxllte Device Tree Integration"
echo "════════════════════════════════════════════════════"
echo ""

# ── Schritt 1: k9100ii-Archiv prüfen ────────────────────────────────────────
echo "=== Schritt 1: k9100ii-Archiv prüfen ==="

if [ ! -f "$ARCHIVE" ]; then
    echo "FEHLER: $ARCHIVE nicht gefunden!"
    echo "Herunterladen mit:"
    echo "  curl -L -o ~/k9100ii-gtaxllte-sources.tar.gz \\"
    echo "    'https://xdaforums.com/attachments/gtaxl_lineage_source_archive-tar-gz.6210266/'"
    exit 1
fi

ARCHIVE_SIZE=$(stat -c%s "$ARCHIVE")
echo "Archiv: $ARCHIVE ($(($ARCHIVE_SIZE / 1024 / 1024)) MB)"

if [ "$ARCHIVE_SIZE" -lt 300000000 ]; then
    echo "WARNUNG: Archiv scheint unvollständig! (< 300 MB)"
fi

# SHA256 prüfen
EXPECTED_SHA256="20e558213749743a1d3f6ce47fc8aef4e8266c52188e8054b4def93a6cfa31b7"
echo "Prüfe SHA256..."
ACTUAL_SHA256=$(sha256sum "$ARCHIVE" | awk '{print $1}')
if [ "$ACTUAL_SHA256" = "$EXPECTED_SHA256" ]; then
    echo "✓ SHA256 korrekt"
else
    echo "WARNUNG: SHA256 stimmt nicht!"
    echo "  Erwartet: $EXPECTED_SHA256"
    echo "  Erhalten: $ACTUAL_SHA256"
    echo "Fortfahren trotzdem? (10s warten zum Abbrechen mit Ctrl+C)"
    sleep 10
fi
echo ""

# ── Schritt 2: Archiv extrahieren ───────────────────────────────────────────
echo "=== Schritt 2: Archiv extrahieren ==="

mkdir -p "$EXTRACT_DIR"

echo "Extrahiere nach $EXTRACT_DIR ..."
tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR" --strip-components=1 2>&1 | grep -v "LIBARCHIVE\|Removing leading"

echo "Inhalt des Archivs:"
ls -la "$EXTRACT_DIR/"
echo ""

# ── Schritt 3: Git-Repos aus Archiv finden ──────────────────────────────────
echo "=== Schritt 3: Verfügbare Git-Repos im Archiv ==="
find "$EXTRACT_DIR" -name "*.git" -type d -o -name "HEAD" -type f | head -30
echo ""

# Repos identifizieren
KERNEL_MIRROR=$(find "$EXTRACT_DIR" -name "*.git" -type d 2>/dev/null | grep -iE "kernel|exynos7870" | head -1)
DEVICE_MIRROR=$(find "$EXTRACT_DIR" -name "*.git" -type d 2>/dev/null | grep -iE "gtaxllte|device_samsung" | head -1)
COMMON_MIRROR=$(find "$EXTRACT_DIR" -name "*.git" -type d 2>/dev/null | grep -iE "exynos7870.common|gtaxl.common" | head -1)
VENDOR_MIRROR=$(find "$EXTRACT_DIR" -name "*.git" -type d 2>/dev/null | grep -iE "vendor|blobs" | head -1)

echo "Kernel-Mirror:  ${KERNEL_MIRROR:-NICHT GEFUNDEN}"
echo "Device-Mirror:  ${DEVICE_MIRROR:-NICHT GEFUNDEN}"
echo "Common-Mirror:  ${COMMON_MIRROR:-NICHT GEFUNDEN}"
echo "Vendor-Mirror:  ${VENDOR_MIRROR:-NICHT GEFUNDEN}"
echo ""

# ── Schritt 4: Repos in AOSP-Tree klonen ────────────────────────────────────
echo "=== Schritt 4: Device Trees in AOSP integrieren ==="

clone_repo() {
    local src="$1"
    local dst="$2"
    local name="$3"
    
    if [ -z "$src" ]; then
        echo "⚠ $name: Kein Mirror-Verzeichnis gefunden"
        return
    fi
    
    if [ -d "$dst/.git" ]; then
        echo "↻ $name: Existiert bereits, aktualisiere..."
        cd "$dst" && git pull 2>/dev/null && cd - > /dev/null
    else
        echo "→ Klone $name..."
        mkdir -p "$(dirname $dst)"
        git clone "$src" "$dst" 2>&1 | tail -3
        echo "✓ $name geklont: $dst"
    fi
}

clone_repo "$KERNEL_MIRROR"  "$AOSP_DIR/kernel/samsung/exynos7870"  "Kernel exynos7870"
clone_repo "$DEVICE_MIRROR"  "$AOSP_DIR/device/samsung/gtaxllte"    "Device gtaxllte"
clone_repo "$COMMON_MIRROR"  "$AOSP_DIR/device/samsung/exynos7870-common" "Device exynos7870-common"
clone_repo "$VENDOR_MIRROR"  "$AOSP_DIR/vendor/samsung/gtaxllte"    "Vendor Samsung gtaxllte"

echo ""

# ── Schritt 5: Verzeichnisse prüfen ─────────────────────────────────────────
echo "=== Schritt 5: Ergebnis prüfen ==="

for dir in \
    "$AOSP_DIR/kernel/samsung/exynos7870" \
    "$AOSP_DIR/device/samsung/gtaxllte" \
    "$AOSP_DIR/device/samsung/exynos7870-common" \
    "$AOSP_DIR/vendor/samsung/gtaxllte"
do
    if [ -d "$dir" ]; then
        echo "✓ $(ls $dir | wc -l) Dateien: $dir"
    else
        echo "✗ FEHLT: $dir"
    fi
done

echo ""

# ── Schritt 6: BPF-Patches anwenden ─────────────────────────────────────────
echo "=== Schritt 6: BPF-Patches anwenden ==="

if [ -d "$PATCHES_DIR" ]; then
    echo "Patches in $PATCHES_DIR:"
    ls "$PATCHES_DIR/"*.patch 2>/dev/null || echo "Keine Patch-Dateien"
    echo ""
    
    # system/bpf Patches
    BPF_DIR="$AOSP_DIR/system/bpf"
    if [ -d "$BPF_DIR" ]; then
        echo "Wende BPF-Patches auf $BPF_DIR an..."
        cd "$BPF_DIR"
        # Patches in Reihenfolge anwenden (0001 bis 0004)
        for patch in "$PATCHES_DIR"/000[1-4]*.patch; do
            if [ -f "$patch" ]; then
                echo "  → $(basename $patch)"
                git apply --check "$patch" 2>/dev/null && \
                    git apply "$patch" && echo "    ✓ angewendet" || \
                    echo "    ⚠ übersprungen (bereits angewendet oder Konflikt)"
            fi
        done
        cd - > /dev/null
    else
        echo "⚠ system/bpf nicht gefunden (repo sync noch nicht fertig?)"
    fi
    
    # netd Patches (0005)
    NETD_DIR="$AOSP_DIR/system/netd"
    if [ -d "$NETD_DIR" ] && ls "$PATCHES_DIR"/0005*.patch 2>/dev/null; then
        echo ""
        echo "Wende netd-Patches an..."
        cd "$NETD_DIR"
        for patch in "$PATCHES_DIR"/0005*.patch; do
            echo "  → $(basename $patch)"
            git apply --check "$patch" 2>/dev/null && \
                git apply "$patch" && echo "    ✓ angewendet" || \
                echo "    ⚠ übersprungen"
        done
        cd - > /dev/null
    fi
    
    # Connectivity Patch (0006) — liegt im packages/modules/Connectivity
    CONN_DIR="$AOSP_DIR/packages/modules/Connectivity"
    if [ -d "$CONN_DIR" ] && ls "$PATCHES_DIR"/0006*.patch 2>/dev/null; then
        echo ""
        echo "Wende Connectivity-Patches an..."
        cd "$CONN_DIR"
        for patch in "$PATCHES_DIR"/0006*.patch; do
            echo "  → $(basename $patch)"
            git apply --check "$patch" 2>/dev/null && \
                git apply "$patch" && echo "    ✓ angewendet" || \
                echo "    ⚠ übersprungen"
        done
        cd - > /dev/null
    fi
else
    echo "⚠ Patches-Verzeichnis nicht gefunden: $PATCHES_DIR"
fi

echo ""
echo "════════════════════════════════════════════════════"
echo "  Integration abgeschlossen!"
echo "════════════════════════════════════════════════════"
echo ""
echo "Nächste Schritte:"
echo "  1. Vendor-Blobs extrahieren:"
echo "     cd $AOSP_DIR/device/samsung/gtaxllte && bash extract-files.sh"
echo "     (Vanity OS Zip mounten: /mnt/c/Users/thoma/Samsung\ Android/Vanity\ OS\ Legacy\ 1.0\ -\ T585\ -\ 2-03-2025.zip)"
echo ""
echo "  2. Build vorbereiten:"
echo "     cd $AOSP_DIR"
echo "     source build/envsetup.sh"
echo "     lunch lineage_gtaxllte-user"
echo ""
echo "  3. Build starten:"
echo "     mka bacon -j8"
