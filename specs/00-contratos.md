# Spec 00 — Contratos entre integrantes

Estado: **borrador v0.1, redactado por C a partir de las fichas `TAREAS_A.md` y `TAREAS_B.md`, `config/config.yaml` y `PLAN_SDD.md`**. Se aprueba en la tarea T-01 con los tres.

**Regla de cambio:** si hay que modificar algo de este archivo (columnas de Tabla 1, claves de `save_run` o `evaluate`, interfaz de modelo), **primero** se hace un PR a este archivo, aprobado por los 3, y recién después el código.

**Cómo leerlo:** cada contrato indica quién lo **provee** (su dueño) y quién lo **consume**. Lo que está marcado como *pendiente* es una decisión sin cerrar: no se debe implementar hasta resolverla.

---

## 1. Tabla 1 `datos_limpios` (ETL → modelos y dashboard)
Provee: **A** (esquema, T-03) y **C** (carga, ETL-4). Consumen: B, A, C.

Una fila por mes, clave `fecha` (primer día del mes, texto ISO `YYYY-MM-DD`).

| Columna | Tipo | Notas |
|---|---|---|
| `fecha` | TEXT, PK | Nunca es feature |
| `anio`, `mes`, `trimestre` | INTEGER | `mes` entre 1 y 12, `trimestre` entre 1 y 4 |
| `estacion` | TEXT | `Verano`, `Otoño`, `Invierno` o `Primavera` |
| `mes_sin`, `mes_cos` | REAL | Codificación cíclica del mes |
| `demanda_total` | REAL | **Nunca es feature** |
| `demanda_residencial`, `comercio_e_industria`, `grandes_usuarios` | REAL, NULL | Solo desde 2005-01. Suman exactamente `demanda_total` |
| `part_residencial`, `part_comercio_industria`, `part_grandes_usuarios` | REAL, NULL | Participaciones; los modelos usan estas, no los absolutos |
| `tiene_sectores` | INTEGER (0/1) | 1 desde 2005-01 |
| `temperatura_promedio`, `potencia_maxima` | REAL | |
| `demanda_ratio_tendencia` | REAL, NULL | **Nunca es feature**; de ahí sale la etiqueta |
| `etiqueta` | TEXT | `Normal`, `Alta` o `Crítica`. **Los modelos no la recalculan** |
| `split` | TEXT | `train` o `test`. **Los modelos no lo recalculan** |

Los NULL de sectores **no se imputan en el ETL**. Si hace falta imputar, ocurre dentro del `Pipeline` de scikit-learn.

Fuente del esquema: `src/demanda/db/schema.sql` (T-03). Ese archivo, cuando se mergee, es la referencia exacta; esta tabla debe coincidir con él.

## 2. Lectura de datos: `load_clean_data` (A → B, C)
```python
# demanda/db/repository.py  (tarea DB-1)
load_clean_data(db_path=None, desde_sectores=False) -> pd.DataFrame
```
- Devuelve `datos_limpios` **ordenado por fecha**, con `fecha` como `datetime` y los NULL como `NaN`.
- Con `desde_sectores=True` devuelve solo las filas con `tiene_sectores = 1`.
- No recalcula etiqueta ni split. Las columnas son exactamente las de §1.

## 3. Conjuntos de features y preprocesador (B → A, C)
Provee: **B** (MC-1). Consumen: los tres modelos.

**Columnas prohibidas como feature** (`config.yaml → modelado.columnas_prohibidas_como_feature`): `fecha`, `etiqueta`, `split`, `demanda_total`, `demanda_ratio_tendencia`. Ningún `feature_set` puede contener alguna; hay un test anti-fuga (MC-1).

**Conjuntos** (`config.yaml → modelado.feature_sets`), elegibles con `--features`:

| Nombre | Numéricas | Categóricas | `solo_con_sectores` |
|---|---|---|---|
| `base` | `mes_sin`, `mes_cos`, `temperatura_promedio`, `potencia_maxima` | `estacion` | no |
| `con_participaciones` | las de `base` + `part_residencial`, `part_comercio_industria`, `part_grandes_usuarios` | `estacion` | sí (desde 2005-01) |
| `sin_potencia` | `mes_sin`, `mes_cos`, `temperatura_promedio` | `estacion` | no |

```python
# demanda/models/preprocessing.py  (tarea MC-1)
build_preprocessor(cfg, feature_set="base") -> ColumnTransformer
get_feature_columns(cfg, feature_set) -> list[str]
```
- Numéricas: `SimpleImputer(median)` + `StandardScaler`. Categóricas: `SimpleImputer(most_frequent)` + `OneHotEncoder(handle_unknown="ignore")`.
- Falla con un mensaje claro si el `feature_set` no existe.
- Los 3 modelos usan **el mismo objeto**, sin lógica específica de un modelo.

## 4. Split y validación cruzada (B → A, C)
Provee: **B** (MC-2).

```python
# demanda/models/splits.py
get_train_test(df, feature_set, cfg) -> (train_df, test_df)
get_cv(cfg) -> TimeSeriesSplit
```
- Usa la columna `split` de `datos_limpios`; **no recalcula el corte**.
- Si el `feature_set` tiene `solo_con_sectores: true`, filtra `tiene_sectores = 1`.
- `get_cv` usa `cfg["validacion"]["n_splits_cv"]`. **Pendiente:** la clave `validacion` todavía no está en `config.yaml`; la agrega B en MC-2 (`n_splits_cv: 5`, `scoring: f1_macro`).
- `check_cv_class_presence(y, cv)` reporta qué clases faltan en cada fold. En los primeros folds puede faltar `Crítica`.

## 5. Evaluación: `evaluate` (B → A, C)
Provee: **B** (MC-3). Un solo `evaluate.py` para los 3 modelos y el mismo conjunto de test.

```python
# demanda/models/evaluate.py
evaluate(y_true, y_pred, labels=("Normal", "Alta", "Crítica")) -> dict
```
Claves devueltas, **exactamente estas** (son el contrato con `save_run`):

`accuracy`, `precision_macro`, `recall_macro`, `f1_macro`, `precision_normal`, `recall_normal`, `f1_normal`, `precision_alta`, `recall_alta`, `f1_alta`, `precision_critica`, `recall_critica`, `f1_critica`, `matriz_confusion`.

- `matriz_confusion`: lista de listas de `int`, filas = clase real, columnas = clase predicha, **orden Normal / Alta / Crítica**.
- Usa `zero_division=0` y etiquetas fijas, aunque una clase no aparezca en `y_true`.
- El resultado es serializable a JSON.

## 6. Persistencia: `save_run` (A ← B, A, C)
Provee: **A** (DB-2). Usan: el runner de B y los tres modelos.

```python
# demanda/db/repository.py
save_run(run_id, predictions_df, metrics_dict, config_dict, db_path=None) -> None
```
- Escribe en `predicciones`, `metricas_modelo` y `config_modelo` en **una sola transacción** (todo o nada).
- Un `run_id` repetido **falla con un error claro**; no sobrescribe en silencio.
- `db_path` por defecto sale de `config.yaml`.

**`predictions_df`** — columnas: `fecha`, `modelo`, `y_real`, `y_pred`, `prob_normal`, `prob_alta`, `prob_critica`.

**`metrics_dict`** — claves: `modelo`, las 14 claves de §5, y además `cv_best_score`, `tiempo_entrenamiento_s`, `n_train`, `n_test`. La matriz se guarda como JSON.

**`config_dict`** — claves: `modelo`, `grid_hiperparametros`, `mejores_params`, `umbrales_etiqueta`, `features_usadas`, `semilla`, `cv_folds`, `scoring`, y **`feature_set`** (agregada por la decisión V-D2 de `specs/04-visualizacion.md`, ver §10). Los dicts y listas se guardan como JSON.

### 6.1 Formato del `run_id`
`<modelo>_<feature_set>_<timestamp>`, por ejemplo `xgb_base_20261105T221500`. Lo arma el runner (MC-4). Los datos ficticios de la fixture (VIZ-2) usan el prefijo `fixture_`.

### 6.2 Probabilidades: mapeo por nombre de clase
`classes_` de scikit-learn es **alfabético** (`Alta`, `Crítica`, `Normal`), no `Normal`, `Alta`, `Crítica`. Por eso `predict_proba` se mapea a `prob_normal`, `prob_alta` y `prob_critica` **por nombre de clase, nunca por posición**. El runner lo implementa y tiene un test.

## 7. Comparación: `compare_runs` (A → C)
Provee: **A** (CMP-2). Consume: **C** (gráficos CMP-3 y dashboard).

```python
compare_runs(run_ids=None, db_path=None) -> pd.DataFrame
```
- Una fila por `run_id`, con: `modelo`, `feature_set`, accuracy, precision/recall/F1 macro, F1 y recall de cada clase, `cv_best_score`, `tiempo_entrenamiento_s` y `n_test`.
- Acordado en la decisión V-D1: incluye también `matriz_confusion` ya parseada y `features_usadas`.
- Verifica que todos los runs comparados comparten split y semilla (`config_modelo`) y avisa si no.
- **Pendiente:** A confirma la lista exacta de columnas por escrito antes de empezar CMP-2.
- No contiene lógica de decisión; el criterio de elección vive en `specs/03-comparacion.md`.

## 8. Contrato de modelos (A, B, C)
Cada modelo vive en `src/demanda/models/<modelo>.py` y expone la misma interfaz. El runner los descubre solo con `importlib`, así que agregar un modelo no toca archivos ajenos.

```python
NAME = "logreg"            # "logreg" | "rf" | "xgb"
SEARCH = "grid"            # "grid" | "random"
NEEDS_SAMPLE_WEIGHT = False  # opcional; True si el modelo necesita sample_weight (XGBoost)
def get_estimator(random_state: int): ...
def get_param_grid() -> dict: ...      # claves con prefijo "clf__"
def get_n_iter() -> int | None: ...
```
Se ejecuta con `python -m demanda.models.train --model logreg|rf|xgb --features base`.

### 8.1 `NEEDS_SAMPLE_WEIGHT` (propuesta de C, XG-1; **pendiente de aprobación de B**)
- XGBoost no tiene `class_weight` en multiclase. El módulo declara `NEEDS_SAMPLE_WEIGHT = True`.
- Entonces el runner calcula `compute_sample_weight("balanced", y_train)` y lo pasa como `fit_params={"clf__sample_weight": ...}`.
- Riesgo a resolver en XG-4 y MC-4: dentro de la validación cruzada, el vector de pesos debe corresponder a las filas de **cada fold**. Si se calcula con todo `train`, se filtra información del fold de validación. La solución se documenta cuando se elija.
- Si el atributo no existe, el runner lo trata como `False`.

### 8.2 Etiquetas de texto
El sistema siempre ve `Normal`, `Alta` y `Crítica`. XGBoost requiere clases enteras, así que su módulo codifica y decodifica internamente (XG-2).

## 9. Contrato de lectura para el dashboard (C ← A)
El dashboard lee solo `demanda.db`. Las funciones de lectura que necesita (`predicciones`, `metricas_modelo`, `config_modelo`, `etl_auditoria`) van en `repository.py` (decisión V-D6). **Pendiente:** definir la tarea e issue bajo la que se escriben y sus firmas.

## 10. Decisiones y cambios de contrato registrados
| ID | Cambio | Estado |
|---|---|---|
| V-D2 | Agregar la columna `feature_set` a `config_modelo` y la clave `feature_set` a `config_dict` | Acordado verbalmente; se ratifica con la aprobación de este PR. Afecta a T-03, DB-2 y MC-4 |
| V-D1 | `compare_runs()` incluye `matriz_confusion` y `features_usadas` | Acordado verbalmente; columnas finales las confirma A |
| V-D6 | Lecturas del dashboard en `repository.py` | Acordado verbalmente; falta tarea e issue |
| MC-2 | Agregar `validacion: {n_splits_cv: 5, scoring: f1_macro}` a `config.yaml` | Lo hace B en MC-2 |
| XG-1 | Contrato `NEEDS_SAMPLE_WEIGHT` | Propuesto por C; falta aprobación de B |
