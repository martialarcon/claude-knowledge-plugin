# Migraciones

Cada subdirectorio `vX.Y.Z/` contiene un `upgrade.sh` idempotente que migra una instalación del plugin **desde la versión inmediatamente anterior** a `X.Y.Z`.

## Contrato

- **Entrada:** primer argumento = ruta absoluta del target (`<target>` que contiene `.claude/` y `CLAUDE.md`).
- **Idempotencia:** ejecutar dos veces no debe romper nada ni duplicar contenido.
- **Preservar local:** nunca sobrescribir archivos que el operador haya personalizado (`repos.list`, `references/domain.md`, contenidos del KB). Tocar solo lo que el plugin **posee** (hooks, settings, skill-rules, plantillas).
- **Salida:** código 0 si OK, no-cero si requiere intervención manual; mensajes claros por stderr.
- **No bumpea VERSION** en el target: eso lo hace `upgrade.sh` raíz tras encadenar todas las migraciones aplicables.

## Versión instalada

Tras instalar/migrar, el target tiene `.claude/.plugin-version` con la versión actual. Si falta, se asume `0.1.0` (instalaciones anteriores a la introducción de migraciones).

## Estructura de una migración

```
migrations/v0.2.0/
  upgrade.sh        # ejecutable, idempotente
  NOTES.md          # qué cambia, por qué, riesgos
```
