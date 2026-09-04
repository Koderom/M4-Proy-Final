# CI/CD Labs - GitHub Actions Learning Project

## Descripción

Este proyecto es un laboratorio de pruebas y conceptos fundamentales de **CI/CD (Continuous Integration/Continuous Delivery)** y **GitHub Actions**. Está diseñado para explorar y practicar los siguientes conceptos clave:

## 🌐 La Aplicación

Una API REST sencilla con **Spring Boot 4.1.0** y **Java 17** que expone un endpoint de ejemplo (hello world):

| Método | Ruta        | Respuesta                  |
|--------|-------------|----------------------------|
| GET    | `/api/hello`| `Hola desde CI/CD Labs`    |

## 🎯 Objetivos

- Entender y configurar pipelines de CI/CD
- Aprender a utilizar GitHub Actions para automatización
- Implementar flujos de trabajo (workflows) automatizados
- Practicar estrategias de branching y versionado
- Validar código automáticamente en cada push
- Automatizar pruebas, builds y deployments

## 📚 Temas Cubiertos

- **GitHub Actions Basics**: Workflows, jobs, steps, y actions
- **Branching Strategy**: Feature branches, main branch protection
- **Automated Testing**: Ejecutar tests automáticamente
- **Build Automation**: Compilación y empaquetamiento automático
- **Deployment Pipelines**: Automatización de despliegues
- **CI/CD Best Practices**: Convenciones y mejores prácticas

## 🏗️ Estructura del Proyecto

```
ci-cd-labs/
├── .github/
│   └── workflows/          # GitHub Actions workflow files
├── src/
│   ├── main/               # Código de la aplicación
│   │   └── java/com/example/ci_cd_labs/
│   │       ├── CiCdLabsApplication.java
│   │       └── controllers/GreetingController.java
│   └── test/               # Tests automatizados
│       └── java/com/example/ci_cd_labs/
├── build.gradle
├── settings.gradle
└── README.md               # Este archivo
```

## 🚀 Primeros Pasos

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd ci-cd-labs
   ```

2. **Crear una rama de feature**
   ```bash
   git checkout -b feature/nombre-de-feature
   ```

3. **Hacer cambios y commitear**
   ```bash
   git add .
   git commit -m "Add: descripción de cambios"
   ```

4. **Push a la rama**
   ```bash
   git push -u origin feature/nombre-de-feature
   ```

5. **Crear Pull Request**
   - Los workflows se ejecutarán automáticamente
   - Revisa que pasen todas las validaciones

## 🛠️ Build y Tests

Usa el wrapper de Gradle incluido. En Windows el comando es `.\gradlew.bat` (en Linux/macOS, `./gradlew`).

| Comando                         | Descripción                                                  |
|---------------------------------|--------------------------------------------------------------|
| `.\gradlew.bat test`            | Compila y ejecuta todas las pruebas (JUnit 5)                |
| `.\gradlew.bat build`           | Compila, ejecuta pruebas y genera el jar (incluye `test`)    |
| `.\gradlew.bat build -x test`   | Solo compila, sin ejecutar pruebas                           |
| `.\gradlew.bat test --tests com.example.ci_cd_labs.controllers.GreetingControllerTest` | Ejecuta una sola prueba |

Para correr la aplicación:

```
.\gradlew.bat bootRun
```

Y abrir <http://localhost:8080/api/hello>.

> **Nota (entorno local):** el puerto 8080 suele estar ocupado por XAMPP/Apache en esta máquina. Si ocurre, usa `.\gradlew.bat bootRun --args='--server.port=8090'` o detén Apache.

## 🔄 GitHub Actions Workflows

### Workflows Disponibles

- **pipeline.yml**: Se ejecuta en cada push a `main`/`feature/*` y en PRs hacia `main`. Por ahora solo muestra pasos de ejemplo (echo); no compila ni ejecuta pruebas.

## ✅ Validaciones Automáticas

Cada commit y pull request se somete a:

- ✔️ Análisis estático del código
- ✔️ Ejecución de pruebas unitarias
- ✔️ Validación de estándares de código
- ✔️ Verificación de cambios en documentación

## 📝 Convenciones de Commit

Para mantener un historial limpio:

```
<tipo>: <descripción breve>

<descripción detallada opcional>
```

**Tipos**:
- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Cambios en documentación
- `test`: Adición o modificación de tests
- `chore`: Cambios en configuración o dependencias

Ejemplo:
```
feat: Add GitHub Actions workflow for CI/CD
```

## 🔐 Protecciones de Rama

La rama `main` está protegida y requiere:

- ✅ Pull Request review
- ✅ Pasar todos los checks de CI/CD
- ✅ Historia de commits limpia

## 📚 Referencias Útiles

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Actions Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [GitHub Actions Best Practices](https://docs.github.com/en/actions/guides)
- [CI/CD Concepts](https://www.atlassian.com/continuous-delivery/ci-cd)

**Última actualización**: 2026-08-16
