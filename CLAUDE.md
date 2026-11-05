# Contexto del proyecto para el agente de IA

Proyecto académico en equipo (3 personas, GitHub, metodología SDD). Objetivo: clasificar meses de **demanda eléctrica** en `Normal` / `Alta` / `Crítica` con scikit-learn, guardar todo en **SQLite** y mostrarlo en un dashboard. Lee `PLAN_SDD.md` (plan y tareas), `GUIA_EQUIPO.md` (flujo de trabajo) y `specs/` antes de escribir código.

## Reglas que SIEMPRE se cumplen
1. **SDD:** primero la spec/criterio de aceptación (`specs/…`), después el test, después la implementación.
2. **Una tarea = una rama = un PR.** Rama `feat/<ID>-<slug>`. Nunca trabajar sobre `main`.
3. **Commits chicos (mínimo 3 por tarea)**, formato `tipo(ID): descripción en imperativo` (tipos: feat, fix, test, docs, refactor, data, chore). Un cambio lógico por commit. El humano revisa el diff y hace el commit con su propio usuario de Git.
4. **Tocar solo los archivos de tu tarea.** Los archivos de otros integrantes (ver `CODEOWNERS`) no se modifican sin avisar. Si hay que cambiar un contrato, es un PR a `specs/00-contratos.md`.
5. **Sin hardcodear:** semilla, umbrales, rutas, columnas y conjuntos de features salen de `config/config.yaml`.
6. **Sin fuga de datos (leakage):** `demanda_total`, `demanda_ratio_tendencia`, `etiqueta`, `split` y `fecha` nunca son features. Los umbrales de la etiqueta se calculan solo con `train`. Los sectores en valores absolutos suman exactamente `demanda_total`: usar participaciones o excluirlos.
7. **Split cronológico**, nunca aleatorio. CV con `TimeSeriesSplit`. Misma semilla, mismo split y mismo `evaluate.py` para los 3 modelos.
8. Los tests usan `unittest` o `pytest` y deben pasar (`pytest`) y el linter también (`ruff check src tests`).
9. No inventar columnas, resultados ni métricas: si algo no está en los datos o en la spec, preguntar.
10. No subir `db/*.db`, credenciales ni datos que no estén en `data/raw/`.

## Datos (resumen verificado)
Serie mensual 2001-01 → 2026-08 (308 filas, sin huecos). Sectores solo desde 2005-01. Distribuidoras (23) solo 2014-01 → 2026-06 y cubren ~71 % del total. `potencia_maxima` correlaciona 0,96 con `demanda_total`. La demanda crece con el tiempo (por eso la etiqueta por defecto es `relativo_tendencia`). Detalle: `docs/data_dictionary.md`.

## Comandos
```bash
pip install -r requirements.txt && pip install -e .
python scripts/run_etl.py             # CSV -> SQLite (db/demanda.db)
pytest                                # tests
ruff check src tests                  # lint
python -m demanda.models.train --model logreg|rf|xgb --features base
streamlit run src/demanda/viz/app.py
```

## Contrato de modelos (src/demanda/models/<modelo>.py)
`NAME`, `SEARCH` ("grid"|"random"), `get_estimator(random_state)`, `get_param_grid()` (claves `clf__*`), `get_n_iter()`.

## Cómo trabajar con el humano
Explicá brevemente qué vas a hacer, hacelo en pasos pequeños, y al terminar cada paso proponé el mensaje de commit. El humano debe poder explicar cada línea del código que entrega: preferí código simple y comentado antes que ingenioso.
