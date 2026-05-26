---
name: setup
description: |
  Bootstrap inicial del Knowledge Base de CKP en el proyecto actual.

  Usar cuando:
  - El usuario invoca `/ckp:setup`
  - El usuario dice "configura ckp", "inicializa el knowledge base", "bootstrap del KB"
  - El hook `pre-activate.sh` reporta `KB_EXISTS=false`
  - knowledge-agent o planner se invocan y no hay carpetas `L0-system/`…`L7-functional/`
    en el directorio resuelto como KB

  NO usar cuando:
  - El KB ya existe (`L0-system/` presente). En ese caso, no rehacer.

tools: [Read, Bash, Write, Edit, Glob, LS]
---

# CKP — Setup del Knowledge Base

Esta skill prepara la estructura mínima del KB en el proyecto actual y deja al usuario listo para `/ckp` y `/ckp:planner`.

## Reglas duras

1. **Nunca sobrescribir** archivos existentes. Si `L0-system/` ya está, abortar con mensaje y derivar a `/ckp` para análisis normal.
2. **Pedir confirmación** antes de copiar nada al disco del proyecto.
3. **Respetar `${user_config.kb_path}`**: si está configurado, ahí se bootstrappea. Si está vacío, usar `${CLAUDE_PROJECT_DIR}` directamente.
4. **No tocar `${CLAUDE_PLUGIN_ROOT}`**: la plantilla `kb-skeleton/` se lee, no se modifica.

## Proceso

### 1. Resolver destino del KB

```
KB_DIR = ${CLAUDE_PROJECT_DIR}/${user_config.kb_path}
         (si kb_path vacío → KB_DIR = ${CLAUDE_PROJECT_DIR})
```

Mostrar al usuario:

> Voy a bootstrappear el KB en: `<KB_DIR>`
> Tracker activo: `${user_config.issue_tracker}` (prefijo `${user_config.issue_prefix}`)
> ¿Confirmas?

### 2. Verificar pre-condiciones

```bash
ls "$KB_DIR/L0-system" 2>/dev/null && echo "EXISTS" || echo "EMPTY"
```

- Si `EXISTS`: avisar al usuario, **no continuar**. Sugerir `/ckp status` para inspeccionar.
- Si `EMPTY`: continuar.

### 3. Copiar esqueleto

```bash
cp -R "${CLAUDE_PLUGIN_ROOT}/kb-skeleton/." "$KB_DIR/"
```

### 4. Crear `repos.list` vacío

```bash
mkdir -p "${CLAUDE_PROJECT_DIR}/.claude"
[[ -f "${CLAUDE_PROJECT_DIR}/.claude/ckp-repos.list" ]] || cat > "${CLAUDE_PROJECT_DIR}/.claude/ckp-repos.list" <<'EOF'
# Repos compañeros que el hook pre-activate.sh mantiene actualizados vía `git pull --ff-only`.
# Una entrada por línea, relativa a CKP_REPOS_ROOT (default: directorio padre del KB).
# Acepta globs (ej. `lambda-*`).
EOF
```

### 5. Inicializar `index/keywords.json` si falta

```bash
mkdir -p "$KB_DIR/index"
[[ -f "$KB_DIR/index/keywords.json" ]] || echo '{"keywords":{}}' > "$KB_DIR/index/keywords.json"
```

### 6. Reportar al usuario

```
✅ KB inicializado en <KB_DIR>

Siguientes pasos:
  1. Editar L0-system/environments.yaml con los entornos reales.
  2. Editar skills/knowledge-agent/references/domain.md (en el plugin: ya viene con plantilla).
  3. Añadir repos compañeros en .claude/ckp-repos.list (opcional).
  4. Probar: /ckp status
```

## Lo que NO hago

- ❌ Configurar el tracker (eso se hace en `/plugin` → user_config).
- ❌ Crear tickets, ramas o ADRs (eso es trabajo del KA o Planner).
- ❌ Modificar archivos fuera del KB y del `.claude/ckp-repos.list`.
