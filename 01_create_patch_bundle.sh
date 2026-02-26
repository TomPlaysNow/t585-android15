#!/bin/bash
# =============================================================================
# Script 1: Patch-Bundle auf dem MAC erstellen
# Ausführen auf: macOS (im AOSP-Verzeichnis)
# Ausgabe: ~/Desktop/t585-patches.tar.gz (~wenige MB)
# =============================================================================
set -e

AOSP="/Volumes/AndroidBuild/aosp"
PATCH_DIR="$HOME/Desktop/t585-patches"
OUTPUT="$HOME/Desktop/t585-patches.tar.gz"

echo "=== T585 Android 15 Patch-Bundle erstellen ==="
rm -rf "$PATCH_DIR"
mkdir -p "$PATCH_DIR/files"

cd "$AOSP"

# -----------------------------------------------------------------------
# 1) Alle modifizierten Einzeldateien kopieren (Verzeichnisstruktur behalten)
# -----------------------------------------------------------------------
MODIFIED_FILES=(
  "packages/modules/Connectivity/staticlibs/Android.bp"
  "packages/modules/Connectivity/service/Android.bp"
  "packages/modules/Connectivity/service-t/Android.bp"
  "packages/modules/Connectivity/framework/Android.bp"
  "packages/modules/Connectivity/framework-t/Android.bp"
  "packages/modules/Connectivity/thread/service/Android.bp"
  "packages/modules/Connectivity/nearby/service/Android.bp"
  "packages/modules/Connectivity/networksecurity/service/Android.bp"
  "packages/modules/Connectivity/remoteauth/service/Android.bp"
  "packages/modules/Connectivity/tests/unit/Android.bp"
  "packages/modules/Connectivity/tests/common/Android.bp"
  "packages/modules/Connectivity/tools/Android.bp"
  "packages/modules/Connectivity/tests/cts/multidevices/Android.bp"
  "packages/modules/Connectivity/tests/cts/hostside/Android.bp"
  "packages/modules/Connectivity/tests/deflake/Android.bp"
  "packages/modules/Connectivity/staticlibs/testutils/Android.bp"
  "packages/modules/IPsec/Android.bp"
  "cts/tests/tests/vcn/Android.bp"
  "hardware/samsung_slsi-linaro/exynos/ssp/strongbox_keymint/strongbox_test/functional_vts/Android.bp"
  "hardware/samsung_slsi-linaro/exynos/ssp/strongbox_keymint/Android.bp"
  "hardware/samsung_slsi-linaro/exynos/ssp/wait_for_dual_keymint/Android.bp"
  "hardware/samsung_slsi-linaro/exynos/gralloc/gralloc1/Android.bp"
  "hardware/samsung_slsi-linaro/exynos/Android.bp"
  "hardware/samsung_slsi-linaro/graphics/Android.bp"
  "hardware/samsung/aidl/sensors/Android.bp"
  "hardware/samsung/hidl/powershare/Android.bp"
  "hardware/lineage/interfaces/touch/Android.bp"
  "hardware/lineage/interfaces/livedisplay/Android.bp"
  "vendor/infinity/prebuilt/common/Android.bp"
  "vendor/infinity/build/soong/generator/generator.go"
  "do-build.sh"
)

echo "Kopiere modifizierte Dateien..."
for f in "${MODIFIED_FILES[@]}"; do
  if [ -f "$AOSP/$f" ]; then
    dest="$PATCH_DIR/files/$f"
    mkdir -p "$(dirname "$dest")"
    cp "$AOSP/$f" "$dest"
    echo "  OK: $f"
  else
    echo "  FEHLT: $f"
  fi
done

# -----------------------------------------------------------------------
# 2) Neu erstellte Verzeichnisse/Dateien komplett kopieren
# -----------------------------------------------------------------------
NEW_DIRS=(
  "hardware/lineage/interfaces/touch"          # touch/Android.bp (leer-stub)
  "hardware/lineage/interfaces/livedisplay"     # livedisplay/Android.bp
  "hardware/samsung_slsi-linaro/graphics"       # falls neu
  "lineage-sdk/lib/Android.bp"
  "lineage-sdk/lib/src/java/org/lineageos/lib/phone/spn"
)

echo "Kopiere neue Verzeichnisse..."
for d in "${NEW_DIRS[@]}"; do
  if [ -d "$AOSP/$d" ]; then
    mkdir -p "$PATCH_DIR/files/$d"
    cp -r "$AOSP/$d/." "$PATCH_DIR/files/$d/"
    echo "  OK dir: $d"
  elif [ -f "$AOSP/$d" ]; then
    mkdir -p "$(dirname "$PATCH_DIR/files/$d")"
    cp "$AOSP/$d" "$PATCH_DIR/files/$d"
    echo "  OK file: $d"
  fi
done

# lineage-sdk spn stubs komplett
if [ -d "$AOSP/lineage-sdk/lib/src/java/org/lineageos/lib/phone/spn" ]; then
  SPN_DEST="$PATCH_DIR/files/lineage-sdk/lib/src/java/org/lineageos/lib/phone/spn"
  mkdir -p "$SPN_DEST"
  cp "$AOSP/lineage-sdk/lib/src/java/org/lineageos/lib/phone/spn/"*.java "$SPN_DEST/" 2>/dev/null || true
fi

# lineage-sdk selbst (nur die geänderte lib/Android.bp)
if [ -f "$AOSP/lineage-sdk/lib/Android.bp" ]; then
  mkdir -p "$PATCH_DIR/files/lineage-sdk/lib"
  cp "$AOSP/lineage-sdk/lib/Android.bp" "$PATCH_DIR/files/lineage-sdk/lib/"
fi

# -----------------------------------------------------------------------
# 3) Installations-Script mit einbündeln
# -----------------------------------------------------------------------
cat > "$PATCH_DIR/apply_patches.sh" << 'APPLY_EOF'
#!/bin/bash
# Dieses Script auf dem Windows-PC in WSL2 ausführen
# Voraussetzung: AOSP wurde bereits per repo sync heruntergeladen
# Aufruf: bash apply_patches.sh /pfad/zum/aosp

AOSP="${1:-$HOME/aosp}"

if [ ! -d "$AOSP/.repo" ]; then
  echo "FEHLER: $AOSP ist kein AOSP-Verzeichnis (kein .repo gefunden)"
  echo "Bitte angeben: bash apply_patches.sh /pfad/zum/aosp"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FILES_DIR="$SCRIPT_DIR/files"

echo "=== Wende Patches an auf: $AOSP ==="

# Alle Dateien aus files/ in AOSP kopieren
find "$FILES_DIR" -type f | while read src; do
  rel="${src#$FILES_DIR/}"
  dest="$AOSP/$rel"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "  Patch: $rel"
done

echo ""
echo "=== Alle Patches angewendet ==="
echo "Nächster Schritt: bash $AOSP/do-build.sh"
APPLY_EOF
chmod +x "$PATCH_DIR/apply_patches.sh"

# -----------------------------------------------------------------------
# 4) Archiv erstellen
# -----------------------------------------------------------------------
echo ""
echo "Erstelle Archiv: $OUTPUT"
tar -czf "$OUTPUT" -C "$HOME/Desktop" "t585-patches"
echo ""
echo "=== FERTIG ==="
echo "Archiv: $OUTPUT"
du -sh "$OUTPUT"
echo ""
echo "Nächster Schritt: t585-patches.tar.gz auf Windows übertragen"
echo "(E-Mail, USB-Stick, AirDrop, oder Netzlaufwerk)"
