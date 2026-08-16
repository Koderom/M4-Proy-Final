# CI/CD Labs - GitHub Actions Learning Project

## Descripción

Este proyecto es un laboratorio de pruebas y conceptos fundamentales de **CI/CD (Continuous Integration/Continuous Delivery)** y **GitHub Actions**. Está diseñado para explorar y practicar los siguientes conceptos clave:

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
├── app/                    # Código de la aplicación
├── tests/                  # Tests automatizados
├── README.md               # Este archivo
└── hello.txt               # Archivo de ejemplo
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

## 🔄 GitHub Actions Workflows

### Workflows Disponibles

- **on-push.yml**: Se ejecuta en cada push a cualquier rama
- **on-pull-request.yml**: Se ejecuta cuando se abre o actualiza un PR
- **on-schedule.yml**: Se ejecuta en horarios programados

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
