# Contexto del proyecto — {{PROJECT_NAME}}

<!--
  ARCHIVO A RELLENAR AL ADOPTAR EL PLUGIN.

  Este archivo concentra todo lo específico del proyecto que el Knowledge Agent
  necesita para responder con precisión. El `SKILL.md` referencia esta página
  pero no la copia, así actualizar el contexto del proyecto NO obliga a tocar
  el skill core.

  Rellena cada sección. Borra las que no apliquen.
-->

## Sistema

<!-- En 2-3 líneas: qué hace el sistema, para quién, dominio. -->
TODO.

## Entornos

| Entorno | Branch | Notas |
|---------|--------|-------|
| dev     | develop | |
| uat     | uat     | |
| prod    | main    | |

Fuente de verdad estructurada: `L0-system/environments.yaml`.

## Módulos y repos

| Módulo | Repo (ruta local) | Stack |
|--------|-------------------|-------|
| TODO   | `~/git/TODO`      | TODO  |

Mantener `<KB>/.claude/repos.list` sincronizado para que el pull automático funcione.

## Invariantes

<!-- Reglas de negocio o arquitectónicas que NUNCA se rompen. -->
- TODO.

## Top issues abiertos

Catálogo completo en `L5-issues/INDEX-open.md`.

| Issue | Entorno | Resumen |
|-------|---------|---------|
| TODO  | TODO    | TODO    |

## Archivos clave por módulo

<!-- Apuntar a los 3-5 archivos más leídos por módulo, con anclas a funciones/líneas. -->
### TODO-módulo
- `path/al/archivo.ext` — propósito (función X, líneas ~NN-NN).

## Glosario

<!-- Términos canónicos del dominio. Si el usuario usa un sinónimo conflictivo, llamarlo. -->
- TODO.
