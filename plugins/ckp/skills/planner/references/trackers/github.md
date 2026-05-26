# Tracker: GitHub Issues (stub)

> ⚠️ **STUB no verificado.** El contrato está declarado pero las recetas
> requieren validación. Cuando lo implementes, sustituye este aviso y marca
> como ✅ en `../issue-tracker.md`.

Cubre el contrato declarado en [`../issue-tracker.md`](../issue-tracker.md).

## Credenciales

Usar el CLI `gh` autenticado (`gh auth login`). Evita gestionar tokens a mano.

```bash
# Verificar autenticación
gh auth status
```

Si se prefiere curl: token en `~/secrets/github_token.txt` (PAT con scope `repo`).

## Convenciones

En GitHub Issues, los IDs son numéricos (`#123`), pero el plugin asume un
**prefijo simbólico** (`${user_config.issue_prefix}-NNN`). Dos opciones:

1. **Prefijo = nombre del repo o etiqueta**: `${user_config.issue_prefix}-NNN` mapea a
   `<owner>/<repo>#NNN`. Mantener el mapeo en este archivo.
2. **Adoptar el número crudo**: cambiar el regex a `^#\d+$` y sustituir
   `${user_config.issue_prefix}` por `#` en todo el plugin.

> ⚠️ Decidir cuál antes de usar.

## Operaciones (recetas a verificar)

### `resolve_issue(${user_config.issue_prefix}-NNN)`

```bash
OWNER="..."        # rellenar
REPO="..."         # rellenar
NUMBER="${1#*-}"   # extrae el número del ID

gh issue view "$NUMBER" --repo "$OWNER/$REPO" --json number,title,state,url \
  | jq '{key: ("${user_config.issue_prefix}-" + (.number|tostring)), summary: .title, status: .state, url}'
```

### `build_url(id)`

```
https://github.com/<owner>/<repo>/issues/NNN
```

### `validate_id(id)`

```bash
[[ "$id" =~ ^${user_config.issue_prefix}-[0-9]+$ ]]
```

## TODO al adoptar

- [ ] Decidir el formato de prefijo (opción 1 o 2).
- [ ] Hardcodear `OWNER/REPO` o convertirlo en variable de entorno.
- [ ] Validar recetas `gh` contra el repo real.
- [ ] Documentar permisos mínimos del PAT si no se usa `gh`.
- [ ] Sustituir este aviso por la confirmación de que está validado.
