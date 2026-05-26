# Tracker: Linear (stub)

> ⚠️ **STUB no verificado.** El contrato está declarado pero las recetas
> concretas requieren validación contra la API real antes de fiarse de ellas.
> Cuando lo implementes, sustituye este aviso y marca como ✅ en
> `../issue-tracker.md`.

Cubre el contrato declarado en [`../issue-tracker.md`](../issue-tracker.md).

## Credenciales

- **Token**: archivo `~/secrets/linear_token.txt` (Personal API key desde Linear → Settings → API).
- **Base URL API**: `https://api.linear.app/graphql`.

```bash
LINEAR_TOKEN="$(cat ~/secrets/linear_token.txt)"
LINEAR_API="https://api.linear.app/graphql"
```

## Operaciones (recetas a verificar)

### `resolve_issue(${user_config.issue_prefix}-NNN)`

Linear identifica issues por slug `<TEAM>-<N>` (mismo formato).

```bash
curl -s -X POST "$LINEAR_API" \
  -H "Authorization: $LINEAR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { issue(id: \"${user_config.issue_prefix}-NNN\") { identifier title state { name } url } }"}' \
  | jq '.data.issue'
```

> ⚠️ Verificar: la API de Linear puede requerir UUID en lugar del identifier
> humano. Si falla, listar issues filtrando por `team` + `number`.

### `build_url(id)`

```
${user_config.issue_tracker_url}/issue/${user_config.issue_prefix}-NNN
```

Linear suele ser `https://linear.app/<workspace>/issue/<id>`.

### `validate_id(id)`

```bash
[[ "$id" =~ ^${user_config.issue_prefix}-[0-9]+$ ]]
```

## TODO al adoptar

- [ ] Verificar formato de identifier real (humano vs UUID).
- [ ] Validar query GraphQL contra la API.
- [ ] Documentar mapping `git config user.email` ↔ cuenta Linear si aplica.
- [ ] Sustituir este aviso por la confirmación de que está validado.
