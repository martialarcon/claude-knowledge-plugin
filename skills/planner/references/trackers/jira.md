# Tracker: Jira (implementación)

Cubre el contrato declarado en [`../issue-tracker.md`](../issue-tracker.md).

## Credenciales

- **Token**: archivo `~/secrets/jira_token.txt` (API token de Atlassian, no la contraseña).
- **Email**: derivado de `git config user.email`. Si la cuenta de Claude no coincide con la de Atlassian, mantener un mapeo en el README del proyecto (o exportar `JIRA_EMAIL`).

```bash
JIRA_BASE="${user_config.issue_tracker_url}"
JIRA_EMAIL="${JIRA_EMAIL:-$(git config user.email)}"
JIRA_TOKEN="$(cat ~/secrets/jira_token.txt)"
JIRA_AUTH="$JIRA_EMAIL:$JIRA_TOKEN"
```

## Operaciones

### `resolve_issue(${user_config.issue_prefix}-NNN)`

```bash
curl -s -u "$JIRA_AUTH" \
  "$JIRA_BASE/rest/api/3/issue/${user_config.issue_prefix}-NNN?fields=summary,status" \
  | jq '{key, summary: .fields.summary, status: .fields.status.name}'
```

Salida esperada:
```json
{ "key": "${user_config.issue_prefix}-123", "summary": "…", "status": "In Progress" }
```

**Si devuelve 404**: el ticket no existe → avisar al usuario, NO inventar.
**Si devuelve 401**: token caducado o email mal mapeado → avisar.

### `build_url(id)`

```
${user_config.issue_tracker_url}/browse/${user_config.issue_prefix}-NNN
```

### `validate_id(id)`

```bash
[[ "$id" =~ ^${user_config.issue_prefix}-[0-9]+$ ]]
```

## Búsqueda por JQL (opcional, para `/ckp status` o similar)

```bash
curl -s -u "$JIRA_AUTH" -X POST -H "Content-Type: application/json" \
  "$JIRA_BASE/rest/api/3/search/jql" \
  -d '{"jql":"project = ${user_config.issue_prefix} AND status = \"In Progress\"","fields":["summary","status"]}' \
  | jq '.issues[] | {key, summary: .fields.summary, status: .fields.status.name}'
```

## Errores comunes

| Síntoma | Causa | Fix |
|---------|-------|-----|
| 401 Unauthorized | Token caducado o email incorrecto | Regenerar token en id.atlassian.com → `~/secrets/jira_token.txt` |
| 404 Not Found | ID inexistente o sin permisos | Verificar permisos del proyecto |
| Comilla / acento mal escapados en JQL | Shell escaping | Usar `--data-urlencode` o heredoc |

## Helpers shell

Recomendado añadir a `~/.bashrc` o `~/.zshrc`:

```bash
jira_get() {
  local id="$1"
  curl -s -u "$JIRA_AUTH" \
    "$JIRA_BASE/rest/api/3/issue/$id?fields=summary,status" \
    | jq '{key, summary: .fields.summary, status: .fields.status.name}'
}
```
