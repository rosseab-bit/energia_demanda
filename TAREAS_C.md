# Tareas del Integrante C — Infraestructura, Load del ETL, Visualización y XGBoost

Complementa a `PLAN_SDD.md` (qué y cuándo) y `GUIA_EQUIPO.md` (cómo). Cada ficha trae un **prompt listo para pegar en tu agente de IA** (Claude Code). Antes de pegar un prompt, seguí el *arranque de tarea* de `GUIA_EQUIPO.md §3` (rama nueva, `git pull`, agente abierto en la raíz del repo para que lea `CLAUDE.md`). La única excepción es **T-00**, que arranca antes de que exista el repo.

**Tu foco:** dejar el repositorio y la CI funcionando desde el día 1 (de eso depende que los otros dos puedan trabajar), cargar los datos a SQLite de forma segura (Load), todo lo visual (gráficos y dashboard) y el modelo **XGBoost**.

## Orden recomendado

| Orden | Semana | Tarea | Por qué en este orden |
|---|---|---|---|
| 1 | 1 (día 1–2) | **T-00** Repo y esqueleto | **Bloquea a todos.** Hacela primero y avisá |
| 2 | 1 | **T-15** CI | Cada PR posterior depende de este check |
| 3 | 1 | **T-01** Reunión de arranque | Tu parte: redactar el contrato de visualización (`specs/04-visualizacion.md`) |
| 4 | 1 | **XG-1** Spec del modelo | Sin dependencias; resolvé con B el contrato de `sample_weight` |
| 5 | 1–2 | **ETL-4** Load y **VIZ-2** BD fixture | Necesitan `schema.sql` (T-03 de A) |
| 6 | 2 | **ETL-5** Pipeline + CLI | Necesita ETL-1…4. **Desbloquea a B** (MC-1, MC-2, ETL-6) |
| 7 | 2–3 | **VIZ-1** `plots.py` base y **XG-2** | |
| 8 | 3–4 | **XG-3 → XG-7** | Tu modelo |
| 9 | 4–5 | **CMP-3** gráficos de comparación y **V-1** dashboard | Cuando A entregue `compare_runs` |
| 10 | 6 | CMP-1, CMP-5, F-2, F-3, F-4 | Cierre |

**Revisás los PRs de:** B (tus PRs los revisa A).

---

## T-00 · Repo y esqueleto
**Depende de:** nada · **Rama:** `main` (único commit directo permitido: el inicial) y luego `chore/T-00-esqueleto` · **Entregable:** repo clonable donde `pip install -e . && pytest` funciona

**Qué entra en T-00 y qué NO** (para que el historial muestre quién escribió cada parte):

| Entra en T-00 (tuyo) | NO entra: lo incorpora su dueño en su tarea |
|---|---|
| `pyproject.toml`, `requirements.txt`, `.gitignore`, `config/config.yaml`, `CLAUDE.md`, `README.md` | `etl/extract.py`, `transform.py` (A) |
| `src/demanda/__init__.py`, `config.py`, paquetes vacíos | `etl/validate.py` (B) |
| `data/raw/demanda_electricidad_original_mensual1.csv` | `etl/load.py`, `pipeline.py` (C, en ETL-4/5) |
| `PLAN_SDD.md`, `GUIA_EQUIPO.md`, `TAREAS_A/B/C.md`, `scripts/crear_issues.sh` | `schema.sql` (A, en T-03) |
| `CODEOWNERS`, `.github/pull_request_template.md` | Todos los tests |

**Prompt para el agente**
```text
Tarea T-00. Estoy en una carpeta con el contenido del zip del proyecto (proyecto-demanda/). Quiero armar el
repositorio inicial SIN incluir todavía los módulos que tienen dueño en otras tareas (etl/extract.py,
transform.py, validate.py, load.py, pipeline.py, schema.sql, scripts/run_etl.py y tests/).
1) Mostrame qué archivos del zip van al commit inicial según la tabla de TAREAS_C.md (T-00) y cuáles se quedan
   fuera. Guardá los que se quedan fuera en una carpeta ../referencia_etl (no la subas al repo).
2) Creá CODEOWNERS con estas reglas (usuarios de GitHub en <A>, <B>, <C>): src/demanda/etl/extract.py y
   transform.py, src/demanda/db/ y models/logreg.py -> <A>; etl/validate.py, models/{preprocessing,splits,
   evaluate,train,rf}.py -> <B>; etl/load.py, etl/pipeline.py, viz/ y models/xgb.py -> <C>; specs/ y config/ -> todos.
3) Creá .github/pull_request_template.md con: resumen, issue (Closes #), tareas hechas, cómo probarlo, checklist
   del DoD de PLAN_SDD.md §6 y checklist del revisor de GUIA_EQUIPO.md.
4) Escribí README.md corto: objetivo, requisitos, instalación, comandos (CLAUDE.md los lista) y enlaces.
5) Verificá que `pip install -e .` funciona y que `python -c "from demanda.config import load_config; print(load_config()['semilla'])"`
   imprime 42.
Proponé los mensajes de commit (uno por bloque lógico: chore(T-00) para configuración, docs(T-00) para
documentos). No hagas push; lo hago yo.
```
**Pasos manuales en GitHub** (el agente no los hace):
1. Crear el repo, subir los commits y **invitar a A y B** como colaboradores.
2. `Settings → Branches → Add rule` para `main`: requerir PR, 1 aprobación, status checks (cuando exista T-15), **sin push directo**, sin force-push.
3. `Settings → General → Pull Requests`: habilitar solo **"Allow merge commits"** (desactivar *squash* y dejar *rebase* opcional) para conservar los commits de cada uno.
4. Ejecutar `scripts/crear_issues.sh` (ver `GUIA_EQUIPO.md §2`).

**Aceptación:** los otros dos clonan, instalan y corren `python -c "…load_config…"` sin errores · `main` protegida · issues creados.

**Commits:** `chore(T-00): estructura, pyproject y configuración inicial` → `docs(T-00): plan, guía y fichas de tareas` → `chore(T-00): CODEOWNERS y plantilla de PR` → `docs(T-00): README con instalación y comandos`

---

## T-15 · CI en GitHub Actions
**Depende de:** T-00 · **Rama:** `chore/T-15-ci` · **Entregable:** `.github/workflows/ci.yml`
```text
Tarea T-15. Creá .github/workflows/ci.yml que en cada push y pull_request: use Python 3.11 con caché de pip,
instale requirements.txt y `pip install -e .`, corra `ruff check src tests` y `pytest -q`. Un solo job
llamado "test". Si todavía no hay tests, que `pytest` no falle por "no tests collected" (usá
`pytest -q || [ $? -eq 5 ]` y dejá un comentario que lo explique, a eliminar cuando entre el primer test).
Después de mergear, indicame cómo marcar el job "test" como required check en la regla de protección de main.
```
**Aceptación:** el job corre en un PR de prueba y queda como *required* · falla si el lint o un test falla.

**Commits:** `chore(T-15): workflow de CI con ruff y pytest` → `docs(T-15): cómo marcar el check como obligatorio`

---

## ETL-4 · Load
**Depende de:** T-03 · **Rama:** `feat/ETL-4-load` · **Entregable:** `src/demanda/etl/load.py` + tests

**Referencia:** `src/demanda/etl/load.py` del zip.

**Prompt para el agente**
```text
Tarea ETL-4 (Load). Seguí CLAUDE.md y specs/01-datos.md (criterios ETL-7 y ETL-8). Tests primero
(tests/test_load.py) con una BD temporal (tempfile), después implementación.
Funciones: connect(db_path), init_schema(conn, schema_path, reset=False) y
load(conn, datos_limpios, distribuidoras, auditoria) -> dict.
Requisitos: (a) la carga es ATÓMICA: `with conn:` y si algo falla no queda nada a medias; (b) IDEMPOTENTE:
correr dos veces deja 308 filas, no 616, y 2 filas en etl_auditoria; (c) NaN se guarda como NULL; (d) NO
borra predicciones/metricas_modelo/config_modelo (solo reset=True las borra); (e) etl_run_id incluye
microsegundos (dos corridas en el mismo segundo no pueden pisarse). Tests: idempotencia, NULL en sectores
anteriores a 2005, rollback (un valor que viola un CHECK deja la corrida anterior intacta), que reset=True
borra los resultados de modelos y reset=False los conserva.
```
**Aceptación:** los 5 comportamientos probados · sin SQL armado con datos del usuario (solo `?` para valores).

**Commits:** `test(ETL-4): tests de idempotencia, NULL, rollback y reset` → `feat(ETL-4): carga transaccional e idempotente` → `feat(ETL-4): auditoría de corrida con SHA-256` → `docs(ETL-4): política de re-ejecución en GUIA_EQUIPO.md`

**Revisá vos:** el test de rollback debe romper algo *a mitad de la carga* (no antes de empezar) para probar de verdad la atomicidad.

---

## ETL-5 · Pipeline + CLI
**Depende de:** ETL-1, ETL-2, ETL-3, ETL-4 · **Rama:** `feat/ETL-5-pipeline` · **Entregable:** `etl/pipeline.py`, `scripts/run_etl.py`, test de integración

**Referencia:** `pipeline.py` y `scripts/run_etl.py` del zip.

**Prompt para el agente**
```text
Tarea ETL-5. Creá etl/pipeline.py con run_etl(config_path=None, reset=False, csv_path=None, db_path=None)
que encadena extract -> assert_valid -> transform -> init_schema -> load y devuelve un resumen (filas,
umbrales, advertencias, distribución de etiquetas por split). scripts/run_etl.py es el CLI (argparse:
--config, --reset): imprime el resumen, y si la validación falla imprime el error y sale con código 1 SIN
escribir nada en la BD. Test de integración con el CSV real y una BD temporal: 308 filas en datos_limpios,
3450 en demanda_distribuidora (150 meses x 23 distribuidoras), sectores desde 2005-01-01, las 3 clases
presentes en train, 1 fila de auditoría. Test de CLI: un CSV inválido (fecha duplicada) devuelve 1 y deja la
BD vacía de datos. Al terminar corré `python scripts/run_etl.py` y pegame la salida.
```
**Aceptación:** `python scripts/run_etl.py` genera `db/demanda.db` · falla limpio con datos inválidos · **avisar a A y B apenas esté mergeado** (los desbloquea).

**Commits:** `test(ETL-5): integración con el CSV real y caso inválido` → `feat(ETL-5): run_etl encadena E-V-T-L` → `feat(ETL-5): CLI run_etl.py con --reset` → `docs(ETL-5): comando en README`

---

## VIZ-2 · BD fixture para tests y dashboard
**Depende de:** T-03 · **Rama:** `test/VIZ-2-fixture` · **Entregable:** `tests/fixtures.py`
```text
Tarea VIZ-2. Creá tests/fixtures.py con make_fixture_db(path) que crea una BD con el schema.sql real y la llena
con DATOS FICTICIOS pero con la forma exacta de las tablas: 36 meses en datos_limpios (con etiquetas y split),
y 3 runs de resultados (run_id con prefijo "fixture_", modelos logreg/rf/xgb) en predicciones,
metricas_modelo y config_modelo, con métricas inventadas pero coherentes (matriz de confusión que suma
n_test). Marcá los datos como ficticios en comentarios y en un campo reconocible (prefijo fixture_) para
que nunca se confundan con resultados reales. Tests que verifiquen que las 3 tablas quedan pobladas y que
respeta los CHECKs. Es lo que usarán A (CMP-2) y vos (VIZ-1, CMP-3, V-1) para trabajar sin esperar a los modelos.
```
**Commits:** `test(VIZ-2): fixture con datos ficticios y 3 runs` → `docs(VIZ-2): aclara que son datos ficticios`

---

## VIZ-1 · `plots.py` base
**Depende de:** ETL-5 · **Rama:** `feat/VIZ-1-plots` · **Entregable:** `src/demanda/viz/plots.py` + tests de humo
```text
Tarea VIZ-1. Creá src/demanda/viz/plots.py con funciones PURAS (reciben DataFrames, devuelven una figura de
matplotlib o plotly; no leen la BD ni llaman a plt.show): plot_clases_por_split, plot_demanda_vs_temperatura
(dispersión coloreada por etiqueta), plot_estacionalidad (perfil por mes con la banda por año),
plot_serie_con_criticos (serie de demanda_total con los meses Crítica marcados y la línea de corte
train/test). Títulos, ejes y leyendas en español, con unidades "PENDIENTE" si D7 no está resuelto. Paleta que
distinga Normal/Alta/Crítica de forma accesible (no solo por color: usá también marcador o forma). Tests de
humo con la fixture (VIZ-2): cada función devuelve una figura y no lanza con una BD de 36 meses ni con la real.
```
**Aceptación:** 4 funciones puras · accesibles (no dependen solo del color) · tests de humo verdes.

**Commits:** `test(VIZ-1): tests de humo de cada gráfico` → `feat(VIZ-1): gráficos de clases y demanda vs temperatura` → `feat(VIZ-1): gráficos de estacionalidad y serie con críticos`

---

## XG-1 … XG-7 · Modelo XGBoost
Archivos: `specs/02-modelo-xgb.md`, `src/demanda/models/xgb.py`, `tests/test_xgb.py`, `notebooks/04_xgb.ipynb`. Mismo preprocesador, split, CV y `evaluate` que los otros dos (no los reimplementes).

### XG-1 · Spec del modelo
**Depende de:** T-01 · **Entregable:** `specs/02-modelo-xgb.md` + acuerdo con B
```text
Tarea XG-1. Escribí specs/02-modelo-xgb.md: por qué XGBoost (boosting, interacciones no lineales), y los DOS puntos
delicados: (1) etiquetas: XGBoost requiere clases enteras; el módulo debe codificar/decodificar
internamente para que el sistema siga viendo "Normal/Alta/Crítica"; (2) desbalance: en multiclase no hay
class_weight; se usa sample_weight=compute_sample_weight("balanced", y_train) pasado al fit. Propuesta de
contrato para el runner: el módulo declara NEEDS_SAMPLE_WEIGHT = True y el runner pasa
fit_params={"clf__sample_weight": ...}. Espacio de RandomizedSearchCV (n_estimators [100,200,400],
max_depth [3,5,7], learning_rate [0.03,0.1,0.3], subsample/colsample_bytree [0.7,0.9,1.0], reg_lambda
[1,5,10], n_iter=30; justificá con 246 filas de train). Criterios de aceptación de XG-2…XG-7. Sin código.
Dejá el contrato NEEDS_SAMPLE_WEIGHT como PR a specs/00-contratos.md para que lo apruebe B (MC-4).
```
**Commits:** `docs(XG-1): justifica el modelo, etiquetas enteras y sample_weight` → `docs(XG-1): espacio de búsqueda y criterios` → `docs(XG-1): propone contrato NEEDS_SAMPLE_WEIGHT`

### XG-2 · Módulo del modelo
**Depende de:** XG-1, T-03 · **Entregable:** `models/xgb.py` + `tests/test_xgb.py`
```text
Tarea XG-2. Tests primero. Implementá src/demanda/models/xgb.py con el contrato de CLAUDE.md: NAME="xgb",
SEARCH="random", NEEDS_SAMPLE_WEIGHT=True, get_estimator(random_state), get_param_grid() (claves "clf__..."),
get_n_iter() -> 30. get_estimator debe devolver un estimador compatible con sklearn que ACEPTE y DEVUELVA las
etiquetas de texto ("Normal","Alta","Crítica"): un wrapper (o subclase de XGBClassifier) que codifique con
LabelEncoder en fit y decodifique en predict, y exponga classes_ con los strings. Tiene que funcionar con
sklearn.base.clone, dentro de Pipeline y de RandomizedSearchCV. Tests: fit/predict con etiquetas de texto;
predict_proba tiene 3 columnas en el orden de classes_; clone() conserva los parámetros; sample_weight llega
al fit. CUIDADO: el orden de classes_ es alfabético (Alta, Crítica, Normal), no (Normal, Alta, Crítica): el
runner y save_run deben mapear las probabilidades por NOMBRE de clase, no por posición. Dejalo escrito en la spec.
```
**Commits:** `test(XG-2): tests de etiquetas de texto, clone y sample_weight` → `feat(XG-2): wrapper de XGBClassifier con etiquetas de texto` → `docs(XG-2): orden de classes_ y mapeo de probabilidades`

### XG-3 · Baseline
**Depende de:** XG-2, MC-1, MC-2
```text
Tarea XG-3. Con build_preprocessor("base") y el split de la columna `split`, entrená XGBoost con parámetros por
defecto y sample_weight balanceado, predecí en test y calculá F1 macro, Recall de Crítica y matriz de
confusión con evaluate.py. Mostrame los números. Verificá que sample_weight realmente se usa (compará con y
sin él) y reportá la diferencia.
```
**Commits:** `test(XG-3): test de reproducibilidad` → `feat(XG-3): baseline de xgb con sample_weight`

### XG-4 · Búsqueda de hiperparámetros
**Depende de:** XG-3
```text
Tarea XG-4. RandomizedSearchCV (n_iter=30, random_state=semilla) sobre Pipeline(prep+clf), cv=get_cv(cfg),
scoring f1_macro, fit_params con clf__sample_weight, SOLO con train. Ojo: el sample_weight debe
recalcularse con las filas de cada fold, no con todo train (si no, se filtra información del fold de
validación); si el runner pasa el vector entero, comprobá cómo se alinea con los folds y documentá la
solución elegida (por ejemplo, calcularlo dentro de un paso del pipeline). Registrá mejores parámetros,
cv_best_score y tiempo; mirá la brecha entre CV y test.
```
**Commits:** `feat(XG-4): RandomizedSearchCV con CV temporal` → `test(XG-4): test de alineación de sample_weight por fold` → `docs(XG-4): resultados y decisión sobre sample_weight`

### XG-5 · Evaluación y ablación
**Depende de:** XG-4, MC-3
```text
Tarea XG-5. Evaluá el mejor XGBoost en test con evaluate.py y repetí con los 3 feature_sets (base,
con_participaciones, sin_potencia). Tabla comparativa y lectura honesta (hay 3 Alta en test).
```
**Commits:** `feat(XG-5): evaluación en test` → `feat(XG-5): ablación por feature set` → `docs(XG-5): tabla comparativa`

### XG-6 · Persistencia
**Depende de:** XG-5, MC-4, DB-2
```text
Tarea XG-6. Persistí con save_run (run_id único por feature set, ej. xgb_base_<timestamp>). Verificá con SQL: las
probabilidades están en las columnas correctas (prob_normal/alta/critica mapeadas por NOMBRE de clase: comprobá
que la suma por fila ≈ 1 y que la columna prob_critica es la más alta en los meses y_pred="Crítica"),
matriz de confusión parseable, mismos semilla y split que logreg y rf.
```
**Commits:** `feat(XG-6): persiste runs de xgb en Tablas 2 y 3` → `test(XG-6): verifica probabilidades por clase y JSON`

### XG-7 · Notebook e interpretación
**Depende de:** XG-6 · **Entregable:** `notebooks/04_xgb.ipynb` + sección en `docs/model_card.md`
```text
Tarea XG-7. Notebook que lee desde demanda.db: métricas, matriz de confusión, importancia por gain (y SHAP si hay
tiempo y la librería está en requirements), y análisis de errores (meses confundidos, deriva del pico
estacional). Limitaciones honestas.
```
**Commits:** `docs(XG-7): notebook de métricas e importancias` → `docs(XG-7): análisis de errores en model_card`

---

## CMP-3 · Gráficos de comparación
**Depende de:** CMP-2, VIZ-1 · **Rama:** `feat/CMP-3-plots-comparacion` · **Entregable:** funciones nuevas en `plots.py`
```text
Tarea CMP-3. Agregá a plots.py (funciones puras que reciben el DataFrame de compare_runs y/o las
matrices de confusión): plot_metricas_por_modelo (barras agrupadas de accuracy, precision, recall y F1 macro),
plot_matrices_confusion (una por modelo, lado a lado, misma escala), plot_f1_por_clase, plot_tiempos y
plot_ablacion (F1 macro por modelo × feature set). Incluí en cada gráfico el n_test y una nota "test = 62
meses; 3 Alta" cuando corresponda para no sobreinterpretar. Tests de humo con la fixture VIZ-2.
```
**Commits:** `test(CMP-3): tests de humo con la fixture` → `feat(CMP-3): métricas y matrices de confusión comparadas` → `feat(CMP-3): F1 por clase, tiempos y ablación`

## V-1 · Dashboard Streamlit
**Depende de:** CMP-3 · **Rama:** `feat/V-1-dashboard` · **Entregable:** `src/demanda/viz/app.py`
```text
Tarea V-1. Dashboard Streamlit que solo LEE db/demanda.db (con @st.cache_data). Barra lateral: modelo(s), feature
set, rango de fechas, clase. Pestañas: "Datos" (VIZ-1), "Modelos" (tabla de métricas y matriz de confusión por
run), "Comparación" (gráficos CMP-3), "Predicciones" (tabla filtrable y serie con aciertos/errores) y
"Calidad de datos" (etl_auditoria: archivo, SHA-256, filas, nulos por tramo, advertencias, umbrales de la
etiqueta). Si la BD no existe o no hay runs, mostrar un mensaje claro con el comando para generarlos, no un
traceback. Test de humo con streamlit.testing.v1.AppTest sobre la BD fixture.
```
**Aceptación:** `streamlit run src/demanda/viz/app.py` funciona con la BD real · mensajes claros sin datos · test de humo verde.

**Commits:** `test(V-1): test de humo del dashboard` → `feat(V-1): pestañas Datos y Modelos` → `feat(V-1): pestañas Comparación y Predicciones` → `feat(V-1): pestaña Calidad de datos desde etl_auditoria`

---

## Tareas conjuntas (las tres personas)

| ID | Tu parte |
|---|---|
| **T-01** | Redactar `specs/04-visualizacion.md` (qué muestra el dashboard) y presentar la estructura del repo |
| **CMP-1** | Aportar criterios de presentación de la comparación (qué se grafica y cómo se advierte la incertidumbre) |
| **CMP-5** | Decisión final del modelo |
| **F-2** | Revisar los PRs de B |
| **F-3 / F-4** | Sección "Infraestructura, visualización y XGBoost" del informe; ensayo de demo |

## Checklist final de C
- [ ] Clono el repo en una carpeta vacía, sigo el README y `python scripts/run_etl.py` + `streamlit run …` funcionan.
- [ ] CI verde y obligatoria en `main`; solo merge commits permitidos.
- [ ] 7 tareas XG cerradas con 3+ commits cada una.
- [ ] El dashboard no se rompe sin datos.
- [ ] Puedo explicar la atomicidad de la carga y por qué `classes_` está en orden alfabético.
