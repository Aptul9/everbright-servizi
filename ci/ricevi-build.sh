#!/bin/sh
# Comando forzato della chiave delle pipeline delle app (authorized_keys di `servizi`): riceve uno ZIP su stdin e lo mette tra i
# download. SSH_ORIGINAL_COMMAND = "<nome>.zip <sha256>". Il file arriva intero e col suo hash, oppure resta quello di prima.
set -euf
# RICEVI_DIR solo per la prova in CI: il client SSH non può impostarla (restrict, niente PermitUserEnvironment)
dir=${RICEVI_DIR:-/opt/servizi/downloads}
set -- ${SSH_ORIGINAL_COMMAND:-}
[ "$#" -eq 2 ] || { echo "uso: <nome>.zip <sha256>" >&2; exit 2; }
nome=$1 hash=$2
printf '%s' "$nome" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]{0,80}\.zip$' || { echo "nome non valido" >&2; exit 2; }
printf '%s' "$hash" | grep -Eq '^[0-9a-f]{64}$' || { echo "sha256 non valido" >&2; exit 2; }
mkdir -p "$dir"
tmp=$(mktemp "$dir/.arrivo.XXXXXX")
trap 'rm -f "$tmp"' EXIT
head -c 314572800 > "$tmp"
echo "$hash  $tmp" | sha256sum -c --status || { echo "sha256 diverso: file scartato" >&2; exit 1; }
chmod 644 "$tmp"
mv -f "$tmp" "$dir/$nome"
trap - EXIT
echo "$dir/$nome $(wc -c < "$dir/$nome") byte"
