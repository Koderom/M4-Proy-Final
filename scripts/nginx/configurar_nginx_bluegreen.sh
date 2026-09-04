#!/usr/bin/env bash
set -e

# Script de infraestructura: configura la VM NGINX para blue-green.
# Se ejecuta UNA vez desde la VM Nginx (192.168.100.78).
# Requiere: sudo NOPASSWD configurado para nginx/systemctl
#           (o ejecutar con sudo interactivo).
#
# Deposita el estado inicial: BLUE activo en :8080.

NGINX_HOST="192.168.100.78"
APP_HOST="192.168.100.79"
ACTIVE_PORT="8080"

echo "=============================================="
echo " Configurar Nginx Blue-Green"
echo " VM NGINX : $NGINX_HOST"
echo " APP HOST : $APP_HOST"
echo "=============================================="

# ------------------------------------------------------------------
# 1) Configurar sudo NOPASSWD para los comandos de nginx
# ------------------------------------------------------------------
echo "--- 1) sudo NOPASSWD para nginx ---"
SUDOERS_FILE="/etc/sudoers.d/nginx-bluegreen"
LINE='osboxes ALL=(ALL) NOPASSWD: /usr/bin/tee, /usr/sbin/nginx, /usr/bin/systemctl reload nginx, /usr/bin/systemctl restart nginx, /usr/bin/cat, /usr/bin/chmod'

if sudo -n cat "$SUDOERS_FILE" 2>/dev/null | grep -q "NOPASSWD"; then
    echo "   sudoers ya configurado."
else
    printf '%s\n' "$LINE" | sudo tee "$SUDOERS_FILE" >/dev/null
    sudo chmod 440 "$SUDOERS_FILE"
    echo "   sudoers escrito: $SUDOERS_FILE"
fi

# ------------------------------------------------------------------
# 2) Crear el archivo include con el server activo (BLUE :8080)
#    Usa extensión .inc para que conf.d/*.conf NO lo cargue a nivel http
# ------------------------------------------------------------------
echo "--- 2) Si no existe, inicializar bluegreen-active.inc ---"
INCLUDE_CONF="/etc/nginx/conf.d/bluegreen-active.inc"
if [[ ! -s "$INCLUDE_CONF" ]]; then
    printf 'server %s:%s;\n' "$APP_HOST" "$ACTIVE_PORT" | sudo tee "$INCLUDE_CONF" >/dev/null
fi
echo "   Contenido actual de $INCLUDE_CONF:"
cat "$INCLUDE_CONF"

# ------------------------------------------------------------------
# 3) Verificar / reescribir springboot-lb.conf con include
# ------------------------------------------------------------------
echo "--- 3) springboot-lb.conf usa include ---"
LB_CONF="/etc/nginx/conf.d/springboot-lb.conf"
NEW_LB_CONF='upstream springboot_backend {
    least_conn;

    # El server activo lo define deploy.sh en bluegreen-active.inc
    include /etc/nginx/conf.d/bluegreen-active.inc;
}

server {
    listen 80;
    server_name '"$NGINX_HOST"';

    location / {
        proxy_pass http://springboot_backend;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 5s;
        proxy_read_timeout 30s;
    }
}
'
printf '%s\n' "$NEW_LB_CONF" | sudo tee "$LB_CONF" >/dev/null
echo "   $LB_CONF actualizado."

# ------------------------------------------------------------------
# 3b) Vaciar el archivo .conf obsoleto (si existe) para que el glob
#     conf.d/*.conf no lo cargue a nivel http y no rompa nginx.
# ------------------------------------------------------------------
OLD_CONF="/etc/nginx/conf.d/bluegreen-active.conf"
if [[ -s "$OLD_CONF" ]]; then
    echo "--- 3b) Vaciando $OLD_CONF obsoleto ---"
    printf '' | sudo tee "$OLD_CONF" >/dev/null
fi

# ------------------------------------------------------------------
# 4) Validar y recargar
# ------------------------------------------------------------------
echo "--- 4) Validar y recargar nginx ---"
sudo nginx -t
sudo systemctl reload nginx
echo "   nginx OK."

echo "=============================================="
echo " Nginx configurado. BLUE activo en :$ACTIVE_PORT"
echo "=============================================="
