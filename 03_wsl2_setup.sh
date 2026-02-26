#!/bin/bash
# =============================================================================
# Script 2: WSL2 Ubuntu einrichten + AOSP herunterladen + Patches anwenden
# AUSFÜHREN IN: WSL2 Ubuntu 22.04 (nach Windows-Installation)
# =============================================================================
set -e

# -----------------------------------------------------------------------
# KONFIGURATION — hier anpassen:
# -----------------------------------------------------------------------
AOSP_DIR="$HOME/aosp"           # Wo AOSP hin soll (mind. 200 GB Speicher)
JOBS=12                          # Gleichzeitige Download-Jobs (1/2 der CPU-Kerne)
MANIFEST_URL="https://github.com/ProjectInfinityX/android.git"
MANIFEST_BRANCH="fifteen"

# -----------------------------------------------------------------------
# 1) System-Pakete installieren
# -----------------------------------------------------------------------
echo "=== Schritt 1: System-Pakete installieren ==="
sudo apt-get update
sudo apt-get install -y \
  git-core gnupg flex bison build-essential zip curl \
  zlib1g-dev libc6-dev-i386 libncurses5 x11proto-core-dev \
  libx11-dev lib32z1-dev libgl1-mesa-dev \
  libxml2-utils xsltproc unzip fontconfig \
  python3 python3-pip python3-setuptools \
  bc lzop libssl-dev rsync openssh-client \
  ccache openjdk-17-jdk-headless \
  lz4 libncurses5-dev

echo "Java-Version:"
java -version 2>&1 | head -1

# -----------------------------------------------------------------------
# 2) repo-Tool installieren
# -----------------------------------------------------------------------
echo ""
echo "=== Schritt 2: repo-Tool installieren ==="
if ! command -v repo &>/dev/null; then
  mkdir -p "$HOME/bin"
  curl -o "$HOME/bin/repo" https://storage.googleapis.com/git-repo-downloads/repo
  chmod a+x "$HOME/bin/repo"
  echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
  export PATH="$HOME/bin:$PATH"
fi
echo "repo Version: $(repo --version 2>&1 | head -1)"

# -----------------------------------------------------------------------
# 3) Git konfigurieren
# -----------------------------------------------------------------------
echo ""
echo "=== Schritt 3: Git konfigurieren ==="
if [ -z "$(git config --global user.email)" ]; then
  read -p "Dein Git-Name (z.B. 'Max Mustermann'): " GIT_NAME
  read -p "Deine Git-E-Mail: " GIT_EMAIL
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
fi
git config --global color.ui true

# -----------------------------------------------------------------------
# 4) ccache aktivieren (beschleunigt Rebuilds stark)
# -----------------------------------------------------------------------
echo ""
echo "=== Schritt 4: ccache konfigurieren (15 GB Cache) ==="
ccache -M 15G
echo 'export USE_CCACHE=1' >> "$HOME/.bashrc"
echo 'export CCACHE_DIR="$HOME/.ccache"' >> "$HOME/.bashrc"
export USE_CCACHE=1
export CCACHE_DIR="$HOME/.ccache"

# -----------------------------------------------------------------------
# 5) AOSP herunterladen (dauert je nach Internet 2-8 Stunden!)
# -----------------------------------------------------------------------
echo ""
echo "=== Schritt 5: AOSP-Quellen herunterladen ==="
echo "Zielverzeichnis: $AOSP_DIR"
echo "Manifest: $MANIFEST_URL (Branch: $MANIFEST_BRANCH)"
echo "WARNUNG: Dies lädt ~80-120 GB herunter. Ca. 2-8 Stunden!"
echo ""
read -p "Weiter? (j/n): " CONFIRM
if [[ "$CONFIRM" != "j" && "$CONFIRM" != "J" ]]; then
  echo "Abgebrochen."
  exit 0
fi

mkdir -p "$AOSP_DIR"
cd "$AOSP_DIR"

repo init \
  -u "$MANIFEST_URL" \
  -b "$MANIFEST_BRANCH" \
  --git-lfs \
  --depth=1

# Device-Trees für gtaxllte hinzufügen (local_manifests)
mkdir -p .repo/local_manifests
cat > .repo/local_manifests/gtaxllte.xml << 'MANIFEST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <!-- Samsung SM-T585 (gtaxllte) Device Trees -->
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
MANIFEST_EOF

echo "Starte repo sync (kann Stunden dauern)..."
repo sync -j"$JOBS" --no-clone-bundle --no-tags --fail-fast

echo ""
echo "=== AOSP Download abgeschlossen ==="

# -----------------------------------------------------------------------
# 6) Patches anwenden
# -----------------------------------------------------------------------
echo ""
echo "=== Schritt 6: Patches anwenden ==="
PATCHES_TAR="$HOME/t585-patches.tar.gz"

if [ -f "$PATCHES_TAR" ]; then
  cd "$HOME"
  tar -xzf "$PATCHES_TAR"
  bash "$HOME/t585-patches/apply_patches.sh" "$AOSP_DIR"
else
  echo "HINWEIS: $PATCHES_TAR nicht gefunden."
  echo "Bitte die Datei t585-patches.tar.gz ins WSL2-Home-Verzeichnis kopieren."
  echo "Dann: bash ~/t585-patches/apply_patches.sh ~/aosp"
fi

# -----------------------------------------------------------------------
# 7) Finale Umgebungsvariablen
# -----------------------------------------------------------------------
cat >> "$HOME/.bashrc" << 'BASHRC_EOF'

# Android Build Umgebung
export ANDROID_BUILD_TOP="$HOME/aosp"
export USE_CCACHE=1
export CCACHE_DIR="$HOME/.ccache"
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

# Schnell in AOSP wechseln und Build starten
alias aosp='cd $HOME/aosp && source build/envsetup.sh && lunch lineage_gtaxllte-userdebug'
BASHRC_EOF

source "$HOME/.bashrc"

echo ""
echo "============================================================"
echo "=== WSL2-Setup ABGESCHLOSSEN! ==="
echo "============================================================"
echo ""
echo "Nächster Schritt — Build starten:"
echo "  cd ~/aosp"
echo "  bash do-build.sh"
echo ""
echo "Oder manuell:"
echo "  cd ~/aosp"
echo "  source build/envsetup.sh"
echo "  lunch lineage_gtaxllte-userdebug"
echo "  mka otapackage -j16"
echo ""
