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
