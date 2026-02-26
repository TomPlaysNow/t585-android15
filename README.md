# T585 Android 15 — Migration Mac → Windows 11 PC

## Übersicht

| Aspekt | Mac (aktuell) | Windows 11 PC (Ziel) |
|--------|--------------|----------------------|
| RAM | 16 GB (Docker: 14 GB) | **48 GB** — kein OOM! |
| Build-Umgebung | Docker (Rosetta x86-Emulation) | **WSL2 Native** (schneller) |
| Problem | OOM beim Ninja-Schreiben | Keines |
| AOSP Download | Bereits heruntergeladen | Neu herunterladen (~2-6 Std.) |

**Warum Neudownload statt USB-Stick?**
- Der Mac speichert AOSP auf einem APFS-formattierten Sparse-Image (`android-build.sparseimage`) — dieses Format **funktioniert auf Windows nicht**
- Der Patch-Bundle (alle 32 geänderten Dateien) ist nur wenige MB → problemlos transferierbar
- Ein frischer `repo sync` ist sauberer und vermeidet versteckte Probleme

---

## Schritt-für-Schritt-Anleitung

---

### Phase 1: Patch-Bundle auf dem Mac erstellen (5 Minuten)

```bash
# Im macOS Terminal:
bash "/Users/thoma/Samsung Android/t585-android15/migrate-to-windows/01_create_patch_bundle.sh"
```

Dies erstellt: `~/Desktop/t585-patches.tar.gz` (wenige MB)

**Patch-Bundle auf Windows übertragen** — wähle eine Option:
- Option A: **E-Mail / OneDrive / Google Drive** (empfohlen, wenige MB)
- Option B: **USB-Stick** (direkte Kopie, jedes Format geht weil die Datei FAT32-kompatibel ist)
- Option C: **LAN** (Mac-Terminal: `python3 -m http.server 8080 --directory ~/Desktop`, dann im Windows-Browser: `http://MAC-IP:8080`)

> **Tipp:** Mac-IP herausfinden: `ipconfig getifaddr en0`

---

### Phase 2: WSL2 auf Windows einrichten (10 Minuten)

**Im Windows PowerShell als Administrator:**

```powershell
# WSL2 mit Ubuntu 22.04 installieren
wsl --install -d Ubuntu-22.04

# Nach dem Neustart: Standard auf WSL2 setzen
wsl --set-default-version 2
```

**WSL2-Speicherlimit konfigurieren:**

Datei `C:\Users\DEIN_NAME\.wslconfig` erstellen (Notepad):
```ini
[wsl2]
memory=32GB
swap=8GB
processors=16
```
Kopiere dafür die Datei aus diesem Ordner: `02_wslconfig.txt`
→ Speichere sie als `.wslconfig` (OHNE .txt!) in `C:\Users\DEIN_NAME\`

**WSL2 Neustart:**
```powershell
wsl --shutdown
wsl
```

---

### Phase 3: AOSP herunterladen + Setup (2-8 Stunden)

**Im WSL2 Ubuntu-Terminal:**

```bash
# Patch-Bundle in WSL2 heimverzeichnis kopieren
# (aus Windows-Downloads: /mnt/c/Users/DEIN_NAME/Downloads/)
cp /mnt/c/Users/DEIN_NAME/Downloads/t585-patches.tar.gz ~/

# Setup-Script ausführen
bash /mnt/c/Users/thoma/Samsung\ Android/t585-android15/migrate-to-windows/03_wsl2_setup.sh
```

**ODER manuell (wenn Script nicht erreichbar):**

```bash
# 1. Pakete
sudo apt-get update && sudo apt-get install -y \
  git-core gnupg flex bison build-essential zip curl \
  zlib1g-dev libc6-dev-i386 libncurses5 x11proto-core-dev \
  libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils \
  xsltproc unzip fontconfig python3 python3-pip bc lzop \
  libssl-dev rsync ccache openjdk-17-jdk-headless lz4

# 2. repo Tool
mkdir -p ~/bin
curl -o ~/bin/repo https://storage.googleapis.com/git-repo-downloads/repo
chmod +x ~/bin/repo
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 3. AOSP herunterladen
mkdir -p ~/aosp && cd ~/aosp
repo init -u https://github.com/ProjectInfinityX/android.git -b fifteen --git-lfs --depth=1

# 4. local_manifest für gtaxllte
mkdir -p .repo/local_manifests
# (Inhalt aus 03_wsl2_setup.sh kopieren)

repo sync -j12 --no-clone-bundle --no-tags
```

---

### Phase 4: Patches anwenden (2 Minuten)

```bash
cd ~
tar -xzf t585-patches.tar.gz
bash ~/t585-patches/apply_patches.sh ~/aosp

# do-build.sh für WSL2 ebenfalls kopieren
cp /mnt/c/Users/thoma/Samsung\ Android/t585-android15/migrate-to-windows/do-build-wsl2.sh ~/aosp/do-build.sh
chmod +x ~/aosp/do-build.sh
```

---

### Phase 5: Build starten (3-8 Stunden)

```bash
cd ~/aosp
bash do-build.sh
```

**Fortschritt beobachten (zweites Terminal):**
```bash
tail -f /tmp/t585-build.log
```

---

## Erwartetes Ergebnis

Mit 48 GB RAM:
- **Soong-Analyse**: ~40-50 Minuten (wie Mac) ✅
- **Ninja-Datei schreiben**: Kein OOM mehr — braucht ~15 GB ✅
- **C++ Compilation**: ~2-5 Stunden mit 16 Threads ✅
- **OTA-Paket**: `out/target/product/gtaxllte/lineage-22.2-*-UNOFFICIAL-gtaxllte.zip`

---

## Häufige Fragen

### "Kann ich die 118 GB AOSP-Daten per USB-Stick übertragen?"
Nein — nicht direkt. Das APFS Sparse-Image des Macs ist unter Windows nicht lesbar.
Selbst eine normale FAT32/exFAT-Kopie würde wegen der Case-Sensitivity Probleme machen.
→ **Neudownload ist die sauberste Lösung.**

### "Kann ich LAN-Übertragung nutzen, um die 118 GB zu kopieren?"
Ja, wenn Mac und Windows-PC im selben Netzwerk sind:
```bash
# Im Mac Terminal (rsync direkt aus Docker):
docker exec t585-android15 tar -czf - /aosp \
  --exclude='/aosp/out' \
  --exclude='/aosp/.repo' | \
  ssh user@WINDOWS-WSL2-IP "cat > ~/aosp.tar.gz"
```
Bei GbE-Netzwerk: ~50 GB ohne `out/` → ca. 1-2 Stunden.
Aber: Repo-Sync ist einfacher und liefert saubereren Zustand.

### "WSL2 oder Docker auf Windows?"
**WSL2** ist besser:
- Kein Virtualisierungs-Overhead für den Container
- Direkter Zugriff auf alle 48 GB RAM (kein Helper-VM-Limit)
- Schnelleres Dateisystem (ext4 VHD)

### "Brauche ich andere Soong-Wrapper-Tricks?"
Nein! Mit 48 GB RAM brauchst du **kein** `GOMEMLIMIT`, `GOGC` oder `GOMAXPROCS`.
Einfach `mka otapackage -j16` — fertig.

---

## VSCode auf Windows für AOSP nutzen

Mit der Extension **Remote - WSL** kannst du den WSL2-AOSP-Ordner in VSCode öffnen:

1. Extension: `ms-vscode-remote.remote-wsl` installieren
2. In VSCode: `Strg+Shift+P` → "WSL: Open Folder in WSL..."
3. `/home/USERNAME/aosp` auswählen

Dann hast du dieselbe Entwicklungsumgebung wie auf dem Mac, aber mit 48 GB RAM.

---

## Checkliste

- [ ] `01_create_patch_bundle.sh` auf Mac ausführen
- [ ] `t585-patches.tar.gz` auf Windows übertragen
- [ ] `.wslconfig` mit 32GB memory erstellen
- [ ] WSL2 Ubuntu 22.04 installieren (`wsl --install -d Ubuntu-22.04`)
- [ ] `03_wsl2_setup.sh` in WSL2 ausführen (oder manuell)
- [ ] repo sync abwarten (2-8 Stunden)
- [ ] Patches anwenden (`apply_patches.sh`)
- [ ] `do-build.sh` kopieren und ausführen
- [ ] Build erfolgreich! OTA-zip auf T585 flashen
