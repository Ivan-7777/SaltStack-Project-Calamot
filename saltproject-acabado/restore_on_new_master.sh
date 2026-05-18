#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "ERROR: ejecuta este script como root en el Salt master." >&2
  exit 1
fi

backup_path() {
  local path="$1"
  if [[ -e "$path" ]]; then
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    mv "$path" "${path}.bak-${stamp}"
    echo "Backup creado: ${path}.bak-${stamp}"
  fi
}

mkdir -p /srv /var/www

backup_path /srv/salt
backup_path /srv/pillar

cp -a "${BASE_DIR}/srv/salt" /srv/salt
cp -a "${BASE_DIR}/srv/pillar" /srv/pillar

if [[ -d "${BASE_DIR}/var/www/html" ]]; then
  mkdir -p /var/www
  backup_path /var/www/html
  cp -a "${BASE_DIR}/var/www/html" /var/www/html
fi

if [[ -d "${BASE_DIR}/Scripts" ]]; then
  mkdir -p /srv/salt
  cp -a "${BASE_DIR}/Scripts" /srv/salt/Scripts
fi

chmod -R root:root /srv/salt /srv/pillar
find /srv/salt -type f -name "*.sh" -exec chmod +x {} \;
find /srv/salt/Scripts -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

echo "Restauracion completada."
echo "Siguientes comprobaciones recomendadas:"
echo "  salt '*' saltutil.refresh_pillar"
echo "  salt '*' test.ping"
echo "  salt '*' state.apply test=True"
