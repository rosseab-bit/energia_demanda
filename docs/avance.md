# Avance del proyecto

Una casilla por tarea. Se marca al **mergear el PR** de la tarea (definición de "hecho" de `PLAN_SDD.md §6`).
Cada fila enlaza al issue con su número. Responsables: A = Angelzam21, B = briansablich, C = rosseab-bit.

Para revisar el equilibrio de aportes: `git shortlog -sn --no-merges`.

**Progreso: 4 de 50 tareas.**

## Fase 0 - Fundacion

| Hecho | Tarea | Issue | Responsable | Descripción |
|---|---|---|---|---|
| [x] | T-00 | #4 | C | Repo y esqueleto: pyproject, config, CLAUDE.md, CODEOWNERS, plantilla de PR, proteccion de main |
| [x] | T-01 | #5 | A+B+C | Reunion de arranque: cerrar decisiones D1-D7 y aprobar specs 00-contratos y 01-datos |
| [ ] | T-02 | #6 | A | Diccionario de datos y unidades |
| [ ] | T-03 | #7 | A | schema.sql (Tabla 1, 2, 3 y extras del ETL) |
| [ ] | CMP-1 | #8 | A+B+C | Spec de comparacion de modelos (criterios definidos antes de ver resultados) |

## Fase 1 - ETL y base

| Hecho | Tarea | Issue | Responsable | Descripción |
|---|---|---|---|---|
| [ ] | ETL-1 | #9 | A | ETL Extract: lectura del CSV, fechas, SHA-256 |
| [ ] | ETL-2 | #10 | B | ETL Validate: reglas de calidad (errores vs advertencias) |
| [ ] | ETL-3 | #11 | A | ETL Transform: calendario, participaciones, etiqueta, split cronologico |
| [ ] | ETL-4 | #12 | C | ETL Load: transaccion, idempotencia, rollback, auditoria |
| [ ] | ETL-5 | #13 | C | ETL Pipeline y CLI run_etl.py + test de integracion con el CSV real |
| [ ] | ETL-6 | #14 | B | EDA de decision: metodos de etiqueta (D1), fuga por sectores (D2), balance de clases |
| [ ] | DB-1 | #15 | A | repository.load_clean_data() |
| [ ] | DB-2 | #16 | A | repository.save_run() en Tablas 2 y 3 (transaccional) |
| [ ] | MC-1 | #17 | B | build_preprocessor() desde feature_sets (test anti-fuga) |
| [ ] | MC-2 | #18 | B | splits.py: split por columna + TimeSeriesSplit + chequeo de clases por fold |
| [ ] | MC-3 | #19 | B | evaluate.py: Accuracy, Precision, Recall, F1 y matriz de confusion |
| [ ] | MC-4 | #20 | B | Runner train.py (--model, --features, autodescubrimiento) |
| [x] | T-15 | #21 | C | CI en GitHub Actions (ruff + pytest) como check obligatorio |
| [ ] | VIZ-1 | #22 | C | plots.py base: clases, demanda vs temperatura, estacionalidad, serie con criticos |
| [ ] | VIZ-2 | #23 | C | BD fixture con datos ficticios (3 tablas) para tests y dashboard |

## Fase 2 - Modelos

| Hecho | Tarea | Issue | Responsable | Descripción |
|---|---|---|---|---|
| [ ] | LR-1 | #24 | A | [logreg] Spec del modelo: justificacion, espacio de busqueda, desbalance |
| [ ] | LR-2 | #25 | A | [logreg] Modulo del modelo (contrato NAME/SEARCH/get_estimator/get_param_grid) + test |
| [ ] | LR-3 | #26 | A | [logreg] Baseline sin tuning con el pipeline comun (set base) |
| [ ] | LR-4 | #27 | A | [logreg] Busqueda de hiperparametros (GridSearchCV) con CV temporal y scoring f1_macro |
| [ ] | LR-5 | #28 | A | [logreg] Evaluacion en test y ablacion de features (base, con_participaciones, sin_potencia) |
| [ ] | LR-6 | #29 | A | [logreg] Persistencia en Tablas 2 y 3 con run_id propio |
| [ ] | LR-7 | #30 | A | [logreg] Notebook e informe del modelo: interpretacion y analisis de errores |
| [ ] | RF-1 | #31 | B | [rf] Spec del modelo: justificacion, espacio de busqueda, desbalance |
| [ ] | RF-2 | #32 | B | [rf] Modulo del modelo (contrato NAME/SEARCH/get_estimator/get_param_grid) + test |
| [ ] | RF-3 | #33 | B | [rf] Baseline sin tuning con el pipeline comun (set base) |
| [ ] | RF-4 | #34 | B | [rf] Busqueda de hiperparametros (RandomizedSearchCV) con CV temporal y scoring f1_macro |
| [ ] | RF-5 | #35 | B | [rf] Evaluacion en test y ablacion de features (base, con_participaciones, sin_potencia) |
| [ ] | RF-6 | #36 | B | [rf] Persistencia en Tablas 2 y 3 con run_id propio |
| [ ] | RF-7 | #37 | B | [rf] Notebook e informe del modelo: interpretacion y analisis de errores |
| [x] | XG-1 | #38 | C | [xgb] Spec del modelo: justificacion, espacio de busqueda, desbalance |
| [ ] | XG-2 | #39 | C | [xgb] Modulo del modelo (contrato NAME/SEARCH/get_estimator/get_param_grid) + test |
| [ ] | XG-3 | #40 | C | [xgb] Baseline sin tuning con el pipeline comun (set base) |
| [ ] | XG-4 | #41 | C | [xgb] Busqueda de hiperparametros (RandomizedSearchCV) con CV temporal y scoring f1_macro |
| [ ] | XG-5 | #42 | C | [xgb] Evaluacion en test y ablacion de features (base, con_participaciones, sin_potencia) |
| [ ] | XG-6 | #43 | C | [xgb] Persistencia en Tablas 2 y 3 con run_id propio |
| [ ] | XG-7 | #44 | C | [xgb] Notebook e informe del modelo: interpretacion y analisis de errores |

## Fase 3 - Comparacion

| Hecho | Tarea | Issue | Responsable | Descripción |
|---|---|---|---|---|
| [ ] | CMP-2 | #45 | A | compare_runs(): consulta consolidada de los 3 run_id (mismo split y semilla) |
| [ ] | CMP-3 | #46 | C | Graficos de comparacion: metricas, matrices lado a lado, F1 por clase, tiempos, ablacion |
| [ ] | CMP-4 | #47 | B | Analisis comparativo: ganador, incertidumbre, deriva estacional |
| [ ] | CMP-5 | #48 | A+B+C | Decision del modelo final segun el criterio de CMP-1 |

## Fase 4 - Cierre

| Hecho | Tarea | Issue | Responsable | Descripción |
|---|---|---|---|---|
| [ ] | V-1 | #49 | C | Dashboard Streamlit: modelos, comparacion, predicciones y calidad de datos |
| [ ] | F-1 | #50 | B | run_all.py + test de integracion (ETL -> 3 modelos -> BD) |
| [ ] | F-2 | #51 | A+B+C | Revision cruzada final de codigo y specs (A->B, B->C, C->A) |
| [ ] | F-3 | #52 | A+B+C | Informe final y README (una seccion por integrante) |
| [ ] | F-4 | #53 | A+B+C | Ensayo de demo desde cero |
