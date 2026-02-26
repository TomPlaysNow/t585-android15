#!/usr/bin/env bash
# Kopiert gtaxllte.xml vom Mac und startet k9100ii-Download

set -e

echo "=== Local Manifest vom Mac kopieren ==="
ssh thoma@192.168.188.166 "cat '/Users/thoma/Samsung Android/t585-android15/manifest/local_manifests/gtaxllte.xml'" > ~/aosp/.repo/local_manifests/gtaxllte.xml
echo "OK: gtaxllte.xml ersetzt"
head -5 ~/aosp/.repo/local_manifests/gtaxllte.xml

echo ""
echo "=== k9100ii-Archiv Download starten (374 MB) ==="
ARCHIVE_FILE=~/k9100ii-gtaxllte-sources.tar.gz
if [ -f "$ARCHIVE_FILE" ]; then
    echo "Archiv bereits vorhanden: $ARCHIVE_FILE"
    ls -lh "$ARCHIVE_FILE"
else
    echo "Starte Download von XDA..."
    curl -L \
        --retry 5 \
        --retry-delay 10 \
        --progress-bar \
        -o "$ARCHIVE_FILE" \
        'https://xdaforums.com/attachments/gtaxl_lineage_source_archive-tar-gz.6210266/' &
    echo "Download läuft im Hintergrund (PID: $!)"
    echo $! > ~/k9100ii-download.pid
fi

echo ""
echo "=== Patch-Dateien vom Mac kopieren ==="
mkdir -p ~/aosp-patches
ssh thoma@192.168.188.166 "tar -czf - '/Users/thoma/Samsung Android/t585-android15/patches/'" | tar -xzf - -C ~/aosp-patches --strip-components=5
echo "Patches kopiert:"
ls ~/aosp-patches/

echo ""
echo "=== Bereit für repo sync ==="
echo "Starte jetzt: cd ~/aosp && ~/bin/repo sync -j8 --current-branch --no-tags --force-sync"
