# DEPLOY.md

Guía de despliegue del proyecto **m4-proy-final** mediante una estrategia **Blue-Green** sobre dos máquinas virtuales Ubuntu, con Nginx como balanceador de carga.

Este documento describe los comandos y configuraciones necesarios para desplegar la aplicación y para **replicar el proceso en otros entornos** (otra PC, otras VMs).

---

## 1. Arquitectura

```
                         CLIENTE
                           │
                           ▼
        ┌──────────────────────────────────┐
        │       VM NGINX  (192.168.100.78) │
        │       Nginx :80                  │
        │       upstream -> include        │
        └──────────────┬───────────────────┘
                       │ red interna
                       ▼
        ┌──────────────────────────────────┐
        │       VM APP   (192.168.100.79)  │
        │       BLUE  :8080                │
        │       GREEN :8081                │
        └──────────────────────────────────┘
```

- **VM APP**: ejecuta las instancias de Spring Boot (BLUE/GREEN) y corre el script `deploy.sh`.
- **VM NGINX**: recibe el tráfico en `:80` y lo reenvía a la instancia activa de la VM APP.
- La instancia activa se define en un archivo `include` que Nginx lee dentro del upstream.

---

## 2. Tecnologías y versiones

| Componente | Versión |
|-----------|---------|
| OS | Ubuntu (VM) |
| Java | OpenJDK 17 |
| Spring Boot | 4.1.0 |
| Nginx | 1.18+ |
| Gradle | 9.5.1 (wrapper) |
| SSH | OpenSSH |

---

## 3. Datos del entorno de referencia

| Rol | IP | Usuario | Clave SSH |
|-----|-----|---------|-----------|
| VM APP | `192.168.100.79` | `osboxes` | (acceso desde host PC) |
| VM NGINX | `192.168.100.78` | `osboxes` | `~/.ssh/id_rsa_app_server` (en VM APP) |

> Estas IPs son de referencia. **Todos los valores son configurables** mediante variables de entorno del script `deploy.sh`.

---

## 4. Estructura del repositorio relevante

```
scripts/
├── deploy.sh                     # Despliegue blue-green (el entregable principal)
├── configurar_nginx_bluegreen.sh # Configura Nginx una sola vez en la VM NGINX
└── fix_sudoers_nginx.sh          # (auxiliar) configura sudo NOPASSWD en VM NGINX
```

---

## 5. Prerequisitos

### En la VM APP
- Java 17
- `curl`
- `ssh` (para comunicarse con la VM NGINX)
- El directorio de aplicación (`APP_DIR`) con permisos de escritura
- El JAR compilado de la aplicación

### En la VM NGINX
- Nginx instalado
- Un usuario con acceso `sudo` a los binarios de Nginx (ver `sudoers` abajo)
- Clave SSH de la VM APP instalada para permitir conexiones entrantes

---

## 6. Configuración de Nginx (VM NGINX) — ejecutar UNA VEZ

El archivo `springboot-lb.conf` expone el upstream. **Clave:** el upstream hace `include` de un archivo `.inc` donde `deploy.sh` escribe la instancia activa.

> **IMPORTANTE (gotcha):** el archivo `include` **no debe llamarse `.conf`** dentro de `conf.d/`, porque el glob `conf.d/*.conf` de `nginx.conf` lo cargaría a nivel `http` (donde `server ...;` es inválido). Por eso se usa la extensión `.inc`.

### 6.1 Configurar sudo NOPASSWD (VM NGINX)

Para que el `deploy.sh` pueda escribir el include y recargar Nginx **sin contraseña**, crea `/etc/sudoers.d/nginx-bluegreen`:

```bash
sudo tee /etc/sudoers.d/nginx-bluegreen <<'EOF'
osboxes ALL=(ALL) NOPASSWD: /usr/bin/tee, /usr/sbin/nginx, /usr/bin/systemctl reload nginx, /usr/bin/systemctl restart nginx, /usr/bin/cat, /usr/bin/chmod
EOF
sudo chmod 440 /etc/sudoers.d/nginx-bluegreen
sudo visudo -c -f /etc/sudoers.d/nginx-bluegreen   # debe decir "parsed OK"
```

> Ajusta el usuario (`osboxes`) y las rutas si difieren en tu entorno. Puedes automatizarlo con `scripts/fix_sudoers_nginx.sh`.

### 6.2 Crear el archivo include inicial (VM NGINX)

```bash
echo "server 192.168.100.79:8080;" | sudo tee /etc/nginx/conf.d/bluegreen-active.inc
```
(Estado inicial: BLUE activo en `:8080`.)

### 6.3 Configurar el site/upstream

Crea `/etc/nginx/conf.d/springboot-lb.conf`:

```nginx
upstream springboot_backend {
    least_conn;

    # El server activo lo escribe deploy.sh en bluegreen-active.inc
    include /etc/nginx/conf.d/bluegreen-active.inc;
}

server {
    listen 80;
    server_name 192.168.100.78;

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
```

### 6.4 Validar y recargar

```bash
sudo nginx -t
sudo systemctl reload nginx
```

> Todo esto puede hacerse automáticamente ejecutando `configurar_nginx_bluegreen.sh` en la VM NGINX.

---

## 7. El script `deploy.sh`

### 7.1 Variables configurables (por entorno)

| Variable | Default | Descripción |
|----------|---------|-------------|
| `APP_NAME` | `m4-proy-final` | Nombre de la aplicación |
| `APP_DIR` | `/home/osboxes/opt/m4-proy-final` | Directorio de despliegue en VM APP |
| `JAVA_OPTS` | `-Xms512m -Xmx1024m` | Opciones JVM |
| `SPRING_PROFILE` | `prod` | Perfil de Spring |
| `BLUE_PORT` | `8080` | Puerto de la instancia BLUE |
| `GREEN_PORT` | `8081` | Puerto de la instancia GREEN |
| `BLUE_JAR` | `m4-proy-final-blue.jar` | Nombre del JAR destino BLUE |
| `GREEN_JAR` | `m4-proy-final-green.jar` | Nombre del JAR destino GREEN |
| `NGINX_HOST` | `192.168.100.78` | IP de la VM NGINX |
| `NGINX_USER` | `osboxes` | Usuario SSH de la VM NGINX |
| `SSH_KEY` | `/home/osboxes/id_rsa_app_server` | Clave SSH (en VM APP) para conectar a NGINX |
| `NGINX_CONF` | `/etc/nginx/conf.d/bluegreen-active.inc` | Archivo include activo en NGINX |
| `APP_HOST` | `192.168.100.79` | IP de la VM APP |

### 7.2 Qué hace el script

1. Identifica la versión y el artefacto (JAR) a desplegar.
2. Valida infraestructura y conectividad SSH con la VM NGINX (sección 13).
3. Detecta el ambiente activo (`active-environment`) y determina el TARGET.
4. Detiene la instancia TARGET previa (si existe).
5. Hace backup de la versión TARGET en `versions/`.
6. Instala el nuevo JAR como TARGET.
7. Inicia la instancia TARGET con `APP_INSTANCE=BLUE|GREEN` y su puerto.
8. Health check del TARGET (sección 19).
9. Pruebas E2E contra el TARGET (sección 20).
10. Switch de tráfico en Nginx hacia el TARGET (secciones 16/18).
11. Verifica 20 solicitudes contra Nginx (sección 18).
12. Marca el TARGET como activo y reporta.
    - **Si cualquier paso falla → rollback automático** (sección 21).

---

## 8. Comandos de despliegue

### 8.1 Compilar el JAR (en la máquina de desarrollo / Windows)

```bash
# Windows
.\gradlew.bat build -x test

# Linux/Mac
./gradlew build -x test
```

El JAR ejecutable se genera en `build/libs/m4-proy-final-0.0.1-SNAPSHOT.jar`.

### 8.2 Copiar `deploy.sh` y el JAR a la VM APP

```bash
scp scripts/deploy.sh osboxes@<VM_APP>:/home/osboxes/opt/m4-proy-final/
scp build/libs/m4-proy-final-0.0.1-SNAPSHOT.jar osboxes@<VM_APP>:/home/osboxes/opt/m4-proy-final/
```

### 8.3 Configurar Nginx (solo la primera vez, en VM NGINX)

```bash
# Desde la VM APP (que tiene acceso SSH a NGINX):
scp scripts/configurar_nginx_bluegreen.sh osboxes@<VM_NGINX>:/home/osboxes/
ssh osboxes@<VM_NGINX> "bash /home/osboxes/configurar_nginx_bluegreen.sh"
```

### 8.4 Ejecutar el despliegue (en la VM APP)

```bash
cd /home/osboxes/opt/m4-proy-final
export APP_DIR=/home/osboxes/opt/m4-proy-final   # si difiere del default

./deploy.sh v1.0.0 /home/osboxes/opt/m4-proy-final/m4-proy-final-0.0.1-SNAPSHOT.jar
```

> Forma general: `./deploy.sh <version> <path-al-jar>`

---

## 9. Verificación del despliegue

Una vez completado, verifica a través del balanceador Nginx:

```bash
curl -s http://<VM_NGINX>/api/instance     # {"instance":"GREEN","port":"8081"}
curl -s http://<VM_NGINX>/api/hello        # Hola desde M4 Proy Final
curl -s http://<VM_NGINX>/health           # Server Healthy!
curl -s http://<VM_NGINX>/                 # M4 Proy Final is running!
```

Verificación de tráfico (repetición para comprobar la instancia que responde):

```bash
for i in {1..20}; do curl -s http://<VM_NGINX>/api/instance; echo; done
```

---

## 10. Endpoints de la aplicación

| Endpoint | Descripción |
|----------|-------------|
| `GET /` | Mensaje de estado de la aplicación |
| `GET /health` | Health check (`Server Healthy!`) |
| `GET /api/hello` | Saludo de ejemplo |
| `GET /api/instance` | Identifica la instancia activa: `{"instance":"BLUE"\|"GREEN","port":"8080"\|"8081"}` |

> La app identifica la instancia mediante la variable de entorno `APP_INSTANCE` (BLUE/GREEN), que `deploy.sh` inyecta al arrancar.

---

## 11. Rollback

Con Blue-Green, el ambiente **no activo** siempre conserva la versión anterior, por lo que el rollback es inmediato:

**Rollback automático** (durante deploy): si el health check o las E2E fallan, el script detiene la instancia nueva y **mantiene el tráfico en el ambiente anterior** (no conmuta Nginx).

**Rollback manual** (versión con problemas ya activa): vuelve a desplegar la versión anterior, que quedará guardada como backup en `versions/`:

```bash
ls /home/osboxes/opt/m4-proy-final/versions/   # backups con timestamp
./deploy.sh v1.0.0 /home/osboxes/opt/m4-proy-final/versions/m4-proy-final-blue-<TIMESTAMP>.jar
```

El script detectará el ambiente activo y desplegará la versión pasada en el ambiente opuesto, conmutando el tráfico al recuperarse.

---

## 12. Cómo replicar en otro entorno (otra PC / otras VMs)

1. **Clonar/obtener el repositorio** en la máquina de desarrollo.
2. **Compilar el JAR** (sección 8.1) o descargarlo de un Release.
3. **Preparar 2 VMs Ubuntu** con los prerequisitos (sección 5).
4. **Ajustar IPs y rutas** en `deploy.sh` mediante variables de entorno, o editando los defaults:
   - `APP_HOST`, `NGINX_HOST`, `NGINX_USER`, `SSH_KEY`, `APP_DIR`, `NGINX_CONF`.
5. **Instalar la clave SSH** en la VM APP para conectar a la VM NGINX (y agregar su clave pública a `authorized_keys` de la VM NGINX).
6. **Configurar sudo NOPASSWD** en la VM NGINX (sección 6.1).
7. **Configurar Nginx** (sección 6.2–6.4) o ejecutar `configurar_nginx_bluegreen.sh`.
8. **Copiar** `deploy.sh` + JAR a la VM APP (sección 8.2).
9. **Ejecutar** el despliegue (sección 8.4).
10. **Verificar** (sección 9).

### Checklist rápido de replicación

- [ ] Java 17 en VM APP
- [ ] Nginx en VM NGINX
- [ ] SSH VM APP → VM NGINX sin contraseña (clave `id_rsa_app_server`)
- [ ] sudo NOPASSWD para `tee`, `nginx`, `systemctl reload/restart nginx` en VM NGINX
- [ ] include `.inc` configurado en Nginx
- [ ] `APP_DIR` y IPs correctos en `deploy.sh`
- [ ] JAR compilado presente en la VM APP
