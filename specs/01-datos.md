# Spec 01 — Datos y ETL

Estado: **borrador v0.1** (se aprueba en la tarea T-01). Cualquier cambio se hace primero acá.

## 1. Objetivo
Cargar `demanda_electricidad_original_mensual1.csv` en SQLite de forma **reproducible, validada y auditable**, dejando la Tabla 1 lista para que los tres modelos la consuman sin tocarla.

## 2. Pipeline

```
CSV ──E──► DataFrame crudo ──V──► reporte (errores/avisos) ──T──► datos_limpios + demanda_distribuidora ──L──► SQLite
        extract.py            validate.py                      transform.py                              load.py
```

Se ejecuta con `python scripts/run_etl.py [--reset]`. Orquestación en `etl/pipeline.py::run_etl`.

## 3. Criterios de aceptación

| ID | Criterio | Verificación |
|---|---|---|
| ETL-1 | El CSV se lee sin modificar valores; las fechas se parsean a datetime | `test_fechas_extraidas` |
| ETL-2 | La corrida **falla** (código de salida 1, sin escribir nada) si: faltan columnas obligatorias, hay fechas duplicadas o meses faltantes, valores negativos, temperatura fuera de rango, nulos en columnas base, sectores parcialmente nulos o que no suman `demanda_total` | `TestValidate` |
| ETL-3 | Los nulos esperados (sectores antes de 2005; distribuidoras antes de 2014 y tras 2026-06) generan **advertencia**, no error, y **no se imputan** en el ETL | `test_nulos_esperados_*`, `test_participaciones_*` |
| ETL-4 | Tabla 1 con una fila por mes, clave `fecha`, columnas según `docs/data_dictionary.md` | `test_conteos` |
| ETL-5 | Los umbrales de la etiqueta se calculan **solo con el período train**; cambiar datos de test no los altera | `test_umbrales_solo_con_train` |
| ETL-6 | Split cronológico (nunca aleatorio) con fracción de `config.yaml` | `test_split_cronologico` |
| ETL-7 | La carga es **atómica** (transacción) e **idempotente** (correr dos veces no duplica) | `test_rollback_*`, `test_carga_idempotente_*` |
| ETL-8 | Cada corrida deja una fila en `etl_auditoria` con SHA-256 del archivo, conteos, nulos, umbrales y configuración | `test_carga_idempotente_*` |
| ETL-9 | Las distribuidoras se guardan en formato largo, solo con datos no nulos | `test_distribuidoras_formato_largo_*` |

## 4. Decisiones abiertas (cerrar en T-01 con los 3)

| ID | Decisión | Propuesta por defecto | Alternativas / riesgo |
|---|---|---|---|
| D1 | **Definición de la etiqueta** | `relativo_tendencia`: `demanda_total` / media móvil centrada 12 m, con P75 y P90 de train | `percentil_global` (simple, pero la tendencia de largo plazo etiqueta casi todo lo reciente como Crítica). Probar ambas en EDA y documentar |
| D2 | **Fuga por sectores** | Los sectores suman exactamente `demanda_total`; usar solo `part_*` (participaciones) o excluirlos | Experimento de ablación: con/sin sectores, con/sin `potencia_maxima` |
| D3 | **Filas 2001-2004 sin sectores** | Mantenerlas en Tabla 1 (NULL). Los modelos que usen sectores trabajan desde 2005-01 (`tiene_sectores = 1`); los que no, usan toda la serie | Imputar (no recomendado: no hay dato real) |
| D4 | **Tamaño de muestra** | 308 meses (246 train / 62 test). En test hay pocas Alta (3) → reportar con cautela | Validación cruzada temporal; variante binaria Normal vs Alta+Crítica como experimento complementario |
| D5 | **Deriva de la estacionalidad** | Documentar: el pico estacional crece (más Crítica en test: 27 % vs 10 % en train) | Es una propiedad real de los datos, no un error del ETL |
| D6 | **Distribuidoras** | Fuera de las features de v1 (cobertura parcial, solo desde 2014) | Experimento v2 desde 2014 |
| D7 | **Unidades** | Confirmar con la fuente (GWh/MWh, MW) y completar el diccionario | — |

## 5. Contrato con los modelos (lectura de Tabla 1)

```python
# demanda/db/repository.py  (tarea T-07)
def load_clean_data(db_path=None, desde_sectores: bool = False) -> pd.DataFrame:
    """Devuelve datos_limpios ordenado por fecha. Si desde_sectores=True, solo filas con tiene_sectores=1."""
```

Los modelos **no** recalculan la etiqueta ni el split: leen `etiqueta` y `split` de la tabla.
