#!/bin/bash
# SSH Key generieren (falls noch nicht vorhanden)
if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "wsl2-to-mac"
  echo "=== Key erstellt ==="
else
  echo "=== Key existiert bereits ==="
fi

echo ""
echo "=== Public Key (auf Mac einfügen) ==="
cat ~/.ssh/id_rsa.pub
