# Spec 02 — Modelo XGBoost (integrante C)

Estado: **borrador v0.1** (tarea XG-1). Cualquier cambio se hace primero acá. Cubre las tareas XG-1 a XG-7.

## 1. Objetivo y justificación
Clasificar cada mes en `Normal` / `Alta` / `Crítica` con **XGBoost**, usando el mismo preprocesador, split, validación cruzada y `evaluate.py` que los otros dos modelos (Logistic Regression de A y Random Forest de B). El objetivo es la **comparación justa** entre los tres, no maximizar un solo modelo.

**Por qué XGBoost:**
- Es un método de *boosting*: construye árboles en secuencia, cada uno corrige los errores del anterior. Eso le permite captar **relaciones no lineales** e **interacciones** (por ejemplo, temperatura alta y mes de verano) que una regresión logística no ve sin ingeniería de features.
- Frente a Random Forest (que promedia árboles independientes), el boosting suele ajustar mejor, a costa de más hiperparámetros y más riesgo de sobreajuste con pocos datos.
- Aporta una tercera familia de modelos a la comparación: lineal (A), *bagging* (B) y *boosting* (C).

**Contexto de datos** (de `PLAN_SDD.md §1.3` y `GUIA_EQUIPO.md §6`; las cifras se confirman con el ETL real en ETL-5): 308 meses, de los cuales 246 son de entrenamiento y 62 de test. En train hay 184 Normal, 37 Alta y 25 Crítica. En test hay pocas Alta (3), así que las métricas de esa clase serán inestables.

## 2. Dos puntos delicados

### 2.1 Etiquetas: XGBoost necesita clases enteras
XGBoost solo acepta clases numéricas (0, 1, 2), pero todo el sistema trabaja con los textos `Normal`, `Alta` y `Crítica` (tabla 1, `evaluate.py`, `save_run`, dashboard).

**Decisión:** el módulo `xgb.py` codifica y decodifica **internamente**. Devuelve un estimador compatible con scikit-learn que:
- acepta etiquetas de texto en `fit`;
- las convierte a enteros con un `LabelEncoder`;
- decodifica en `predict`, de modo que el resto del sistema siempre ve los textos;
- expone `classes_` con los strings.

Ningún otro módulo (runner, `evaluate.py`, `save_run`) sabe que XGBoost usa enteros por dentro.

**Consecuencia sobre el orden de clases:** `classes_` queda en orden **alfabético** (`Alta`, `Crítica`, `Normal`), igual que en los otros modelos, no en el orden `Normal`, `Alta`, `Crítica`. Las probabilidades de `predict_proba` se mapean a `prob_normal`, `prob_alta` y `prob_critica` **por nombre de clase, nunca por posición** (`specs/00-contratos.md §6.2`).

### 2.2 Desbalance de clases: no existe `class_weight` en multiclase
Logistic Regression y Random Forest resuelven el desbalance con `class_weight='balanced'`. En XGBoost multiclase esa opción no existe.

**Decisión:** se usa `sample_weight`, calculado con `compute_sample_weight("balanced", y_train)` de scikit-learn y pasado al `fit`. Cada fila pesa más cuanto más rara es su clase.

**Riesgo (de la ficha XG-4):** dentro de la validación cruzada, los pesos deben calcularse con las filas de **cada fold**. Si se calculan una sola vez con todo `train`, la información del fold de validación se filtra al peso. Cómo se resuelve se decide en XG-4 y se documenta ahí; el contrato con el runner está en §5.

## 3. Búsqueda de hiperparámetros
`RandomizedSearchCV` con `n_iter = 30`, `random_state` = la semilla de `config.yaml`, `scoring = f1_macro` y la validación cruzada temporal común (`TimeSeriesSplit`, ver `specs/00-contratos.md §4`). Todo sobre **train**; test no participa.

### 3.1 Espacio de búsqueda
Las claves llevan el prefijo `clf__` porque el modelo va dentro de un `Pipeline` (contrato de modelos).

| Hiperparámetro | Valores | Para qué sirve |
|---|---|---|
| `n_estimators` | 100, 200, 400 | Cantidad de árboles |
| `max_depth` | 3, 5, 7 | Profundidad máxima de cada árbol |
| `learning_rate` | 0.03, 0.1, 0.3 | Cuánto aporta cada árbol nuevo |
| `subsample` | 0.7, 0.9, 1.0 | Fracción de filas que ve cada árbol |
| `colsample_bytree` | 0.7, 0.9, 1.0 | Fracción de columnas que ve cada árbol |
| `reg_lambda` | 1, 5, 10 | Regularización L2 sobre los pesos de las hojas |

### 3.2 Por qué este espacio, con 246 filas de train
- **Cuántas combinaciones hay:** 3 valores en cada uno de 6 hiperparámetros dan 3⁶ = **729** combinaciones. Con 5 folds serían más de 3.600 entrenamientos. Una búsqueda aleatoria de 30 iteraciones (30 × 5 = 150 entrenamientos) cubre cerca del 4 % del espacio y es rápida con tan pocos datos. No garantiza encontrar la mejor combinación.
- **Árboles poco profundos** (3 a 7): con 246 filas, árboles profundos memorizan el entrenamiento. Se limita la profundidad para reducir el sobreajuste.
- **`learning_rate` y `n_estimators` van juntos:** una tasa baja necesita más árboles. Por eso se exploran ambos.
- **`subsample` y `colsample_bytree` menores que 1** y **`reg_lambda` alto** agregan regularización, útil cuando hay pocos datos.
- **Folds muy chicos al principio:** con 246 filas y 5 divisiones, el primer fold entrena con unas 41 filas, y puede no tener ninguna `Crítica` (los picos eran chicos en 2001-2005). Esto se mide con `check_cv_class_presence` (MC-2) y obliga a leer `cv_best_score` con cautela.
- **Diferencias pequeñas son ruido:** con 3 meses `Alta` en test y folds tan chicos, dos configuraciones con F1 macro parecido no se pueden distinguir. No se debe concluir que una es mejor por una diferencia chica.

## 4. Criterios de aceptación de XG-2 a XG-7
Los nombres de la columna "Verificación" son **propuestos**: los tests se escriben antes de implementar (SDD).

| Tarea | Criterio | Verificación |
|---|---|---|
| **XG-2** Módulo `xgb.py` | Expone `NAME = "xgb"`, `SEARCH = "random"`, `NEEDS_SAMPLE_WEIGHT = True`, `get_estimator`, `get_param_grid` (claves `clf__`) y `get_n_iter() = 30` | `test_contrato_xgb` |
| XG-2 | El estimador acepta y devuelve etiquetas de texto | `test_fit_predict_con_etiquetas_de_texto` |
| XG-2 | `predict_proba` tiene 3 columnas en el orden de `classes_` | `test_predict_proba_orden_de_classes` |
| XG-2 | Funciona con `sklearn.base.clone`, dentro de `Pipeline` y de `RandomizedSearchCV` | `test_clone_conserva_parametros`, `test_dentro_de_pipeline` |
| XG-2 | `sample_weight` llega al `fit` | `test_sample_weight_llega_al_fit` |
| **XG-3** Baseline | Entrena con parámetros por defecto, set `base`, split de la columna `split`, y devuelve F1 macro, Recall de `Crítica` y matriz de confusión con `evaluate.py` | `test_baseline_reproducible` (misma semilla, mismo resultado) |
| XG-3 | Compara con y sin `sample_weight` y reporta la diferencia con números | Salida del comando, registrada en el PR |
| **XG-4** Búsqueda | `RandomizedSearchCV(n_iter=30)` con la CV temporal común y `f1_macro`, solo con train | `test_busqueda_solo_con_train` |
| XG-4 | El `sample_weight` se calcula con las filas de cada fold, no con todo train | `test_sample_weight_alineado_por_fold` |
| XG-4 | Registra mejores parámetros, `cv_best_score` y tiempo; informa la brecha entre CV y test | Resultados documentados en el PR |
| **XG-5** Evaluación | Evalúa el mejor modelo en test con `evaluate.py`, para los 3 sets (`base`, `con_participaciones`, `sin_potencia`) | Tabla comparativa |
| XG-5 | La lectura menciona las limitaciones (pocas `Alta` en test) | Revisión en el PR |
| **XG-6** Persistencia | `save_run` guarda un `run_id` por feature set con formato `xgb_<feature_set>_<timestamp>` | `test_save_run_xgb` |
| XG-6 | Con SQL: `prob_*` están mapeadas por nombre de clase, suman ≈ 1 por fila, y `prob_critica` es la más alta cuando `y_pred = Crítica` | `test_probabilidades_por_clase` |
| XG-6 | La matriz de confusión es JSON parseable; semilla y split iguales a los de LR y RF | `test_matriz_json`, `test_misma_semilla_y_split` |
| **XG-7** Notebook | `notebooks/04_xgb.ipynb` lee solo `demanda.db`; muestra métricas, matriz, importancia por *gain* y análisis de errores (deriva del pico estacional) | Notebook ejecutable de punta a punta |
| XG-7 | Sección en `docs/model_card.md` con limitaciones honestas | Revisión en el PR |

**Sobre SHAP:** la ficha lo deja como opcional. La librería `shap` **no está** en `requirements.txt`, así que solo se incluye si el equipo la agrega antes.

## 5. Contrato con el runner: `sample_weight` (pendiente de confirmación de B)
Hoy el contrato (`specs/00-contratos.md §8.1`) dice: el módulo declara `NEEDS_SAMPLE_WEIGHT = True`, y el runner (MC-4, de **B**) calcula `compute_sample_weight("balanced", y_train)` y lo pasa como `fit_params={"clf__sample_weight": ...}`.

### 5.1 Qué se comprobó
Con scikit-learn 1.9.1 (versión instalada al redactar esta spec) se probó con un estimador de prueba: si el runner pasa el vector de pesos **completo**, `cross_val_score` lo **recorta por fold**, y cada `fit` recibe tantas filas de pesos como filas de datos. O sea, **la alineación fila a fila funciona**. Esto se vuelve a verificar con un test en XG-4 y con la versión que fije el equipo.

### 5.2 Cuál es el riesgo real
El problema no es la alineación, sino **cómo se calcularon los valores**. Un peso "balanceado" depende de cuántas filas tiene cada clase. Si se calcula con todo `train` y después se recorta, el peso de cada fila refleja también las frecuencias de las filas de validación de ese fold. Es una fuga leve, pero es una fuga, y la regla 6 de `CLAUDE.md` pide evitarla.

### 5.3 Dos formas de resolverlo
| Opción | Cómo funciona | A favor | En contra |
|---|---|---|---|
| **1. El runner pasa el vector completo** (contrato actual) | Calcula los pesos una vez con todo `train` | Ya está escrito en el contrato; el runner decide | Fuga leve descrita en §5.2 |
| **2. El propio estimador calcula los pesos en su `fit`** | El wrapper de XGBoost (XG-2) llama a `compute_sample_weight("balanced", y)` con las filas que recibe en cada `fit` | Sin fuga: en cada fold usa solo sus filas de entrenamiento. El runner no necesita saber nada de pesos | El comportamiento queda dentro del módulo de C, y el runner no lo ve |

**Propuesta de C:** la opción 2. Evita la fuga y simplifica el runner. Con esa opción `NEEDS_SAMPLE_WEIGHT` ya no hace falta (el runner no tiene nada que pasar), y habría que quitarlo de `00-contratos.md §8.1` con un PR previo.

### 5.4 Preguntas para B
1. ¿Prefiere la opción 1 o la 2? La decisión afecta al runner (MC-4), que es de B.
2. Si queda la opción 1: ¿el runner trata la ausencia del atributo como `False`? (`00-contratos.md §8.1` lo supone, pero B no lo confirmó.)
3. Si queda la opción 2: ¿está de acuerdo con quitar `NEEDS_SAMPLE_WEIGHT` del contrato?

Mientras no haya respuesta, **XG-2 y XG-3 se pueden hacer con cualquiera de las dos**: el wrapper expone un `fit` que acepta `sample_weight` opcional. La decisión se necesita antes de XG-4.
