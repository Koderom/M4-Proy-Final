# M4 Proy Final

Proyecto Spring Boot para demostrar un proceso reproducible de Continuous Integration y publicación de versiones con GitHub Actions. El alcance de este repositorio comprende branching, pruebas, cobertura, empaquetado, versionamiento semántico, artefactos y GitHub Releases. El deployment no forma parte de este alcance.

## Aplicación

La aplicación utiliza Java 17, Spring Boot 4.1.0, Gradle, JUnit 5 y JaCoCo. Expone los siguientes endpoints:

| Método | Ruta | Respuesta esperada |
|---|---|---|
| GET | `/` | `M4 Proy Final is running!` |
| GET | `/api/hello` | `Hola desde M4 Proy Final` |
| GET | `/health` | `Server Healthy!` |
| GET | `/date` | Fecha actual del servidor |

La aplicación se ejecuta localmente en el puerto `8081`.

## Estructura

```text
m4-proy-final/
├── .github/workflows/pipeline.yml
├── gradle/wrapper/
├── src/main/java/com/example/m4_proy_final/
├── src/test/java/com/example/m4_proy_final/
├── build.gradle
├── settings.gradle
├── CHANGELOG.md
└── README.md
```

## Construcción y pruebas

El Gradle Wrapper incluido garantiza que localmente y en CI se utilice la misma versión de Gradle.

| Objetivo | Windows | Linux/macOS |
|---|---|---|
| Compilar, probar, verificar cobertura y empaquetar | `.\gradlew.bat clean build` | `./gradlew clean build` |
| Ejecutar pruebas | `.\gradlew.bat test` | `./gradlew test` |
| Generar reporte JaCoCo | `.\gradlew.bat jacocoTestReport` | `./gradlew jacocoTestReport` |
| Ejecutar la aplicación | `.\gradlew.bat bootRun` | `./gradlew bootRun` |

Después de iniciar la aplicación se puede verificar con:

```bash
curl http://localhost:8081/health
```

Los resultados locales se generan en:

```text
build/reports/tests/test/index.html
build/reports/jacoco/test/html/index.html
build/reports/jacoco/test/jacocoTestReport.xml
build/libs/m4-proy-final-<version>.jar
```

El build falla si una prueba falla o si la cobertura de líneas es inferior al 70%.

Resultado de la validación local del 4 de septiembre de 2026:

- 12 pruebas ejecutadas, sin fallos ni pruebas omitidas.
- 100% de cobertura de clases, métodos, líneas y ramas.
- JAR ejecutable `m4-proy-final-1.0.0.jar` validado con la versión `1.0.0` en su manifiesto.
- Endpoints `/`, `/api/hello` y `/health` verificados con HTTP 200.

### Equivalencia con Maven

Este proyecto utiliza Gradle con autorización del docente. Las responsabilidades son equivalentes:

| Maven | Gradle utilizado |
|---|---|
| `pom.xml` | `build.gradle` |
| `mvn clean verify` | `./gradlew clean build` |
| `target/*.jar` | `build/libs/*.jar` |

No se requiere `pom.xml`, `mvn` ni un workflow llamado `maven.yml`.

## Estrategia de branching

| Rama | Propósito |
|---|---|
| `main` | Código estable, integrado y listo para versionar. |
| `feature/<descripcion>` | Desarrollo aislado de una funcionalidad o cambio. |

Reglas de trabajo:

1. Crear cada `feature/*` desde la versión actual de `main`.
2. No realizar cambios directamente en `main`.
3. Publicar la rama y abrir un Pull Request hacia `main`.
4. Corregir cualquier fallo detectado por el check obligatorio `build-and-test`.
5. Integrar únicamente cuando CI termine correctamente.
6. Utilizar Squash Merge para conservar un commit claro por Pull Request.
7. Eliminar la rama de feature después del merge.

El workflow se ejecuta en cada push a `main` y `feature/**`, y en cada Pull Request dirigido a `main`. La protección de `main` exige Pull Request y el check `build-and-test`, bloquea force pushes y restringe la eliminación de la rama.

## Versionamiento y tagging

Las versiones publicables siguen Semantic Versioning y usan tags con el formato `vMAJOR.MINOR.PATCH`:

- `MAJOR`: cambio incompatible con versiones anteriores.
- `MINOR`: nueva funcionalidad compatible.
- `PATCH`: corrección compatible.

Un tag se crea únicamente sobre un commit integrado en `main` cuyo CI haya finalizado correctamente. Ejemplo para publicar la primera versión:

```bash
git switch main
git pull --ff-only
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

La trazabilidad esperada es directa:

```text
tag v1.0.0
    -> versión Gradle 1.0.0
    -> m4-proy-final-1.0.0.jar
    -> GitHub Release v1.0.0
```

Los cambios de cada versión se documentan en `CHANGELOG.md`.

## Pipeline de CI y publicación

El workflow `.github/workflows/pipeline.yml` ejecuta:

```text
Checkout
  -> Setup JDK 17
  -> Validación del tag
  -> Build
  -> Pruebas JUnit
  -> Verificación y reporte JaCoCo
  -> JAR ejecutable
  -> Artefactos de GitHub Actions
  -> GitHub Release, solamente cuando el evento es un tag válido
```

Para ramas y Pull Requests, la versión del artefacto incluye el SHA corto del commit, por ejemplo `0.0.1-SNAPSHOT-a1b2c3d`. Para un tag `v1.2.0`, el JAR y su manifiesto reciben la versión exacta `1.2.0`.

El job `ci` construye el JAR una sola vez. El job `release` descarga ese mismo artefacto y lo adjunta a la Release; no vuelve a construir la aplicación. El permiso de escritura sobre el repositorio existe únicamente en el job de Release.

Los reportes de pruebas y cobertura se publican incluso cuando una validación falla, siempre que hayan podido generarse. Esto permite diagnosticar el error desde la ejecución de GitHub Actions.

## Code Coverage

JaCoCo genera reportes HTML y XML con cobertura de clases, métodos, líneas, ramas, instrucciones y complejidad. La cobertura permite localizar código sin pruebas y evita integrar cambios que reduzcan la cobertura de líneas por debajo del 70% definido en `build.gradle`.

Para aumentar la cobertura se deben agregar pruebas que recorran tanto el resultado exitoso como las validaciones y excepciones de cada método.

## Comportamiento ante fallos

Cuando una prueba o la verificación de cobertura falla:

1. Gradle devuelve un código de salida distinto de cero.
2. El job `build-and-test` queda en estado fallido.
3. La protección de `main` impide integrar el Pull Request.
4. No se publica el JAR ni se crea una Release.
5. Los reportes disponibles se conservan como artefactos de diagnóstico.

## Evidencias en GitHub

- [Ejecuciones de GitHub Actions](https://github.com/Koderom/M4-Proy-Final/actions)
- [Pull Requests](https://github.com/Koderom/M4-Proy-Final/pulls?q=is%3Apr)
- [Reglas de protección de main](https://github.com/Koderom/M4-Proy-Final/rules?ref=refs%2Fheads%2Fmain)
- [Ejecución fallida de demostración](https://github.com/Koderom/M4-Proy-Final/actions/runs/31964252882)
- [Tags](https://github.com/Koderom/M4-Proy-Final/tags)
- [Releases](https://github.com/Koderom/M4-Proy-Final/releases)

## Convención de commits

```text
<tipo>: <descripción breve>
```

Tipos recomendados: `feat`, `fix`, `docs`, `test`, `ci`, `refactor` y `chore`.

Ejemplo:

```text
ci: publish versioned JAR from semantic tags
```
