#!/usr/bin/env bash
# Corre el VAR en la VM APP (orquesta a la VM NGINX)
# Escribe de forma verificable el sudoers NOPASSWD y confirma.
set -e

NGINX="osboxes@192.168.100.78"
KEY="/home/osboxes/id_rsa_app_server"
SUDO_PASS="osboxes.org"

LINE='osboxes ALL=(ALL) NOPASSWD: /usr/bin/tee, /usr/sbin/nginx, /usr/bin/systemctl reload nginx, /usr/bin/systemctl restart nginx, /usr/bin/cat, /usr/bin/chmod'

echo "=== Escribiendo sudoers NOPASSWD en VM NGINX ==="

ssh -i "$KEY" -o BatchMode=yes "$NGINX" "bash -s" <<INNER
set -e
PASS='$SUDO_PASS'
L='$LINE'
echo "\$PASS" | sudo -S sh -c "printf '%s\\n' \"\$L\" > /etc/sudoers.d/nginx-bluegreen" 2>/dev/null
echo "\$PASS" | sudo -S chmod 440 /etc/sudoers.d/nginx-bluegreen 2>/dev/null
echo "--- tamaño ---"
ls -la /etc/sudoers.d/nginx-bluegreen
echo "--- contenido ---"
sudo cat /etc/sudoers.d/nginx-bluegreen
echo "--- validación ---"
sudo visudo -c -f /etc/sudoers.d/nginx-bluegreen
echo "--- prueba sudo -n cat (debe funcionar sin password) ---"
sudo -n cat /etc/sudoers.d/nginx-bluegreen
INNER

echo "=== FIN ==="
