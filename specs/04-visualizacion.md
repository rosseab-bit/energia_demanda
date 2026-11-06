# Spec 04 — Visualización y dashboard

Estado: **borrador v0.1** (se aprueba en la tarea T-01). Cualquier cambio se hace primero acá.

## 1. Objetivo
Mostrar de forma clara tres cosas, leyendo **únicamente** `db/demanda.db`:
1. **Los datos**: cómo se distribuyen las clases Normal / Alta / Crítica, cómo se relacionan la demanda y la temperatura, y cómo es la estacionalidad.
2. **Los resultados de los modelos**: métricas y matriz de confusión de cada corrida (`run_id`) y las predicciones mes a mes.
3. **La calidad de los datos**: qué cargó el ETL y con qué advertencias.

Cubre el requerimiento **RF-5** de `PLAN_SDD.md §1.2` (gráficos y tablas claras, más un dashboard Streamlit con comparación de modelos).

## 2. Alcance

| Entra | No entra |
|---|---|
| `src/demanda/viz/plots.py`: funciones de gráficos (tareas VIZ-1 y CMP-3) | Forecasting (predecir meses futuros) |
| `src/demanda/viz/app.py`: dashboard Streamlit (tarea V-1) | API REST |
| Mensajes claros cuando faltan datos o corridas | Despliegue productivo |
| | Entrenar o recalcular métricas desde el dashboard |

Responsable: **C**. Los gráficos de comparación dependen de `compare_runs()` (CMP-2, **A**), así que el formato de esa entrada se acuerda en T-01 (ver §8).

## 3. Fuentes de datos
El dashboard y los gráficos no calculan métricas ni etiquetas: **leen lo que ya está guardado**. Esquema de referencia: `src/demanda/db/schema.sql` (tarea T-03, de A). Si cambia el esquema, esta tabla se actualiza primero.

| Tabla | Qué se usa | Para qué vista |
|---|---|---|
| `datos_limpios` | `fecha`, `demanda_total`, `temperatura_promedio`, `potencia_maxima`, `mes`, `anio`, `estacion`, `etiqueta`, `split` | Pestaña **Datos** (VIZ-1) |
| `predicciones` | `run_id`, `fecha`, `modelo`, `y_real`, `y_pred`, `prob_normal`, `prob_alta`, `prob_critica` | Pestaña **Predicciones** |
| `metricas_modelo` | `run_id`, `modelo`, accuracy, precision/recall/F1 macro y por clase, `matriz_confusion` (JSON, orden Normal/Alta/Crítica), `cv_best_score`, `tiempo_entrenamiento_s`, `n_train`, `n_test` | Pestañas **Modelos** y **Comparación** |
| `config_modelo` | `run_id`, `mejores_params`, `features_usadas`, `umbrales_etiqueta`, `semilla`, `cv_folds`, `scoring` | Pestaña **Modelos** (detalle de cada corrida) |
| `etl_auditoria` | `archivo`, `sha256`, filas leídas y cargadas, `nulos_json`, `umbrales_json`, `advertencias_json` | Pestaña **Calidad de datos** |
| `demanda_distribuidora` | — | **No se usa en v1** (D6: distribuidoras fuera de v1) |

Reglas de lectura:
- Las columnas `prob_*` se interpretan **por nombre de clase**, nunca por posición: el orden de `classes_` en scikit-learn es alfabético (Alta, Crítica, Normal).
- `matriz_confusion` se guarda como JSON en el orden Normal / Alta / Crítica y se parsea al leerla.
- Los valores NULL (por ejemplo sectores anteriores a 2005) se muestran como vacíos, no como cero.
- La conexión a la base es de **solo lectura**: el dashboard nunca escribe.
