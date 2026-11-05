# Clasificación de períodos de demanda eléctrica

Clasifica cada mes en **Normal / Alta / Crítica** según demanda total y sectorial, temperatura, potencia máxima y estacionalidad, comparando tres modelos de scikit-learn/XGBoost y guardando todo en SQLite.

| Modelo | Responsable | Búsqueda de hiperparámetros |
|---|---|---|
| Logistic Regression | A | `GridSearchCV` |
| Random Forest | B | `RandomizedSearchCV` |
| XGBoost | C | `RandomizedSearchCV` |

## Instalación
```bash
python -m venv .venv && source .venv/bin/activate     # Windows: .venv\Scripts\activate
pip install -r requirements.txt && pip install -e .
```

## Uso
> **Estado:** estos comandos se habilitan a medida que se mergean las tareas (el ETL con ETL-5, el runner de modelos con MC-4, el dashboard con V-1). Hoy funcionan `pip install -e .` y `load_config()`. El avance está en `docs/avance.md`.

```bash
python scripts/run_etl.py                       # CSV -> SQLite (db/demanda.db)
python -m demanda.models.train --model logreg --features base     # o rf / xgb
streamlit run src/demanda/viz/app.py            # dashboard
pytest && ruff check src tests                  # tests y lint
```

## Documentación
- `PLAN_SDD.md` — especificación, arquitectura y tareas
- `GUIA_EQUIPO.md` — cómo trabajamos (Git, agente de IA, ETL, coordinación)
- `TAREAS_A.md`, `TAREAS_B.md`, `TAREAS_C.md` — fichas por integrante con prompts
- `specs/` — especificaciones por funcionalidad · `docs/data_dictionary.md` — diccionario de datos

## Base de datos (SQLite)
`datos_limpios` (Tabla 1) · `predicciones` y `metricas_modelo` (Tabla 2) · `config_modelo` (Tabla 3) · extras: `demanda_distribuidora`, `etl_auditoria`. Esquema en `src/demanda/db/schema.sql`.
