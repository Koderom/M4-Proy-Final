#!/usr/bin/env bash
# =====================================================================
# deploy.sh — Blue-Green Deployment para Spring Boot
#
# Arquitectura:
#
#                 ┌─────────────────────┐
#                 │       VM NGINX       │
#                 │                     │
# Cliente ───────►│ Nginx :80           │
#                 │                     │
#                 └──────────┬──────────┘
#                            │
#                            │ red interna
#                            ▼
#                 ┌─────────────────────┐
#                 │       VM APP         │
#                 │                     │
#                 │ BLUE  :8080         │
#                 │ GREEN :8081         │
#                 │                     │
#                 └─────────────────────┘
#
# Uso:
#   ./deploy.sh <version> <path-to-new-jar>
#
# Ejemplo:
#   ./deploy.sh v1.0.0 build/libs/m4-proy-final-0.0.1-SNAPSHOT.jar
#
# =====================================================================

set -euo pipefail

# ===============================================================
# CONFIGURACIÓN
# ===============================================================

APP_NAME="${APP_NAME:-m4-proy-final}"

# Directorio de la aplicación en VM APP
APP_DIR="${APP_DIR:-/home/osboxes/opt/m4-proy-final}"

JAVA_OPTS="${JAVA_OPTS:--Xms512m -Xmx1024m}"
SPRING_PROFILE="${SPRING_PROFILE:-prod}"

# Instancias Blue-Green
BLUE_PORT="${BLUE_PORT:-8080}"
GREEN_PORT="${GREEN_PORT:-8081}"

BLUE_JAR="${BLUE_JAR:-m4-proy-final-blue.jar}"
GREEN_JAR="${GREEN_JAR:-m4-proy-final-green.jar}"

# ===============================================================
# VM NGINX
# ===============================================================

# IP de la VM donde está Nginx
NGINX_HOST="${NGINX_HOST:-192.168.100.78}"

# Usuario SSH de la VM Nginx
NGINX_USER="${NGINX_USER:-osboxes}"

# Clave SSH (ubicada en la VM APP) para conectar a la VM NGINX
SSH_KEY="${SSH_KEY:-/home/osboxes/id_rsa_app_server}"

# Archivo que contiene el server activo (se incluye dentro del upstream).
# EXTENSIÓN .inc para que el glob conf.d/*.conf NO lo cargue a nivel http.
NGINX_CONF="${NGINX_CONF:-/etc/nginx/conf.d/bluegreen-active.inc}"

# Host de la VM donde corre Spring Boot
APP_HOST="${APP_HOST:-192.168.100.79}"

# ===============================================================
# HEALTH / E2E
# ===============================================================

HEALTH_RETRIES="${HEALTH_RETRIES:-20}"
HEALTH_SLEEP="${HEALTH_SLEEP:-3}"
STOP_TIMEOUT="${STOP_TIMEOUT:-15}"

INSTANCE_PATH="${INSTANCE_PATH:-/api/instance}"
HEALTH_PATH="${HEALTH_PATH:-/health}"
HELLO_PATH="${HELLO_PATH:-/api/hello}"
ROOT_PATH="${ROOT_PATH:-/}"

# ===============================================================
# ARGUMENTOS
# ===============================================================

APP_VERSION="${1:-}"
NEW_JAR_PATH="${2:-}"

# ===============================================================
# LOG
# ===============================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

ok() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $*"
}

warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ $*"
}

fail() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $*"
}

# ===============================================================
# 13. VALIDAR INFRAESTRUCTURA
# ===============================================================

validar_prerequisitos() {

    log "Validando infraestructura local..."

    if ! command -v java >/dev/null 2>&1; then
        fail "Java no está instalado."
        exit 1
    fi

    if ! command -v curl >/dev/null 2>&1; then
        fail "curl no está instalado."
        exit 1
    fi

    if ! command -v ssh >/dev/null 2>&1; then
        fail "ssh no está instalado."
        exit 1
    fi

    if [[ ! -d "$APP_DIR" ]]; then
        fail "No existe APP_DIR: $APP_DIR"
        exit 1
    fi

    if [[ ! -w "$APP_DIR" ]]; then
        fail "No hay permisos de escritura en $APP_DIR"
        exit 1
    fi

    log "Verificando conexión con VM Nginx..."

    if ! ssh -o BatchMode=yes \
            -o ConnectTimeout=5 \
            -i "$SSH_KEY" "$NGINX_USER@$NGINX_HOST" \
            "echo ok" >/dev/null 2>&1; then

        fail "No se puede conectar por SSH a $NGINX_USER@$NGINX_HOST"
        exit 1
    fi

    ok "Infraestructura validada."
}

# ===============================================================
# 14. IDENTIFICAR VERSION
# ===============================================================

identificar_version() {

    if [[ -z "$APP_VERSION" || -z "$NEW_JAR_PATH" ]]; then

        echo ""
        echo "Uso:"
        echo "  $0 <version> <path-to-new-jar>"
        echo ""
        echo "Ejemplo:"
        echo "  $0 v1.0.0 build/libs/m4-proy-final.jar"
        echo ""

        exit 1
    fi

    log "Versión a desplegar: $APP_VERSION"
}

# ===============================================================
# 14. OBTENER ARTEFACTO
# ===============================================================

obtener_artefacto() {

    log "Verificando artefacto..."

    if [[ ! -f "$NEW_JAR_PATH" ]]; then

        fail "No existe el JAR:"
        fail "$NEW_JAR_PATH"

        exit 1
    fi

    local size

    size=$(du -h "$NEW_JAR_PATH" | cut -f1)

    ok "Artefacto disponible:"
    ok "$(basename "$NEW_JAR_PATH") - $size"
}

# ===============================================================
# 14. PREPARAR AMBIENTE
# ===============================================================

preparar_ambiente() {

    log "Preparando ambiente..."

    mkdir -p "$APP_DIR/logs"
    mkdir -p "$APP_DIR/versions"

    if [[ ! -f "$APP_DIR/active-environment" ]]; then

        echo "blue" > "$APP_DIR/active-environment"

        log "No existía ambiente activo."
        log "Se inicializa BLUE."

    fi

    ok "Ambiente preparado."
}

# ===============================================================
# 15 / 16
# DETECTAR BLUE / GREEN
# ===============================================================

detectar_ambiente_activo() {

    ACTIVE=$(cat "$APP_DIR/active-environment")

    if [[ "$ACTIVE" != "blue" && "$ACTIVE" != "green" ]]; then

        warn "Estado desconocido: $ACTIVE"
        warn "Se utilizará BLUE."

        ACTIVE="blue"
    fi

    if [[ "$ACTIVE" == "blue" ]]; then

        TARGET="green"

        ACTIVE_PORT="$BLUE_PORT"
        TARGET_PORT="$GREEN_PORT"

        TARGET_JAR="$GREEN_JAR"

    else

        TARGET="blue"

        ACTIVE_PORT="$GREEN_PORT"
        TARGET_PORT="$BLUE_PORT"

        TARGET_JAR="$BLUE_JAR"

    fi

    log "=============================================="
    log "Blue-Green"
    log "=============================================="

    log "Ambiente activo : $(echo "$ACTIVE" | tr 'a-z' 'A-Z')"
    log "Puerto activo   : $ACTIVE_PORT"

    log "Ambiente target : $(echo "$TARGET" | tr 'a-z' 'A-Z')"
    log "Puerto target   : $TARGET_PORT"

    log "=============================================="
}

# ===============================================================
# DETENER TARGET ANTERIOR
#
# IMPORTANTE:
# NO se detiene el ambiente activo.
#
# Solamente se detiene la instancia que recibirá
# la nueva versión.
# ===============================================================

detener_target() {

    log "Deteniendo instancia anterior de $TARGET..."

    local pids

    pids=$(pgrep -f "$TARGET_JAR" || true)

    if [[ -z "$pids" ]]; then

        ok "No existe una instancia anterior de $TARGET."

        return 0
    fi

    for pid in $pids; do

        log "Deteniendo PID $pid"

        kill "$pid" 2>/dev/null || true

    done

    for i in $(seq 1 "$STOP_TIMEOUT"); do

        local running=false

        for pid in $pids; do

            if kill -0 "$pid" 2>/dev/null; then
                running=true
            fi

        done

        if [[ "$running" == false ]]; then

            ok "$TARGET detenido."

            return 0
        fi

        sleep 1

    done

    warn "La instancia no terminó normalmente."

    for pid in $pids; do

        kill -9 "$pid" 2>/dev/null || true

    done

    ok "$TARGET detenido forzosamente."
}

# ===============================================================
# BACKUP
# ===============================================================

backup_version() {

    if [[ -f "$APP_DIR/$TARGET_JAR" ]]; then

        local timestamp

        timestamp=$(date '+%Y%m%d%H%M%S')

        cp \
            "$APP_DIR/$TARGET_JAR" \
            "$APP_DIR/versions/${APP_NAME}-${TARGET}-${timestamp}.jar"

        ok "Backup creado."
    fi
}

# ===============================================================
# 14. INSTALAR NUEVA VERSION
# ===============================================================

instalar_nueva_version() {

    log "Instalando nueva versión en $TARGET..."

    backup_version

    cp \
        "$NEW_JAR_PATH" \
        "$APP_DIR/$TARGET_JAR"

    chmod 755 "$APP_DIR/$TARGET_JAR"

    ok "JAR instalado:"
    ok "$APP_DIR/$TARGET_JAR"
}

# ===============================================================
# 14. INICIAR INSTANCIA
# ===============================================================

iniciar_instancia() {

    log "Iniciando $TARGET en puerto $TARGET_PORT..."

    cd "$APP_DIR"

    # La aplicación identifica la instancia mediante la variable
    # de entorno APP_INSTANCE (BLUE/GREEN), no por puerto.
    local instance_upper
    instance_upper=$(echo "$TARGET" | tr 'a-z' 'A-Z')

    APP_INSTANCE="$instance_upper" nohup java $JAVA_OPTS \
        -jar "$TARGET_JAR" \
        --spring.profiles.active="$SPRING_PROFILE" \
        --server.port="$TARGET_PORT" \
        > "logs/app-${TARGET}.log" 2>&1 &

    TARGET_PID=$!

    echo "$TARGET_PID" > "$APP_DIR/${TARGET}.pid"

    ok "$TARGET iniciado."

    log "PID : $TARGET_PID"
    log "Puerto : $TARGET_PORT"
}

# ===============================================================
# 19. HEALTH CHECK
# ===============================================================

health_check() {

    log "Health Check de $TARGET..."

    local healthy=false

    for i in $(seq 1 "$HEALTH_RETRIES"); do

        if curl \
            -sf \
            "http://$APP_HOST:$TARGET_PORT$HEALTH_PATH" \
            >/dev/null 2>&1; then

            healthy=true

            ok "Health Check OK."
            ok "Instancia : $TARGET"
            ok "Puerto    : $TARGET_PORT"
            ok "Intento   : $i"

            break
        fi

        log "Esperando aplicación... intento $i/$HEALTH_RETRIES"

        sleep "$HEALTH_SLEEP"

    done

    if [[ "$healthy" != true ]]; then

        fail "Health Check FALLÓ."

        return 1
    fi

    return 0
}

# ===============================================================
# 20. E2E
# ===============================================================

run_e2e_tests() {

    log "Ejecutando pruebas E2E..."

    local base="http://$APP_HOST:$TARGET_PORT"

    local failed=0

    check_endpoint() {

        local path="$1"
        local expected="$2"

        local response

        response=$(curl -sf "$base$path" 2>/dev/null || true)

        if [[ -z "$response" ]]; then

            fail "E2E FALLÓ: $path"

            failed=1

            return
        fi

        if [[ -n "$expected" && "$response" != *"$expected"* ]]; then

            fail "E2E FALLÓ: respuesta inesperada en $path"
            fail "Respuesta: $response"

            failed=1

            return
        fi

        ok "E2E OK: $path"

    }

    check_endpoint "$ROOT_PATH" ""

    check_endpoint "$HEALTH_PATH" ""

    check_endpoint "$HELLO_PATH" "M4"

    check_endpoint \
        "$INSTANCE_PATH" \
        "$(echo "$TARGET" | tr 'a-z' 'A-Z')"

    if [[ "$failed" -ne 0 ]]; then

        fail "Las pruebas E2E FALLARON."

        return 1
    fi

    ok "Todas las pruebas E2E fueron exitosas."

    return 0
}

# ===============================================================
# SWITCH NGINX
# ===============================================================

switch_traffic() {

    log "=============================================="
    log "SWITCH DE TRAFICO"
    log "=============================================="

    log "Nginx VM : $NGINX_HOST"
    log "Destino  : $APP_HOST:$TARGET_PORT"

    local remote_command

    remote_command="
        set -e

        echo '[NGINX] Configurando tráfico hacia $APP_HOST:$TARGET_PORT'

        echo 'server $APP_HOST:$TARGET_PORT;' | sudo tee '$NGINX_CONF' >/dev/null

        echo '[NGINX] Validando configuración'

        sudo nginx -t

        echo '[NGINX] Recargando Nginx'

        sudo systemctl reload nginx

        echo '[NGINX] Switch completado'
    "

    if ssh \
        -o BatchMode=yes \
        -o ConnectTimeout=5 \
        -i "$SSH_KEY" \
        "$NGINX_USER@$NGINX_HOST" \
        "$remote_command"; then

        ok "Tráfico cambiado hacia $TARGET."

        TRAFFIC_SWITCHED=true

        return 0

    else

        fail "No se pudo realizar el switch de tráfico."

        return 1
    fi
}

# ===============================================================
# 18. TRAFFIC TEST
#
# Se ejecuta CONTRA NGINX.
# No contra localhost de VM APP.
# ===============================================================

verificar_trafico() {

    log "=============================================="
    log "VERIFICACIÓN DE TRÁFICO"
    log "=============================================="

    log "Realizando 20 solicitudes contra Nginx."

    local total=20
    local target_count=0

    for i in $(seq 1 "$total"); do

        local response

        response=$(curl -sf \
            "http://$NGINX_HOST$INSTANCE_PATH" \
            2>/dev/null || true)

        echo "Solicitud $i -> $response"

        if [[ "$response" == *"$(echo "$TARGET" | tr 'a-z' 'A-Z')"* ]]; then

            target_count=$((target_count + 1))

        fi

    done

    echo ""
    echo "----------------------------------------------"
    echo "Solicitudes totales : $total"
    echo "Respuestas target   : $target_count"
    echo "----------------------------------------------"

    if [[ "$target_count" -eq "$total" ]]; then

        ok "Todo el tráfico está llegando a $TARGET."

        return 0

    else

        warn "No todas las solicitudes llegaron a $TARGET."

        return 1
    fi
}

# ===============================================================
# ROLLBACK
# ===============================================================

rollback() {

    log "=============================================="
    log "ROLLBACK"
    log "=============================================="

    log "Ambiente anterior : $ACTIVE"
    log "Ambiente fallido  : $TARGET"

    # -----------------------------------------------------------
    # Si Nginx ya fue cambiado, devolverlo al ambiente anterior
    # -----------------------------------------------------------

    if [[ "${TRAFFIC_SWITCHED:-false}" == true ]]; then

        log "Restaurando tráfico hacia $ACTIVE..."

        local rollback_port

        if [[ "$ACTIVE" == "blue" ]]; then
            rollback_port="$BLUE_PORT"
        else
            rollback_port="$GREEN_PORT"
        fi

        local rollback_command="
            set -e

            echo 'server $APP_HOST:$rollback_port;' | sudo tee '$NGINX_CONF' >/dev/null

            sudo nginx -t

            sudo systemctl reload nginx
        "

        if ssh \
            -o BatchMode=yes \
            -o ConnectTimeout=5 \
            -i "$SSH_KEY" \
            "$NGINX_USER@$NGINX_HOST" \
            "$rollback_command"; then

            ok "Tráfico restaurado hacia $ACTIVE."

        else

            fail "ERROR CRÍTICO: no se pudo restaurar Nginx."

        fi
    fi

    # -----------------------------------------------------------
    # Detener instancia defectuosa
    # -----------------------------------------------------------

    if [[ -n "${TARGET_PID:-}" ]]; then

        if kill -0 "$TARGET_PID" 2>/dev/null; then

            log "Deteniendo $TARGET..."

            kill "$TARGET_PID" 2>/dev/null || true

            sleep 2

        fi
    fi

    ok "Rollback completado."

    log "Ambiente activo: $ACTIVE"
}

# ===============================================================
# RESULTADO
# ===============================================================

reportar_resultado() {

    echo ""

    echo "=============================================="
    echo "      DEPLOYMENT COMPLETADO"
    echo "=============================================="

    echo "Aplicación       : $APP_NAME"
    echo "Versión          : $APP_VERSION"

    echo "Ambiente activo  : $(echo "$TARGET" | tr 'a-z' 'A-Z')"

    echo "Puerto           : $TARGET_PORT"

    echo "VM APP           : $APP_HOST"

    echo "VM NGINX         : $NGINX_HOST"

    echo "JAR              : $TARGET_JAR"

    echo "Log              : $APP_DIR/logs/app-${TARGET}.log"

    echo "=============================================="

    echo "Tráfico:"
    echo "  Nginx :80"
    echo "     ↓"
    echo "  $APP_HOST:$TARGET_PORT"

    echo "=============================================="
}

# ===============================================================
# MAIN
# ===============================================================

main() {

    TRAFFIC_SWITCHED=false

    echo ""
    echo "=============================================="
    echo " BLUE-GREEN DEPLOYMENT"
    echo "=============================================="

    identificar_version

    validar_prerequisitos

    preparar_ambiente

    obtener_artefacto

    detectar_ambiente_activo

    # -----------------------------------------------------------
    # IMPORTANTE:
    # El ambiente ACTIVO nunca se toca durante el deployment.
    # -----------------------------------------------------------

    detener_target

    instalar_nueva_version

    iniciar_instancia

    # -----------------------------------------------------------
    # Health Check
    # -----------------------------------------------------------

    if ! health_check; then

        rollback

        exit 1
    fi

    # -----------------------------------------------------------
    # E2E
    # -----------------------------------------------------------

    if ! run_e2e_tests; then

        rollback

        exit 1
    fi

    # -----------------------------------------------------------
    # Switch Nginx
    # -----------------------------------------------------------

    if ! switch_traffic; then

        rollback

        exit 1
    fi

    # -----------------------------------------------------------
    # Verificar tráfico real
    # -----------------------------------------------------------

    if ! verificar_trafico; then

        warn "La verificación de tráfico falló."

        rollback

        exit 1
    fi

    # -----------------------------------------------------------
    # SOLO AHORA marcamos TARGET como activo.
    # -----------------------------------------------------------

    echo "$TARGET" > "$APP_DIR/active-environment"

    reportar_resultado
}

main "$@"