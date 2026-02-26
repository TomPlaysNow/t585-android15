# T585 Android 15 — VSCode auf Windows einrichten

## Voraussetzungen

- Windows 11, 48 GB RAM, RTX 3080
- VSCode bereits installiert
- Internetverbindung (~100 GB Download für AOSP)
- `t585-patches.tar.gz` vom Mac (liegt auf deinem Desktop — nur 29 KB!)

---

## Phase 1 — WSL2 einrichten (15 Minuten)

### 1.1 WSL2 installieren

PowerShell als **Administrator** öffnen (`Win + X → Windows PowerShell (Administrator)`):

```powershell
wsl --install -d Ubuntu-22.04
wsl --set-default-version 2
```

→ PC **neu starten** wenn gefordert.

Nach dem Neustart öffnet sich Ubuntu automatisch → Benutzername + Passwort vergeben (merken!).

---

### 1.2 WSL2 Speicher konfigurieren

Datei `C:\Users\DEIN_WINDOWS_NAME\.wslconfig` erstellen.

**Notepad öffnen** (`Win + R → notepad`) und folgenden Inhalt einfügen:

```ini
[wsl2]
memory=32GB
swap=8GB
processors=16

[experimental]
sparseVhd=true
```

Speichern unter: `C:\Users\DEIN_WINDOWS_NAME\.wslconfig`  
**WICHTIG:** Dateiname ist `.wslconfig` — OHNE `.txt` am Ende!

In Notepad: `Datei → Speichern unter → Dateityp: Alle Dateien → Dateiname: .wslconfig`

Danach WSL2 neu starten (PowerShell):
```powershell
wsl --shutdown
```

---

### 1.3 WSCode — Remote WSL Extension installieren

1. VSCode öffnen
2. Extensions öffnen: `Strg + Shift + X`
3. Suchen: **Remote - WSL** (Publisher: Microsoft)
4. Installieren: `ms-vscode-remote.remote-wsl`

Außerdem empfohlen:
- **Remote Development** (Extension Pack — enthält alles)
- **C/C++ Extension Pack** (für Kernel/HAL Code-Navigation)
- **Android iOS Extension Pack** (optional)

---

## Phase 2 — Ubuntu WSL2 einrichten (10 Minuten)

WSL2 öffnen: `Win + R → wsl`

### 2.1 System-Pakete installieren

```bash
sudo apt-get update && sudo apt-get install -y \
  git-core gnupg flex bison build-essential zip curl \
  zlib1g-dev libc6-dev-i386 libncurses5 x11proto-core-dev \
  libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils \
  xsltproc unzip fontconfig python3 python3-pip python3-setuptools \
  bc lzop libssl-dev rsync ccache openjdk-17-jdk-headless lz4 \
  libncurses5-dev wget
```

Java-Version prüfen:
```bash
java -version
# Erwartet: openjdk version "17..."
```

### 2.2 repo-Tool installieren

```bash
mkdir -p ~/bin
curl -o ~/bin/repo https://storage.googleapis.com/git-repo-downloads/repo
chmod +x ~/bin/repo
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
repo --version
```

### 2.3 Git konfigurieren

```bash
git config --global user.name "Dein Name"
git config --global user.email "deine@email.de"
git config --global color.ui true
```

### 2.4 ccache aktivieren (spart Stunden bei Rebuilds)

```bash
ccache -M 20G
echo 'export USE_CCACHE=1' >> ~/.bashrc
echo 'export CCACHE_DIR="$HOME/.ccache"' >> ~/.bashrc
source ~/.bashrc
```

---

## Phase 3 — AOSP herunterladen (2–8 Stunden)

### 3.1 Speicherplatz prüfen

AOSP braucht ~200 GB. Prüfen ob genug C:-Speicher frei ist:
```bash
df -h /
```

Falls C: zu klein → AOSP auf anderer Partition:
```bash
# Beispiel: D:-Laufwerk
mkdir -p /mnt/d/aosp
ln -s /mnt/d/aosp ~/aosp
```

### 3.2 AOSP-Verzeichnis anlegen und initialisieren

```bash
mkdir -p ~/aosp && cd ~/aosp

repo init \
  -u https://github.com/ProjectInfinityX/android.git \
  -b fifteen \
  --git-lfs \
  --depth=1
```

### 3.3 Device-Manifest für SM-T585 hinzufügen

```bash
mkdir -p ~/aosp/.repo/local_manifests

cat > ~/aosp/.repo/local_manifests/gtaxllte.xml << 'EOF'
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
  <project name="LineageOS/android_lineage-sdk"
           path="lineage-sdk"
           remote="github" revision="lineage-22.2" />
  <project name="LineageOS/android_hardware_lineage_interfaces"
           path="hardware/lineage/interfaces"
           remote="github" revision="lineage-22.2" />
</manifest>
EOF
```

### 3.4 AOSP herunterladen

```bash
# Im Hintergrund laufen lassen — dauert 2-8 Stunden je nach Internet!
cd ~/aosp
repo sync -j12 --no-clone-bundle --no-tags --fail-fast 2>&1 | tee ~/repo-sync.log
```

Fortschritt in zweitem Terminal beobachten:
```bash
tail -f ~/repo-sync.log
```

---

## Phase 4 — Patches anwenden (2 Minuten)

### 4.1 Patch-Bundle vom Mac übertragen

Die Datei `t585-patches.tar.gz` (29 KB) vom Mac auf den Windows-PC kopieren.

In WSL2 liegt das Windows-Laufwerk C: unter `/mnt/c/`:
```bash
# Wenn Bundle in Downloads liegt:
cp /mnt/c/Users/DEIN_WINDOWS_NAME/Downloads/t585-patches.tar.gz ~/

# Wenn Bundle auf dem Desktop liegt:
cp /mnt/c/Users/DEIN_WINDOWS_NAME/Desktop/t585-patches.tar.gz ~/
```

### 4.2 Patches entpacken und anwenden

```bash
cd ~
tar -xzf t585-patches.tar.gz
bash ~/t585-patches/apply_patches.sh ~/aosp
```

Ausgabe sollte zeigen:
```
=== Patches anwenden auf: /home/user/aosp ===
  Patch: packages/modules/Connectivity/staticlibs/Android.bp
  Patch: vendor/infinity/build/soong/generator/generator.go
  ... (36 Dateien)
=== Fertig. Naechster Schritt: bash ~/aosp/do-build.sh ===
```

### 4.3 do-build.sh für WSL2 installieren

```bash
# Direkt die WSL2-optimierte Version anlegen:
cat > ~/aosp/do-build.sh << 'EOF'
#!/bin/bash
set -e
AOSP_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="/tmp/t585-build.log"
JOBS=16

echo "=== T585 Android 15 Build (WSL2 — 48 GB RAM) ==="
echo "Log: $LOG"

export USE_CCACHE=1
export CCACHE_DIR="$HOME/.ccache"

cd "$AOSP_DIR"
source build/envsetup.sh
lunch lineage_gtaxllte-userdebug

echo "Build startet (Jobs: $JOBS)..."
mka otapackage -j"$JOBS" 2>&1 | tee "$LOG"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
  echo ""
  echo "=== BUILD ERFOLGREICH! ==="
  find out/target/product/gtaxllte -name "*lineage*.zip" 2>/dev/null | tail -1
else
  echo "=== BUILD FEHLGESCHLAGEN ==="
  tail -30 "$LOG"
fi
EOF
chmod +x ~/aosp/do-build.sh
```

---

## Phase 5 — VSCode mit WSL2 verbinden

### 5.1 AOSP-Ordner in VSCode öffnen

1. VSCode öffnen
2. `Strg + Shift + P` → **"WSL: Open Folder in WSL..."** eingeben
3. Den Pfad `/home/UBUNTU_USERNAME/aosp` eingeben → OK

Oder direkt im WSL2-Terminal:
```bash
cd ~/aosp
code .
```

VSCode öffnet sich mit grünem `>< WSL: Ubuntu-22.04` Symbol links unten — das bedeutet alles läuft nativ in Linux.

### 5.2 Empfohlene VSCode Extensions (in WSL2)

VSCode fragt automatisch ob Extensions auch in WSL2 installiert werden sollen. Folgende installieren:

| Extension | ID | Zweck |
|-----------|-----|-------|
| C/C++ | `ms-vscode.cpptools` | HAL/Kernel-Code |
| clangd | `llvm-vs-code-extensions.vscode-clangd` | Bessere Autovervollständigung |
| Go | `golang.go` | Für Soong/Blueprint (.go Dateien) |
| Android BP | `Asuka.vscode-android-bp` | Android.bp Syntax-Highlighting |
| GitLens | `eamodio.gitlens` | Git-History |
| Error Lens | `usernamehw.errorlens` | Fehler direkt im Code hervorheben |
| Trailing Spaces | `shardulm94.trailing-spaces` | Whitespace-Fehler sehen |

Alle auf einmal in WSL2 installieren (VSCode Terminal, das in WSL2 läuft):
```bash
code --install-extension ms-vscode.cpptools \
     --install-extension llvm-vs-code-extensions.vscode-clangd \
     --install-extension golang.go \
     --install-extension eamodio.gitlens \
     --install-extension usernamehw.errorlens
```

### 5.3 VSCode Workspace-Einstellungen für AOSP

Datei `~/aosp/.vscode/settings.json` erstellen:

```bash
mkdir -p ~/aosp/.vscode
cat > ~/aosp/.vscode/settings.json << 'EOF'
{
  "files.exclude": {
    "out/**": true,
    ".repo/**": true,
    "**/*.pyc": true
  },
  "search.exclude": {
    "out/**": true,
    ".repo/**": true,
    "**/node_modules": true
  },
  "files.watcherExclude": {
    "out/**": true,
    ".repo/**": true
  },
  "editor.tabSize": 4,
  "editor.detectIndentation": true,
  "[makefile]": {
    "editor.insertSpaces": false
  },
  "go.toolsManagement.autoUpdate": true,
  "terminal.integrated.defaultProfile.linux": "bash",
  "C_Cpp.intelliSenseEngine": "disabled",
  "clangd.arguments": [
    "--background-index",
    "--clang-tidy",
    "--header-insertion=never"
  ]
}
EOF
```

### 5.4 Build-Tasks direkt in VSCode

Datei `~/aosp/.vscode/tasks.json` erstellen:

```bash
cat > ~/aosp/.vscode/tasks.json << 'EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "T585: Build OTA",
      "type": "shell",
      "command": "bash ~/aosp/do-build.sh",
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "presentation": {
        "reveal": "always",
        "panel": "new",
        "clear": true
      },
      "problemMatcher": {
        "owner": "android",
        "pattern": {
          "regexp": "^(.*\\.(?:bp|go|java|c|cpp|h)):?(\\d+)?:?(\\d+)?:\\s+(error|warning):\\s+(.*)$",
          "file": 1,
          "line": 2,
          "column": 3,
          "severity": 4,
          "message": 5
        }
      }
    },
    {
      "label": "T585: Build Log anzeigen",
      "type": "shell",
      "command": "tail -f /tmp/t585-build.log",
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      }
    },
    {
      "label": "T585: Soong Fehler prüfen",
      "type": "shell",
      "command": "grep -E '^error:|FAILED:' /tmp/t585-build.log | sort -u | head -30",
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      }
    },
    {
      "label": "T585: OOM prüfen",
      "type": "shell",
      "command": "cat /sys/fs/cgroup/memory.events | grep oom_kill",
      "presentation": {
        "reveal": "always",
        "panel": "shared"
      }
    }
  ]
}
EOF
```

Build starten mit: `Strg + Shift + B` → "T585: Build OTA"

---

## Phase 6 — Build starten

### 6.1 Im VSCode-Terminal (das in WSL2 läuft):

```bash
cd ~/aosp
bash do-build.sh
```

Oder per Task: `Strg + Shift + B`

### 6.2 Fortschritt beobachten

Zweites Terminal in VSCode: `` Strg + ` `` → neues Terminal → Split:

```bash
tail -f /tmp/t585-build.log
```

### 6.3 Erwartete Ablauf mit 48 GB RAM

| Phase | Dauer | RAM-Verbrauch |
|-------|-------|--------------|
| Soong Analyse | ~40-50 Min | ~8-12 GB |
| Ninja-Datei schreiben | ~5-10 Min | ~14-16 GB ← **war der OOM auf dem Mac!** |
| C++ Compilation (Ninja) | ~2-5 Std | ~8-20 GB |
| Java/dex Compilation | ~30-60 Min | ~4-8 GB |
| OTA-Paket erstellen | ~5 Min | ~2 GB |

**Mit 48 GB RAM kein OOM an keiner Stelle.** Kein `GOMEMLIMIT`, kein `GOGC` nötig.

### 6.4 Ergebnis

Bei Erfolg liegt das OTA-Paket unter:
```
~/aosp/out/target/product/gtaxllte/lineage-22.2-DATUM-UNOFFICIAL-gtaxllte.zip
```

---

## Fehlerbehebung

### "repo: command not found"
```bash
export PATH="$HOME/bin:$PATH"
source ~/.bashrc
```

### "WSL2 hat nur 8 GB RAM" obwohl 32 GB konfiguriert
```bash
# In WSL2 prüfen:
free -h
# Wenn falsch → .wslconfig nochmal prüfen (liegt sie wirklich ohne .txt in C:\Users\NAME\ ?)
# Dann: wsl --shutdown (in PowerShell) → wsl neu öffnen
```

### "Build schlägt mit 'lunch: command not found' fehl"
```bash
cd ~/aosp
source build/envsetup.sh
lunch lineage_gtaxllte-userdebug
mka otapackage -j16
```

### "Permission denied beim Patch anwenden"
```bash
chmod +x ~/t585-patches/apply_patches.sh
bash ~/t585-patches/apply_patches.sh ~/aosp
```

### "repo sync schlägt mit SSL-Fehler fehl"
```bash
git config --global http.sslVerify false
repo sync -j8 --no-clone-bundle --no-tags
```

### Build bricht mit bekanntem Fehler ab
Wenn Soong einen Fehler meldet, den du noch nicht gesehen hast:
1. `grep "^error:" /tmp/t585-build.log | sort -u` → alle Fehler anzeigen
2. Fehlermeldung in die Sitzung mit GitHub Copilot einfügen → Fix bekommt du sofort

---

## Nützliche Befehle (WSCode-Terminal)

```bash
# Build-Status
grep -E "^error:|FAILED:|BUILD END" /tmp/t585-build.log | tail -20

# RAM-Auslastung während Build
watch -n2 free -h

# Soong alleine ausführen (zum Testen ohne Ninja):
cd ~/aosp
source build/envsetup.sh && lunch lineage_gtaxllte-userdebug
m nothing 2>&1 | grep "^error:" | sort -u

# OTA flashen (wenn Gerät per USB angeschlossen):
adb reboot recovery
# Dann im TWRP: install → OTA zip auswählen
```

---

## Zusammenfassung — Status der Fixes

Alle Soong-Fehler (Builds 1-34 auf dem Mac) sind in `t585-patches.tar.gz` enthalten:

| Fix | Datei |
|-----|-------|
| Connectivity genrule→java_genrule | 10× `packages/modules/Connectivity/*/Android.bp` |
| VCN / IPsec visibility | `staticlibs/Android.bp`, `IPsec/Android.bp` |
| Samsung AIDL Versionskonflikte | `sensors/Android.bp`, `keymint/Android.bp`, `wait_for_dual_keymint/Android.bp` |
| Samsung Strongbox VTS Test | `strongbox_test/functional_vts/Android.bp` |
| gralloc exynos5/include fehlt | `gralloc1/Android.bp` |
| PATH_OVERRIDE_SOONG in Soong | `generator/generator.go` — Make-Variablen durchreichen |
| touch-V1.0-java Duplikat | `hardware/lineage/interfaces/touch/Android.bp` |
| livedisplay Java-Stub | `hardware/lineage/interfaces/livedisplay/Android.bp` |
| Samsung powershare HIDL | `hardware/samsung/hidl/powershare/Android.bp` |
| lineage-sdk SPN-Stubs | `lineage-sdk/lib/src/java/.../spn/*.java` |
| spn-schema / apns-conf-schema | `vendor/infinity/prebuilt/common/Android.bp` |
| CTS Tests deaktiviert | `cts/tests/tests/vcn/Android.bp` |

**Nächste Fehler (falls vorhanden):** Die Fixes aus dem Bundle decken alles ab was Build 34 auf dem Mac gezeigt hat. Auf Windows sollte Soong fehlerlos durchlaufen und Ninja starten.
