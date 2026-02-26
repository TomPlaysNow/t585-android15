#!/usr/bin/env python3
"""
Erstellt den T585-Patch-Bundle auf dem Mac.
Ausführen: python3 create_patch_bundle.py
Ergebnis:  ~/Desktop/t585-patches.tar.gz
"""
import os, sys, shutil, tarfile, stat
from pathlib import Path

AOSP = Path("/Volumes/AndroidBuild/aosp")
DESK = Path.home() / "Desktop"
PATCH_DIR = DESK / "t585-patches"
OUTPUT    = DESK / "t585-patches.tar.gz"

# ---- Alle zu kopierenden Dateien ----------------------------------------
MODIFIED_FILES = [
    "packages/modules/Connectivity/staticlibs/Android.bp",
    "packages/modules/Connectivity/service/Android.bp",
    "packages/modules/Connectivity/service-t/Android.bp",
    "packages/modules/Connectivity/framework/Android.bp",
    "packages/modules/Connectivity/framework-t/Android.bp",
    "packages/modules/Connectivity/thread/service/Android.bp",
    "packages/modules/Connectivity/nearby/service/Android.bp",
    "packages/modules/Connectivity/networksecurity/service/Android.bp",
    "packages/modules/Connectivity/remoteauth/service/Android.bp",
    "packages/modules/Connectivity/tests/unit/Android.bp",
    "packages/modules/Connectivity/tests/common/Android.bp",
    "packages/modules/Connectivity/tools/Android.bp",
    "packages/modules/Connectivity/tests/cts/multidevices/Android.bp",
    "packages/modules/Connectivity/tests/cts/hostside/Android.bp",
    "packages/modules/Connectivity/tests/deflake/Android.bp",
    "packages/modules/Connectivity/staticlibs/testutils/Android.bp",
    "packages/modules/Connectivity/staticlibs/vcn-stub/Android.bp",  # neu erstellt
    "packages/modules/IPsec/Android.bp",
    "cts/tests/tests/vcn/Android.bp",
    "hardware/samsung_slsi-linaro/exynos/ssp/strongbox_keymint/strongbox_test/functional_vts/Android.bp",
    "hardware/samsung_slsi-linaro/exynos/ssp/strongbox_keymint/Android.bp",
    "hardware/samsung_slsi-linaro/exynos/ssp/wait_for_dual_keymint/Android.bp",
    "hardware/samsung_slsi-linaro/exynos/gralloc/gralloc1/Android.bp",
    "hardware/samsung_slsi-linaro/exynos/Android.bp",
    "hardware/samsung_slsi-linaro/graphics/Android.bp",
    "hardware/samsung/aidl/sensors/Android.bp",
    "hardware/samsung/hidl/powershare/Android.bp",
    "hardware/lineage/interfaces/touch/Android.bp",
    "hardware/lineage/interfaces/livedisplay/Android.bp",
    "vendor/infinity/prebuilt/common/Android.bp",
    "vendor/infinity/build/soong/generator/generator.go",
    "lineage-sdk/lib/Android.bp",
    "do-build.sh",
]

# Ganze Verzeichnisse (rekursiv)
NEW_DIRS = [
    "lineage-sdk/lib/src/java/org/lineageos/lib/phone/spn",
]

# ---- apply_patches.sh Inhalt ---------------------------------------------
APPLY_SCRIPT = r"""#!/bin/bash
# Patches auf frisches AOSP anwenden
# Aufruf: bash apply_patches.sh /pfad/zum/aosp (Standard: ~/aosp)
AOSP="${1:-$HOME/aosp}"
if [ ! -d "$AOSP/.repo" ]; then
  echo "FEHLER: $AOSP ist kein AOSP-Verzeichnis (.repo fehlt)"
  exit 1
fi
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FILES_DIR="$SCRIPT_DIR/files"
echo "=== Patches anwenden auf: $AOSP ==="
find "$FILES_DIR" -type f | while read src; do
  rel="${src#$FILES_DIR/}"
  dest="$AOSP/$rel"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "  Patch: $rel"
done
echo ""
echo "=== Fertig. Naechster Schritt: bash $AOSP/do-build.sh ==="
"""

# --------------------------------------------------------------------------
def copy_file(src: Path, dst: Path):
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    return True

def main():
    if not AOSP.exists():
        print(f"FEHLER: AOSP-Verzeichnis nicht gefunden: {AOSP}")
        print("Ist das Sparse-Image gemountet?")
        sys.exit(1)

    print(f"=== T585 Patch-Bundle erstellen ===")
    print(f"AOSP:    {AOSP}")
    print(f"Ausgabe: {OUTPUT}")
    print()

    # Altes Bundle löschen
    if PATCH_DIR.exists():
        shutil.rmtree(PATCH_DIR)
    PATCH_DIR.mkdir(parents=True)
    files_dir = PATCH_DIR / "files"
    files_dir.mkdir()

    ok, missing = 0, 0

    # Einzeldateien
    for rel in MODIFIED_FILES:
        src = AOSP / rel
        if src.is_file():
            copy_file(src, files_dir / rel)
            print(f"  OK:     {rel}")
            ok += 1
        else:
            print(f"  FEHLT:  {rel}")
            missing += 1

    # Verzeichnisse
    for rel in NEW_DIRS:
        src = AOSP / rel
        if src.is_dir():
            dst = files_dir / rel
            shutil.copytree(src, dst, dirs_exist_ok=True)
            count = sum(1 for _ in dst.rglob("*") if _.is_file())
            print(f"  OK dir: {rel} ({count} Dateien)")
            ok += count
        else:
            print(f"  FEHLT dir: {rel}")
            missing += 1

    # apply_patches.sh
    apply_script = PATCH_DIR / "apply_patches.sh"
    apply_script.write_text(APPLY_SCRIPT)
    apply_script.chmod(apply_script.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
    print(f"  OK:     apply_patches.sh")

    # tar.gz erstellen
    print(f"\nPaketiere → {OUTPUT}")
    with tarfile.open(OUTPUT, "w:gz") as tar:
        tar.add(PATCH_DIR, arcname="t585-patches")

    size_mb = OUTPUT.stat().st_size / 1024 / 1024
    print(f"\n=== FERTIG ===")
    print(f"Dateien OK:    {ok}")
    print(f"Dateien fehlen: {missing}")
    print(f"Archiv-Groesse: {size_mb:.1f} MB")
    print(f"Gespeichert:    {OUTPUT}")
    print()
    print("Naechster Schritt: t585-patches.tar.gz auf den Windows-PC uebertragen")
    print("(E-Mail / USB-Stick / OneDrive — Datei ist klein!)")

if __name__ == "__main__":
    main()
