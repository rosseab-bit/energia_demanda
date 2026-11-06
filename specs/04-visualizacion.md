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

## 4. Gráficos (`src/demanda/viz/plots.py`)
Todas son **funciones puras**: reciben DataFrames ya leídos, devuelven una figura y no leen la base ni llaman a `plt.show()`. Así se pueden probar sin base de datos y reutilizar en el dashboard.

### 4.1 Gráficos de datos (VIZ-1)
Entrada: un DataFrame con las columnas de `datos_limpios` indicadas.

| Función | Columnas que necesita | Qué muestra |
|---|---|---|
| `plot_clases_por_split` | `etiqueta`, `split` | Cantidad de meses de cada clase en train y en test |
| `plot_demanda_vs_temperatura` | `temperatura_promedio`, `demanda_total`, `etiqueta` | Dispersión coloreada por clase |
| `plot_estacionalidad` | `mes`, `anio`, `demanda_total` | Perfil de demanda por mes, con la banda que cubre los años |
| `plot_serie_con_criticos` | `fecha`, `demanda_total`, `etiqueta`, `split` | Serie de demanda, meses Crítica marcados y línea de corte entre train y test |

### 4.2 Gráficos de comparación (CMP-3)
Entrada: el DataFrame que devuelve `compare_runs()` (CMP-2, de A) y, para las matrices, la columna `matriz_confusion` ya parseada. **El formato exacto se cierra en T-01** (ver §8).

| Función | Qué muestra |
|---|---|
| `plot_metricas_por_modelo` | Barras agrupadas de accuracy, precision, recall y F1 macro por modelo |
| `plot_matrices_confusion` | Una matriz por modelo, lado a lado y con la misma escala |
| `plot_f1_por_clase` | F1 de Normal, Alta y Crítica por modelo |
| `plot_tiempos` | Tiempo de entrenamiento por modelo |
| `plot_ablacion` | F1 macro por modelo y por feature set (`base`, `con_participaciones`, `sin_potencia`) |

## 5. Dashboard (`src/demanda/viz/app.py`)
Se inicia con `streamlit run src/demanda/viz/app.py`. Lee `db/demanda.db` y usa `@st.cache_data` para no releer en cada interacción.

### 5.1 Barra lateral (filtros)
| Filtro | Efecto |
|---|---|
| Modelo(s) | Qué corridas se muestran |
| Feature set | Filtra las corridas por conjunto de features (ver decisión abierta en §8) |
| Rango de fechas | Acota los gráficos de datos y la tabla de predicciones |
| Clase | Muestra solo los meses de esa clase real o predicha |

### 5.2 Pestañas
| Pestaña | Contenido | Gráficos / tablas |
|---|---|---|
| **Datos** | Exploración de la serie y de las clases | Los 4 gráficos de §4.1 |
| **Modelos** | Una corrida por vez: métricas, matriz de confusión, parámetros y features usadas | Tabla de `metricas_modelo`, matriz de confusión, datos de `config_modelo` |
| **Comparación** | Los modelos frente a frente | Los 5 gráficos de §4.2 y una tabla comparativa |
| **Predicciones** | Cada mes con su clase real, la predicha y las probabilidades | Tabla filtrable y serie con aciertos y errores |
| **Calidad de datos** | Qué cargó el ETL | Archivo, SHA-256, filas, nulos por tramo, advertencias y umbrales de la etiqueta (de `etl_auditoria`) |

## 6. Reglas transversales
| # | Regla |
|---|---|
| R1 | **Idioma:** títulos, ejes, leyendas y mensajes en español |
| R2 | **Accesibilidad:** las clases se distinguen por **color y por marcador o forma**, no solo por color |
| R3 | **Unidades:** mientras D7 no esté resuelta, los ejes de demanda y potencia dicen "PENDIENTE". No se inventan unidades |
| R4 | **Incertidumbre:** todo gráfico de comparación indica `n_test`. Si corresponde, agrega una nota de muestra chica, con el texto exacto acordado en CMP-1 (propuesta de la ficha: "test = 62 meses; 3 Alta", cifras a confirmar con el ETL real) |
| R5 | **Estados vacíos:** si la base no existe o no hay corridas, se muestra un mensaje claro con el comando para generarlas (`python scripts/run_etl.py` o `python -m demanda.models.train …`), nunca un traceback |
| R6 | **Solo lectura:** el dashboard no escribe en la base ni entrena modelos |
| R7 | **Sin cifras propias:** toda métrica mostrada sale de `metricas_modelo`. No se recalcula nada en la capa visual |
| R8 | **Mismo criterio de color:** cada clase tiene siempre el mismo color y marcador en todos los gráficos |

## 7. Criterios de aceptación
Los nombres de la columna "Verificación" son **propuestos**: los tests se escriben antes de implementar (SDD) y pueden cambiar de nombre.

| ID | Criterio | Verificación |
|---|---|---|
| VIZ-A1 | Cada función de §4.1 devuelve una figura y no lanza error con la fixture de 36 meses (VIZ-2) ni con la base real | `test_plots_datos_con_fixture`, `test_plots_datos_con_bd_real` |
| VIZ-A2 | Las funciones de `plots.py` no leen la base ni llaman a `plt.show()` | `test_plots_son_puras` |
| VIZ-A3 | Cada función de §4.2 devuelve una figura con la fixture (3 corridas: logreg, rf, xgb) | `test_plots_comparacion_con_fixture` |
| VIZ-A4 | Las clases se distinguen por color **y** marcador o forma (R2) | `test_clases_con_marcador_distinto` |
| VIZ-A5 | Los gráficos de comparación incluyen `n_test` (R4) | `test_comparacion_muestra_n_test` |
| VIZ-A6 | Sin base o sin corridas, el dashboard muestra un mensaje con el comando para generarlas y no lanza excepción (R5) | `test_app_sin_bd`, `test_app_sin_corridas` |
| VIZ-A7 | El dashboard recorre las 5 pestañas sin excepción sobre la fixture | `test_app_cinco_pestanas` (con `streamlit.testing.v1.AppTest`) |
| VIZ-A8 | Las probabilidades se leen por nombre de clase (`prob_normal`, `prob_alta`, `prob_critica`), no por posición | `test_probabilidades_por_nombre` |
| VIZ-A9 | La matriz de confusión se parsea desde el JSON en orden Normal / Alta / Crítica | `test_matriz_confusion_parseo` |
| VIZ-A10 | El dashboard no escribe en la base (conexión de solo lectura, R6) | `test_app_no_escribe_en_bd` |
| VIZ-A11 | Los ejes de demanda dicen "PENDIENTE" mientras D7 esté abierta (R3) | `test_unidades_pendientes` |

## 8. Decisiones abiertas (cerrar en T-01 con los 3)
| ID | Decisión | Con quién | Propuesta |
|---|---|---|---|
| V-D1 | **Formato de `compare_runs()`**: columnas exactas y si devuelve una fila por corrida | A (CMP-2) | Una fila por `run_id`, con las columnas de `metricas_modelo` más `features_usadas` |
| V-D2 | **Feature set de cada corrida**: `metricas_modelo` no lo guarda, solo `config_modelo.features_usadas` (lista JSON) | A (T-03, DB-2) | Agregar columna `feature_set` a `config_modelo` (cambio de contrato: PR previo a `specs/00-contratos.md`) |
| V-D3 | **Librería de gráficos**: matplotlib o plotly (ambas están en `requirements.txt`) | C | A definir. Streamlit soporta las dos |
| V-D4 | **Texto de la advertencia de incertidumbre** (R4) | A, B, C (CMP-1) | "test = N meses; k Alta", con cifras tomadas de la base y no escritas a mano |
| V-D5 | **Formato de `run_id`** visible en el dashboard | A (DB-2), B (MC-4) | `<modelo>_<feature_set>_<timestamp>`, como sugiere la ficha XG-6 |
| V-D6 | **Quién lee la base en el dashboard**: funciones de `repository.py` (A) o consultas propias de solo lectura en `viz/` | A, C | Funciones de lectura en `repository.py`, para tener una sola puerta de acceso a la base |
| V-D7 | **Unidades** (D7 de `PLAN_SDD.md`): GWh o MWh, y MW | A (T-02) | Mientras no se confirme, "PENDIENTE" (R3) |

## 9. Contrato con otros módulos
| Módulo | Quién | Qué espera la visualización | Qué ofrece la visualización |
|---|---|---|---|
| `repository.py` (`load_clean_data`, `compare_runs`) | A | DataFrames con las columnas de §3 y §4. **El formato de `compare_runs()` está sin cerrar (V-D1)** | — |
| `repository.save_run()` | A / modelos | Que guarde `prob_*` por nombre de clase y la matriz de confusión como JSON en orden Normal / Alta / Crítica | — |
| `tests/fixtures.py` (VIZ-2) | C | — | `make_fixture_db(path)`: base con las 3 tablas y datos ficticios (prefijo `fixture_`), para que A y C prueben sin esperar los modelos |
| `viz/plots.py` | C | — | Funciones puras de §4, reutilizables en notebooks (A, B, C) |
| `viz/app.py` | C | Una base creada por `run_etl.py` y por `train.py` | Dashboard de solo lectura |

Si hay que cambiar una columna de las tablas de §3, primero se hace el PR a `specs/00-contratos.md` y después se actualiza esta spec.
