#!/usr/bin/env bash
set -e

# Orquestador: se ejecuta en la VM APP (192.168.100.79)
# y configura la VM NGINX (192.168.100.78) por SSH remoto.

NGINX="osboxes@192.168.100.78"
KEY="/home/osboxes/id_rsa_app_server"
SUDO_PASS="osboxes.org"

echo "=== Configurando sudo NOPASSWD nginx en VM NGINX ==="

REMOTE=$(cat <<'REMOTE'
set -e
SUDO_PASS="osboxes.org"
LINE='osboxes ALL=(ALL) NOPASSWD: /usr/bin/tee, /usr/sbin/nginx, /usr/bin/systemctl reload nginx, /usr/bin/systemctl restart nginx, /usr/bin/cat, /usr/bin/chmod'
# Escribir el archivo por redirección shell (sin conflicto de stdin con sudo -S)
echo "$SUDO_PASS" | sudo -S sh -c "printf '%s\n' \"$LINE\" > /etc/sudoers.d/nginx-bluegreen" 2>/dev/null
echo "$SUDO_PASS" | sudo -S chmod 440 /etc/sudoers.d/nginx-bluegreen 2>/dev/null
echo "Contenido del archivo:"
sudo cat /etc/sudoers.d/nginx-bluegreen
echo "Validacion:"
sudo visudo -c -f /etc/sudoers.d/nginx-bluegreen
REMOTE
)

ssh -i "$KEY" -o BatchMode=yes "$NGINX" "bash -s" <<< "$REMOTE"
echo "=== FIN configuracion sudoers ==="
