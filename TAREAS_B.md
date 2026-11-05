# Tareas del Integrante B — Núcleo de modelado, validación del ETL y Random Forest

Complementa a `PLAN_SDD.md` (qué y cuándo) y `GUIA_EQUIPO.md` (cómo). Cada ficha trae un **prompt listo para pegar en tu agente de IA** (Claude Code). Antes de pegar un prompt, seguí el *arranque de tarea* de `GUIA_EQUIPO.md §3` (rama nueva, `git pull`, agente abierto en la raíz del repo para que lea `CLAUDE.md`).

**Tu foco:** que los 3 modelos se entrenen y evalúen con **exactamente las mismas reglas** (preprocesador, split, CV, métricas, runner), la validación de calidad del ETL y el modelo **Random Forest**. Lo que construís en `MC-*` lo usan A y C: es el punto más sensible del proyecto para que la comparación sea justa.

## Orden recomendado

| Orden | Semana | Tarea | Por qué en este orden |
|---|---|---|---|
| 1 | 1 | **T-01** Reunión de arranque | Tu parte: redactar el contrato de preprocesado/evaluación en `specs/00-contratos.md` |
| 2 | 1 | **ETL-2** Validate | Solo depende de T-01 |
| 3 | 1 | **MC-3** `evaluate.py` | Solo depende de T-01; se prueba con arrays chicos |
| 4 | 1–2 | **RF-1** Spec del modelo | Se puede escribir desde ya |
| 5 | 2 | **ETL-6** EDA de decisión | Necesita `demanda.db` (ETL-5 de C) |
| 6 | 2 | **MC-1** Preprocesador y **MC-2** Split/CV | Necesitan ETL-5 |
| 7 | 2–3 | **RF-2** y **MC-4** Runner | MC-4 espera a DB-1/DB-2 (de A) |
| 8 | 3–4 | **RF-3 → RF-7** | Tu modelo |
| 9 | 5 | **CMP-4** Análisis comparativo | Cuando C entregue CMP-3 |
| 10 | 6 | **F-1** `run_all.py` + CMP-1, CMP-5, F-2, F-3, F-4 | Cierre |

**Revisás los PRs de:** A (tus PRs los revisa C).

---

## ETL-2 · Validate
**Depende de:** T-01 · **Rama:** `feat/ETL-2-validate` · **Entregable:** `src/demanda/etl/validate.py` + tests

**Referencia:** `src/demanda/etl/validate.py` del zip. Distingue **errores** (detienen la carga) de **advertencias** (se guardan en `etl_auditoria`).

**Prompt para el agente**
```text
Tarea ETL-2 (Validate). Seguí CLAUDE.md y specs/01-datos.md (criterios ETL-2 y ETL-3). Tests primero
(tests/test_validate.py) con un DataFrame sintético pequeño con la misma forma que el CSV real.
Reglas de ERROR: columnas obligatorias ausentes; fechas nulas, duplicadas o que no sean día 1; meses faltantes;
nulos o negativos en demanda_total/temperatura_promedio/potencia_maxima; temperatura fuera de
cfg["etl"]["rango_temperatura"]; sectores parcialmente nulos (deben estar los 3 o ninguno); suma de sectores
distinta de demanda_total (tolerancia relativa de config).
Reglas de ADVERTENCIA (no detienen): sectores ausentes (describir los tramos de meses), distribuidoras
ausentes, cobertura promedio de distribuidoras sobre demanda_total, outliers |z| > cfg["etl"]["z_outlier"].
Un test por regla, y un test que confirme que los nulos esperados del CSV real son advertencia y no error.
```
**Aceptación:** una regla = un test · el CSV real pasa sin errores y produce las 3 advertencias esperadas · `ruff` limpio.

**Commits:** `test(ETL-2): un test por regla de validación` → `feat(ETL-2): implementa validate con errores y advertencias` → `docs(ETL-2): documenta reglas en specs/01-datos.md`

**Revisá vos:** que cada test de error falle si borrás la regla correspondiente (probalo comentando la regla).

---

## MC-3 · `evaluate.py`
**Depende de:** T-01 · **Rama:** `feat/MC-3-evaluate` · **Entregable:** `src/demanda/models/evaluate.py` + tests

**Prompt para el agente**
```text
Tarea MC-3. Creá src/demanda/models/evaluate.py con
evaluate(y_true, y_pred, labels=("Normal","Alta","Crítica")) -> dict
que devuelve EXACTAMENTE estas claves (son el contrato con save_run de A): accuracy, precision_macro,
recall_macro, f1_macro, precision_normal, recall_normal, f1_normal, precision_alta, recall_alta, f1_alta,
precision_critica, recall_critica, f1_critica, matriz_confusion (lista de listas de int, filas=real,
columnas=predicho, orden de labels). Usá sklearn.metrics con zero_division=0 y labels fijas (aunque una clase
no aparezca en y_true). Tests con arrays chicos calculados a mano: predicción perfecta, una clase ausente en
y_true, todo predicho como Normal. Verificá que el resultado es serializable a JSON (json.dumps).
```
**Aceptación:** claves idénticas al contrato · no falla si falta una clase · JSON-serializable.

**Commits:** `test(MC-3): tests con casos calculados a mano` → `feat(MC-3): implementa evaluate con métricas macro y por clase` → `docs(MC-3): documenta claves devueltas en specs/00-contratos.md`

---

## RF-1 · Spec del modelo
**Depende de:** T-01 · **Entregable:** `specs/02-modelo-rf.md`
```text
Tarea RF-1. Escribí specs/02-modelo-rf.md: por qué Random Forest (captura no linealidades, no necesita
escalado pero convive con el preprocesador común), desbalance (class_weight='balanced'), el espacio de
RandomizedSearchCV (n_estimators [100,200,400,600], max_depth [None,5,10,20], min_samples_leaf [1,2,5,10],
max_features ["sqrt","log2",0.5], n_iter=30; justificá el rango y n_iter con el tamaño de muestra), scoring
f1_macro, riesgo de sobreajuste con 246 filas de train, y criterios de aceptación de RF-2…RF-7.
Interpretación: importancia por impureza (sesgada) + importancia por permutación. Sin código.
```
**Commits:** `docs(RF-1): justifica el modelo y el tratamiento del desbalance` → `docs(RF-1): define espacio de búsqueda y criterios`

---

## ETL-6 · EDA de decisión (D1 y D2)
**Depende de:** ETL-5 · **Rama:** `docs/ETL-6-eda` · **Entregable:** `notebooks/01_eda.ipynb` + recomendación en `specs/01-datos.md`

**Prompt para el agente**
```text
Tarea ETL-6. Notebook notebooks/01_eda.ipynb que lee SOLO desde db/demanda.db (generala con scripts/run_etl.py).
Secciones: (1) calidad: nulos por bloque de fechas y advertencias de etl_auditoria; (2) tendencia y
estacionalidad de demanda_total (promedio anual, perfil por mes, amplitud del pico por año); (3) D1: comparar
los métodos de etiqueta percentil_global vs relativo_tendencia — distribución de clases por split y por año
(demostrá con datos que percentil_global concentra lo reciente en Crítica); (4) D2: demostrar la fuga: un modelo
trivial con los sectores en valores absolutos reconstruye la etiqueta casi perfecto, contra uno con
participaciones o sin sectores; correlación de potencia_maxima con demanda_total; (5) balance de clases y qué
significa para test (3 Alta). Cerrá con una RECOMENDACIÓN por decisión (D1, D2, D4) que el equipo pueda
aprobar. Gráficos claros con matplotlib/seaborn, títulos y ejes en español. No guardes nada en la BD.
```
**Aceptación:** cada recomendación apoyada en un gráfico o número del notebook · el notebook corre de punta a punta · conclusiones llevadas a `specs/01-datos.md §4`.

**Commits:** `docs(ETL-6): EDA de calidad, tendencia y estacionalidad` → `docs(ETL-6): comparación de métodos de etiqueta (D1)` → `docs(ETL-6): demostración de fuga por sectores y recomendación (D2)`

**Revisá vos:** si la recomendación cambia el método de etiqueta, avisá a A (ETL-3) y a C antes de mergear.

---

## MC-1 · Preprocesador común
**Depende de:** T-01, ETL-5 · **Rama:** `feat/MC-1-preprocessing` · **Entregable:** `src/demanda/models/preprocessing.py` + tests
```text
Tarea MC-1. Creá build_preprocessor(cfg, feature_set="base") -> ColumnTransformer usando
cfg["modelado"]["feature_sets"][feature_set] (numericas, categoricas). Numéricas: SimpleImputer(median) +
StandardScaler. Categóricas: SimpleImputer(most_frequent) + OneHotEncoder(handle_unknown="ignore"). Devolvé
también get_feature_columns(cfg, feature_set). Tests primero: (a) ANTI-FUGA: ninguna columna de
cfg["modelado"]["columnas_prohibidas_como_feature"] aparece en ningún feature_set; (b) el preprocesador
ajustado solo con train transforma test sin error y con la misma forma; (c) un NaN en una numérica se imputa
con la mediana de TRAIN; (d) get_feature_names_out devuelve nombres legibles. Fallá con mensaje claro si el
feature_set no existe. Los 3 modelos usan este mismo objeto: no agregues lógica específica de un modelo.
```
**Aceptación:** test anti-fuga verde para los 3 sets · sin `fit` sobre test · nombres de columnas disponibles para la interpretación.

**Commits:** `test(MC-1): test anti-fuga y de forma de salida` → `feat(MC-1): build_preprocessor desde feature_sets` → `docs(MC-1): documenta feature sets en specs/00-contratos.md`

---

## MC-2 · Split y validación cruzada
**Depende de:** ETL-5 · **Rama:** `feat/MC-2-splits` · **Entregable:** `src/demanda/models/splits.py` + tests + clave en `config.yaml`
```text
Tarea MC-2. Creá splits.py: get_train_test(df, feature_set, cfg) -> (train_df, test_df) usando la columna
`split` de datos_limpios (NO recalcules el corte) y filtrando tiene_sectores=1 si el feature_set tiene
solo_con_sectores=true; get_cv(cfg) -> TimeSeriesSplit(n_splits=cfg["validacion"]["n_splits_cv"]). Agregá a
config/config.yaml: validacion: {n_splits_cv: 5, scoring: f1_macro}. Tests: todas las fechas de train son
anteriores a las de test; sin solapamiento; con solo_con_sectores=true la primera fecha es 2005-01-01; en cada
fold de TimeSeriesSplit el train es anterior al valid. IMPORTANTE: en los primeros folds puede faltar la clase
Crítica (los picos eran chicos en 2001-2005). Escribí una función check_cv_class_presence(y, cv) que reporte
qué clases faltan en cada fold, y comentame qué implica para f1_macro.
```
**Aceptación:** sin fuga temporal comprobada por test · advertencia de clases ausentes por fold · config actualizada.

**Commits:** `test(MC-2): tests de orden temporal y filtro de sectores` → `feat(MC-2): get_train_test y get_cv` → `feat(MC-2): chequeo de clases por fold` → `chore(MC-2): agrega validacion a config.yaml`

---

## MC-4 · Runner `train.py`
**Depende de:** MC-1, MC-2, MC-3, DB-1, DB-2 · **Rama:** `feat/MC-4-runner` · **Entregable:** `src/demanda/models/train.py` + tests
```text
Tarea MC-4. Creá src/demanda/models/train.py ejecutable como
python -m demanda.models.train --model logreg|rf|xgb --features base|con_participaciones|sin_potencia
Pasos: (1) importlib.import_module(f"demanda.models.{model}") — autodescubrimiento, no hay lista de modelos;
(2) cargar datos con repository.load_clean_data y separar con splits.get_train_test; (3) armar
Pipeline([("prep", build_preprocessor(cfg, feature_set)), ("clf", mod.get_estimator(seed))]);
(4) GridSearchCV si mod.SEARCH=="grid" o RandomizedSearchCV(n_iter=mod.get_n_iter(), random_state=seed) si
"random", con cv=get_cv(cfg), scoring de config, refit=True, SOLO sobre train; (5) si el módulo define
NEEDS_SAMPLE_WEIGHT=True, calcular compute_sample_weight("balanced", y_train) y pasarlo como
fit_params={"clf__sample_weight": ...}; (6) predecir en test con probabilidades, evaluar con evaluate.py,
medir tiempo, y guardar con save_run (run_id = f"{model}_{features}_{timestamp}"). Las columnas de
predict_proba siguen el orden de pipeline.classes_ (alfabético: Alta, Crítica, Normal), así que mapealas a
prob_normal/prob_alta/prob_critica por NOMBRE de clase, nunca por posición, y testealo; (7) imprimir resumen.
Tests con un modelo falso (módulo dummy en tests/) para no depender de A ni C: verifica descubrimiento,
que test no entra al fit, que se guarda un run y que NEEDS_SAMPLE_WEIGHT se respeta. El contrato
NEEDS_SAMPLE_WEIGHT debe documentarse en specs/00-contratos.md y acordarse con C (XG-1).
```
**Aceptación:** el mismo comando corre los 3 modelos · no hay `if model == ...` · test con módulo dummy verde.

**Commits:** `docs(MC-4): contrato del runner y NEEDS_SAMPLE_WEIGHT` → `test(MC-4): tests con modelo dummy` → `feat(MC-4): runner con autodescubrimiento y búsqueda` → `feat(MC-4): persistencia vía save_run y resumen en consola`

**Revisá vos:** buscá en el código cualquier uso de `test_df` antes del `.predict`. Ese es el error que invalida la comparación.

---

## RF-2 … RF-7 · Modelo Random Forest
Archivos: `specs/02-modelo-rf.md`, `src/demanda/models/rf.py`, `tests/test_rf.py`, `notebooks/03_rf.ipynb`. Mismo preprocesador, split, CV y `evaluate` que los otros modelos (los construiste vos en MC-*).

### RF-2 · Módulo del modelo
**Depende de:** RF-1, T-03 · **Entregable:** `models/rf.py` + `tests/test_rf.py`
```text
Tarea RF-2. Tests primero. Implementá src/demanda/models/rf.py con el contrato de CLAUDE.md: NAME="rf",
SEARCH="random", get_estimator(random_state) -> RandomForestClassifier(class_weight="balanced",
random_state=random_state, n_jobs=-1), get_param_grid() con claves "clf__n_estimators", "clf__max_depth",
"clf__min_samples_leaf", "clf__max_features" según RF-1, get_n_iter() -> 30. Tests: tiene predict_proba y
class_weight balanced; claves con prefijo clf__; n_iter es entero positivo y no mayor que el tamaño de la grilla.
```
**Commits:** `test(RF-2): test del contrato del módulo rf` → `feat(RF-2): implementa rf con class_weight balanced` → `docs(RF-2): docstrings`

### RF-3 · Baseline
**Depende de:** RF-2, MC-1, MC-2
```text
Tarea RF-3. Con build_preprocessor("base") y el split de la columna `split`, entrená RandomForestClassifier con
parámetros por defecto (class_weight balanced, semilla de config), predecí en test y calculá F1 macro, Recall de
Crítica y matriz de confusión con evaluate.py. Mostrame los números y compará con el baseline de logreg si ya
existe (sin copiarle nada a A: solo leé su resultado de demanda.db).
```
**Commits:** `test(RF-3): test de reproducibilidad` → `feat(RF-3): baseline de rf con el pipeline común`

### RF-4 · Búsqueda de hiperparámetros
**Depende de:** RF-3
```text
Tarea RF-4. RandomizedSearchCV (n_iter=30, random_state=semilla) sobre Pipeline(prep+clf), cv=get_cv(cfg),
scoring f1_macro, SOLO con train. Registrá mejores parámetros, cv_best_score y tiempo. Corrélo con el
runner (MC-4) si ya existe. Mirá la brecha entre cv_best_score y F1 en test: con 246 filas un RF puede
sobreajustar; si la brecha es grande, proponé restringir max_depth/min_samples_leaf en la spec (con commit
docs) y no sólo en el código. Verificá que test no participa del ajuste.
```
**Commits:** `feat(RF-4): RandomizedSearchCV con CV temporal` → `test(RF-4): test de que la búsqueda no usa test` → `docs(RF-4): resultados y análisis de sobreajuste`

### RF-5 · Evaluación y ablación
**Depende de:** RF-4, MC-3
```text
Tarea RF-5. Evaluá el mejor RF en test con evaluate.py y repetí con los 3 feature_sets (base,
con_participaciones, sin_potencia). Tabla comparativa por set. Interpretá cuánto depende de potencia_maxima y
de las participaciones sectoriales. Solo conclusiones que los números sostengan (3 Alta en test).
```
**Commits:** `feat(RF-5): evaluación en test` → `feat(RF-5): ablación por feature set` → `docs(RF-5): tabla comparativa`

### RF-6 · Persistencia
**Depende de:** RF-5, MC-4, DB-2
```text
Tarea RF-6. Persistí con save_run (run_id único por feature set, ej. rf_base_<timestamp>) y verificá con SQL:
n_test filas en predicciones por run, matriz de confusión parseable, features_usadas coherente, mismos
semilla y split que logreg y xgb (config_modelo).
```
**Commits:** `feat(RF-6): persiste runs de rf en Tablas 2 y 3` → `test(RF-6): verifica filas y JSON guardados`

### RF-7 · Notebook e interpretación
**Depende de:** RF-6 · **Entregable:** `notebooks/03_rf.ipynb` + sección en `docs/model_card.md`
```text
Tarea RF-7. Notebook que lee desde demanda.db. Importancia de variables por impureza Y por permutación
(sklearn.inspection.permutation_importance sobre test) con nombres de get_feature_names_out; comentá por qué
difieren. Análisis de errores: qué meses se confunden (picos de dic/ene/jul, transición Alta↔Crítica) y el efecto
de la deriva del pico estacional. Limitaciones honestas.
```
**Commits:** `docs(RF-7): notebook de métricas e importancias` → `docs(RF-7): análisis de errores en model_card`

---

## CMP-4 · Análisis comparativo
**Depende de:** CMP-3 · **Rama:** `docs/CMP-4-analisis` · **Entregable:** `notebooks/05_comparacion.ipynb`
```text
Tarea CMP-4. Notebook que lee compare_runs() de demanda.db y los gráficos de CMP-3. Aplicá los criterios de
specs/03-comparacion.md (fijados ANTES de ver resultados) y respondé: qué modelo gana y por qué; diferencias
por clase (Recall de Crítica); costo (tiempo) vs beneficio; sensibilidad a potencia_maxima (ablación); qué tan
confiable es la diferencia dado que test tiene 62 meses y 3 Alta (si podés, intervalos por bootstrap sobre
test). No declares ganador si la diferencia está dentro del ruido: decilo.
```
**Commits:** `docs(CMP-4): comparación de métricas según CMP-1` → `docs(CMP-4): análisis de incertidumbre y conclusiones`

## F-1 · `run_all.py`
**Depende de:** CMP-2 · **Rama:** `feat/F-1-run-all` · **Entregable:** `scripts/run_all.py` + test de integración
```text
Tarea F-1. scripts/run_all.py ejecuta: ETL (run_etl) → los 3 modelos × 3 feature sets (o los que indique
--features) → compare_runs → imprime la tabla. Parámetro --reset para empezar de cero. Test de integración
con el CSV real en una BD temporal que verifique que quedan 9 runs en metricas_modelo (o los esperados) y
que no hay errores. Debe correr en el CI con un presupuesto de tiempo razonable (reducí n_iter con una
variable de entorno RAPIDO=1 solo para el test).
```
**Commits:** `test(F-1): test de integración de punta a punta` → `feat(F-1): run_all con --reset y --features` → `docs(F-1): instrucciones de ejecución en el README`

---

## Tareas conjuntas (las tres personas)

| ID | Tu parte |
|---|---|
| **T-01** | Redactar el contrato de preprocesado, evaluación y runner en `specs/00-contratos.md` |
| **CMP-1** | Proponer la métrica principal (F1 macro), el desempate (Recall de Crítica) y el tratamiento de la incertidumbre |
| **CMP-5** | Decisión final del modelo |
| **F-2** | Revisar los PRs de A |
| **F-3 / F-4** | Sección "Núcleo de modelado y Random Forest" del informe; ensayo de demo |

## Checklist final de B
- [ ] Los 3 modelos usan el mismo `build_preprocessor`, `get_train_test`, `get_cv` y `evaluate` (sin duplicados).
- [ ] Ninguna fila de test participa del ajuste, de la CV ni del `fit` del preprocesador.
- [ ] `python -m demanda.models.train --model rf --features base` corre de punta a punta.
- [ ] 7 tareas RF cerradas con 3+ commits cada una.
- [ ] Puedo explicar por qué hay riesgo de sobreajuste con 246 filas.
