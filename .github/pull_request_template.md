## Resumen
<!-- Qué cambia este PR y por qué, en 2-3 líneas. -->

## Issue
Closes #

## Tareas hechas
<!-- ID de la tarea (por ejemplo ETL-4) y qué parte del entregable cubre. -->
- [ ]

## Cómo probarlo
<!-- Comandos exactos y qué resultado se espera. -->
```bash
pytest
ruff check src tests
```

## Definición de "hecho" (PLAN_SDD.md §6)
- [ ] Issue con ID de tarea; este PR lo cierra (`Closes #N`).
- [ ] Spec/criterio escrito **antes** de implementar.
- [ ] Mínimo 3 commits propios, formato `tipo(ID): descripción`.
- [ ] Tests y linter pasan en local y en CI.
- [ ] El autor puede **explicar** el código (aunque lo haya generado el agente).
- [ ] Documentación y docstrings actualizados.
- [ ] PR aprobado por otro integrante; merge **sin squash**.
- [ ] Casilla marcada en `docs/avance.md`.

## Checklist del revisor (GUIA_EQUIPO.md §5)
- [ ] El PR cierra el issue correcto y cumple su entregable.
- [ ] Hay 3+ commits con mensajes claros y el ID de tarea.
- [ ] Hay tests significativos (probé romper la regla y falla) y pasan en CI.
- [ ] **Sin fuga de datos:** test no participa de ningún `fit`, ni de la CV, ni del cálculo de umbrales.
- [ ] Ninguna feature prohibida; los sectores no entran en valores absolutos.
- [ ] Respeta los contratos (columnas, claves, firmas).
- [ ] Sin valores hardcodeados.
- [ ] Documentación y docstrings actualizados.
- [ ] El autor puede explicar el código (preguntale una cosa al azar).
