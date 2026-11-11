#!/bin/sh
# Lanciato dal deploy come `servizi`: la cartella dei download, il comando che la riempie (ricevi-build) e le chiavi delle
# pipeline delle app, che con `restrict,command=` possono lanciare solo quello. Di authorized_keys si aggiunge la riga che
# manca: la chiave di questo deploy non si tocca.
set -eu
dir=$1
install -d -m 755 "$dir/downloads" "$dir/bin"
install -m 755 "$dir/app/ci/ricevi-build.sh" "$dir/bin/ricevi-build"
install -d -m 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
while IFS= read -r riga; do
    [ -n "$riga" ] || continue
    chiave=$(printf '%s' "$riga" | grep -o 'ssh-ed25519 [A-Za-z0-9+/=]*')
    grep -qF "$chiave" "$HOME/.ssh/authorized_keys" || printf '%s\n' "$riga" >> "$HOME/.ssh/authorized_keys"
done < "$dir/app/ci/chiavi-build.pub"
echo "download pronti in $dir/downloads"
