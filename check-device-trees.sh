#!/bin/bash
# Git Credential Helper für GitHub in WSL2 einrichten
# + Device Trees und Verfügbarkeit prüfen

# gh token für git nutzen
git config --global credential.helper "$(which git-credential-manager 2>/dev/null || echo store)"
git config --global url."https://github.com/".insteadOf "git://github.com/"

# Ohne Passwort-Prompt prüfen
export GIT_TERMINAL_PROMPT=0

echo "=== Prüfe LineageOS Device Trees ==="
for repo in \
  android_device_samsung_gtaxllte \
  android_device_samsung_gtaxl-common \
  android_kernel_samsung_exynos7870 \
  android_vendor_samsung; do
  result=$(git ls-remote --heads "https://github.com/LineageOS/${repo}.git" 2>&1 | grep -E "lineage-2[0-9]" | awk '{print $2}' | sed 's|refs/heads/||' | tr '\n' ' ')
  if [ -n "$result" ]; then
    echo "OK  LineageOS/${repo}: $result"
  else
    echo "--- LineageOS/${repo}: nicht gefunden / privat"
  fi
done
