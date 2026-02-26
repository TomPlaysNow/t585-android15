#!/bin/bash
# =============================================================================
# do-build.sh — für WSL2 auf Windows (48 GB RAM, KEIN OOM-Problem!)
# In ~/aosp/ ablegen und mit: bash do-build.sh starten
# =============================================================================
set -e

AOSP_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="/tmp/t585-build.log"
JOBS=16   # 48 GB RAM → kann mehr Jobs parallel ausführen

echo "=== T585 Android 15 Build (WSL2 Windows) ==="
echo "AOSP: $AOSP_DIR"
echo "Log: $LOG"
echo ""

# ccache aktivieren
export USE_CCACHE=1
export CCACHE_DIR="$HOME/.ccache"
ccache -z 2>/dev/null || true

# Umgebung laden
cd "$AOSP_DIR"
source build/envsetup.sh
lunch lineage_gtaxllte-userdebug

echo "Build startet... (Log: $LOG)"
echo "Fortschritt anzeigen: tail -f $LOG"
echo ""

# Build ausführen — mit 48 GB RAM KEIN GOMEMLIMIT/NOGC nötig!
mka otapackage -j"$JOBS" 2>&1 | tee "$LOG"

BUILD_RESULT=${PIPESTATUS[0]}

if [ $BUILD_RESULT -eq 0 ]; then
  echo ""
  echo "=== BUILD ERFOLGREICH! ==="
  OTA=$(find "$AOSP_DIR/out/target/product/gtaxllte" -name "*lineage*.zip" 2>/dev/null | tail -1)
  if [ -n "$OTA" ]; then
    echo "OTA-Paket: $OTA"
    du -sh "$OTA"
  fi
else
  echo ""
  echo "=== BUILD FEHLGESCHLAGEN (Exit: $BUILD_RESULT) ==="
  echo "Letzte 50 Zeilen Log:"
  tail -50 "$LOG"
fi

exit $BUILD_RESULT
