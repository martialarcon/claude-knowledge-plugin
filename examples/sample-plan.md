# Plan: PRJ-123

## Metadata
- Issue: [PRJ-123](https://example.atlassian.net/browse/PRJ-123) — Validar CIF en el formulario de alta de proveedor
- Handoff: handoff/PRJ-123.yaml
- Fecha: 2026-05-26
- Estimación: 0.5 días
- Riesgo: bajo

## Resumen
Añadir validador `cifValidator` reactivo al form de alta de proveedor y mensaje de error inline.

## Definiciones Funcionales Consultadas
| Archivo L7 | Reglas aplicadas |
|------------|------------------|
| L7-functional/empresa/cif.md | Letra de control mod-23, formato `^[A-Z]\d{7}[A-Z0-9]$` |

## Conflictos con L7 detectados
Ninguno.

## Decisiones
| ID | Pregunta | Decisión | Justificación |
|----|----------|----------|---------------|
| D1 | ¿Validar también NIF? | No en este ticket | Fuera de alcance, abrir ticket aparte |

## Decisiones Pendientes (Bloqueantes)
Ninguna.

---

## Módulo: frontend (Prioridad: 1)

**Repo:** ~/git/mi-frontend
**Branch:** feature/PRJ-123-validar-cif
**Esfuerzo:** 0.5 días
**Riesgo:** bajo

### Archivos a Crear

#### `src/app/shared/validators/cif.validator.ts`
**Propósito:** función pura `cifValidator(value): ValidationErrors | null` con letra de control.

```text
export function cifValidator(control) {
  const v = (control.value ?? '').toUpperCase();
  if (!/^[A-Z]\d{7}[A-Z0-9]$/.test(v)) return { cif: 'INVALID_FORMAT' };
  // ... cálculo letra de control mod-23
  return null;
}
```

**Verify:** `cifValidator({value:'B12345678'})` devuelve `null`; `cifValidator({value:'XYZ'})` devuelve `{cif:'INVALID_FORMAT'}`.

### Archivos a Modificar

#### `src/app/proveedor/alta/alta.component.ts`

**Cambio 1:** añadir validador al control `cif` del FormGroup.
```diff
- cif: ['', [Validators.required]],
+ cif: ['', [Validators.required, cifValidator]],
```
**Verify:** `this.form.get('cif').errors` contiene `{cif: 'INVALID_FORMAT'}` con input `'XYZ'`.

#### `src/app/proveedor/alta/alta.component.html`

**Cambio 1:** mensaje inline bajo el input.
```diff
+ <small *ngIf="form.get('cif').errors?.cif" class="error">CIF inválido</small>
```
**Verify:** al escribir `XYZ` en el input, aparece "CIF inválido" debajo.

### Definition of Done — frontend
- [ ] `npm test src/app/shared/validators/cif.validator.spec.ts` pasa.
- [ ] Alta con CIF inválido no llega a `api.crearProveedor`.
- [ ] Alta con CIF válido (`B12345678`) sí llega.
- [ ] No regresiones en el spec existente de `alta.component`.

---

## Orden de Implementación
1. frontend — único módulo afectado.

## Testing
### Unit
| Módulo | Archivo | Qué probar |
|--------|---------|------------|
| frontend | cif.validator.spec.ts | 4 cases: válido, formato inválido, letra inválida, vacío |

### E2E
- Flujo de alta completo con CIF válido e inválido.

## Deploy
### Orden
1. frontend a dev → uat → prod.

### Rollback
Revertir branch. Sin migraciones, sin estado persistido.

## Warnings del Knowledge Agent
- Backend devuelve 500 en lugar de 400 con CIF inválido (PRJ-118). No bloqueante para este plan.

## Trazabilidad
- Issue: [PRJ-123](https://example.atlassian.net/browse/PRJ-123)
- Branch sugerida: `feature/PRJ-123-validar-cif`
- Formato commit: `PRJ-123 Validar CIF en alta de proveedor`

## Checklist Pre-Implementación
- [x] Decisiones resueltas
- [ ] Entorno configurado
- [ ] Branch creada
- [ ] Accesos verificados
