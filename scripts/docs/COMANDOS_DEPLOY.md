# COMANDOS_DEPLOY.md

Comandos reales utilizados para ejecutar el despliegue **blue-green** del proyecto `m4-proy-final`, verificados desde la terminal en la máquina de desarrollo (Windows) hacia las dos VMs.

> Complementa a [`DEPLOY.md`](./DEPLOY.md) (teoría y configuración). Este documento es la **guía operativa paso a paso** con los comandos exactos para reproducir el despliegue.

---

## 0. Datos del entorno (memorizar para los comandos)

| Rol | IP | Usuario | Acceso |
|-----|-----|---------|--------|
| VM APP | `192.168.100.79` | `osboxes` | desde PC host con `id_rsa_pc_host` |
| VM NGINX | `192.168.100.78` | `osboxes` | desde VM APP con `id_rsa_app_server` |

- Clave SSH del PC host → VM APP: `C:\Users\ICOREBIZ\Documents\pem\id_rsa_pc_host`
- Clave SSH de VM APP → VM NGINX: `/home/osboxes/id_rsa_app_server` (dentro de la VM APP)
- Directorio de despliegue en VM APP: `/home/osboxes/opt/m4-proy-final`

---

## 1. Compilar y probar la aplicación (Windows, en el repo)

```powershell
# 1.1 Ejecutar todos los tests (verifica nuevas funcionalidades)
.\gradlew.bat test

# 1.2 Construir el JAR ejecutable (si jacocoTestReport falla por archivo bloqueado, usa -x test)
.\gradlew.bat build -x test
```

- Tests de controller: `GreetingControllerTest` (3/3 OK) → `/api/version` incluido.
- JAR generado: `build/libs/m4-proy-final-0.0.1-SNAPSHOT.jar`

---

## 2. Copiar el JAR y el `deploy.sh` a la VM APP

```powershell
# 2.1 Copiar el JAR nuevo
scp -i C:\Users\ICOREBIZ\Documents\pem\id_rsa_pc_host `
    build/libs/m4-proy-final-0.0.1-SNAPSHOT.jar `
    osboxes@192.168.100.79:/home/osboxes/opt/m4-proy-final/

# 2.2 Copiar el deploy.sh actualizado (si hubo cambios de lógica)
scp -i C:\Users\ICOREBIZ\Documents\pem\id_rsa_pc_host `
    scripts\deploy.sh `
    osboxes@192.168.100.79:/home/osboxes/opt/m4-proy-final/deploy.sh
```

> Nota: puede que el JAR nuevo sea la versión `0.0.1-SNAPSHOT` aunque el despliegue se etiquete `v1.1.0` (la versión del despliegue es un tag; el artefacto conserva el nombre de versión del build).

---

## 3. Ejecutar el despliegue (en la VM APP)

```bash
# Conectar a la VM APP
ssh -i "C:\Users\ICOREBIZ\Documents\pem\id_rsa_pc_host" osboxes@192.168.100.79

# Dentro de la VM APP: ir al directorio y ejecutar
cd /home/osboxes/opt/m4-proy-final
bash deploy.sh v1.1.0 /home/osboxes/opt/m4-proy-final/m4-proy-final-0.0.1-SNAPSHOT.jar
```

Forma general del comando:

```bash
bash deploy.sh <version> <ruta-del-jar-en-la-VM-APP>
```

### Qué hace `deploy.sh` (resumen de la salida)

| Fase | Mensaje clave |
|------|---------------|
| Infraestructura | `Verificando conexión con VM Nginx... ✅` |
| Blue-Green | `Ambiente activo: GREEN -> target: BLUE` (o al revés) |
| Instalación | `✅ JAR instalado` / `✅ blue iniciado PID: ...` |
| Health check | `✅ Health Check OK. ✅ Instancia: blue ✅ Puerto: 8080` |
| E2E | `✅ Todas las pruebas E2E fueron exitosas.` |
| Switch | `✅ Tráfico cambiado hacia blue.` |
| Verificación | `Solicitudes totales: 20 / Respuestas target: 20` |
| Completado | `✅ Tráfico mayoritariamente llegando a blue (20/20).` |

Al final imprime el resumen:

```
DEPLOYMENT COMPLETADO
Aplicación       : m4-proy-final
Versión          : v1.1.0
Ambiente activo  : BLUE
Puerto           : 8080
```

---

## 4. Verificar el despliegue (a través del balanceador Nginx)

Desde la VM APP (que alcanza a la VM NGINX por red interna):

```bash
curl -s http://192.168.100.78/api/version     # m4-proy-final v1.1.0   (nuevo)
curl -s http://192.168.100.78/api/instance    # {"port":"8080","instance":"BLUE"}
curl -s http://192.168.100.78/api/hello       # Hola desde M4 Proy Final
curl -s http://192.168.100.78/health          # Server Healthy!
curl -s http://192.168.100.78/                # M4 Proy Final is running!
```

Verificación de tráfico (20 solicitudes para confirmar a qué instancia responde):

```bash
for i in {1..20}; do curl -s http://192.168.100.78/api/instance; echo; done
```

Comprobar el ambiente activo en la VM APP:

```bash
cat /home/osboxes/opt/m4-proy-final/active-environment    # blue | green
cat /home/osboxes/opt/m4-proy-final/blue.pid              # PID de la instancia activa
```

---

## 5. Flujo de despliegue esperado (cómo alterna BLUE/GREEN)

Cada vez que se ejecuta `deploy.sh` alterna el ambiente activo:

| Ejecución | Activo previo | Target | Resultado |
|-----------|---------------|--------|-----------|
| 1ª | GREEN (`:8081`) | BLUE (`:8080`) | BLUE activo |
| 2ª | BLUE (`:8080`) | GREEN (`:8081`) | GREEN activo |
| ... | alternando | ... | ... |

La nueva versión siempre se instala en el ambiente **opuesto** y, solo si pasa health check + E2E + verificación de tráfico, se conmuta Nginx.

---

## 6. Rollback (si algo falla)

**Automático:** si el health check, E2E o la verificación de tráfico fallan, `deploy.sh` revierte solo:

```bash
ROLLBACK
Ambiente anterior : green
Restaurando tráfico hacia green... ✅
Deteniendo blue... ✅
Ambiente activo: green
```

**Manual:** la versión anterior queda respaldada en `versions/`:

```bash
ls /home/osboxes/opt/m4-proy-final/versions/
bash deploy.sh v1.0.0 /home/osboxes/opt/m4-proy-final/versions/m4-proy-final-blue-<TIMESTAMP>.jar
```

---

## 7. Tabla de endpoints

| Endpoint | Respuesta |
|----------|-----------|
| `GET /` | `M4 Proy Final is running!` |
| `GET /health` | `Server Healthy!` |
| `GET /api/hello` | `Hola desde M4 Proy Final` |
| `GET /api/instance` | `{"instance":"BLUE"\|"GREEN","port":"8080"\|"8081"}` |
| `GET /api/version` | `m4-proy-final v1.1.0` |
