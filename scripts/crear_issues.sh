#!/usr/bin/env bash
# Crea labels, milestones e issues del proyecto en GitHub con la CLI `gh` (v0.3 del plan).
# Requisitos: gh instalado y autenticado (gh auth login); ejecutar dentro del repo clonado.
#
# Uso:
#   export GH_USER_A="usuario-github-de-A" GH_USER_B="usuario-github-de-B" GH_USER_C="usuario-github-de-C"
#   bash scripts/crear_issues.sh
#
# Prueba sin tocar GitHub (valida el parseo y que cada dependencia exista):
#   DRY_RUN=1 bash scripts/crear_issues.sh
#
# Cada issue indica "Depende de" por ID. Al final, una segunda pasada reemplaza los IDs por #N reales.
# Correr UNA sola vez: ejecutarlo de nuevo duplica los issues.

set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
  GH_USER_A="${GH_USER_A:-usuario-A}"; GH_USER_B="${GH_USER_B:-usuario-B}"; GH_USER_C="${GH_USER_C:-usuario-C}"
  REPO="(dry-run)"
else
  : "${GH_USER_A:?Definir GH_USER_A}"; : "${GH_USER_B:?Definir GH_USER_B}"; : "${GH_USER_C:?Definir GH_USER_C}"
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
fi
echo "Repositorio: $REPO"

# ---------- Labels ----------
label() { [ "$DRY_RUN" = "1" ] || gh label create "$1" --color "$2" --description "$3" --force >/dev/null; }
label "persona-A" "1f77b4" "Responsable: A"
label "persona-B" "2ca02c" "Responsable: B"
label "persona-C" "ff7f0e" "Responsable: C"
label "equipo"    "7f7f7f" "Tarea conjunta (los 3)"
label "etl"       "d62728" "Proceso ETL"
label "base-compartida" "bcbd22" "Componentes comunes a los 3 modelos"
label "infra"     "8c8c8c" "Repositorio, CI, configuración"
label "viz"       "17becf" "Visualización y dashboard"
label "modelo-logreg" "9467bd" "Logistic Regression (A)"
label "modelo-rf"     "8c564b" "Random Forest (B)"
label "modelo-xgb"    "e377c2" "XGBoost (C)"
label "comparacion"   "2ca02c" "Comparación de métricas"

# ---------- Milestones ----------
ms() { [ "$DRY_RUN" = "1" ] || gh api "repos/$REPO/milestones" -f title="$1" -f description="$2" >/dev/null 2>&1 || true; }
ms "Fase 0 - Fundacion"       "Repo, specs, contratos, schema y configuración"
ms "Fase 1 - ETL y base"      "ETL, repository, preprocesador, split, evaluate, runner, CI, plots base"
ms "Fase 2 - Modelos"         "LR (A), RF (B), XGB (C) en paralelo"
ms "Fase 3 - Comparacion"     "Comparación de métricas y decisión del modelo"
ms "Fase 4 - Cierre"          "Dashboard, integración, informe y demo"

user_for() { case "$1" in A) echo "$GH_USER_A";; B) echo "$GH_USER_B";; C) echo "$GH_USER_C";; *) echo "";; esac; }
ficha_for() { case "$1" in A) echo "TAREAS_A.md";; B) echo "TAREAS_B.md";; C) echo "TAREAS_C.md";; *) echo "PLAN_SDD.md";; esac; }

# Formato: ID|Título|Responsables (A, B, C o combinación con +)|Milestone|Labels extra (coma, "-" si no hay)|Depende de|Entregable
TASKS=$(cat <<'EOF'
T-00|Repo y esqueleto: pyproject, config, CLAUDE.md, CODEOWNERS, plantilla de PR, proteccion de main|C|Fase 0 - Fundacion|infra|-|Repo clonable; pip install -e . funciona
T-01|Reunion de arranque: cerrar decisiones D1-D7 y aprobar specs 00-contratos y 01-datos|A+B+C|Fase 0 - Fundacion|equipo|T-00|Specs aprobadas por PR
T-02|Diccionario de datos y unidades|A|Fase 0 - Fundacion|etl|T-00|docs/data_dictionary.md
T-03|schema.sql (Tabla 1, 2, 3 y extras del ETL)|A|Fase 0 - Fundacion|etl|T-01|DDL idempotente + test
CMP-1|Spec de comparacion de modelos (criterios definidos antes de ver resultados)|A+B+C|Fase 0 - Fundacion|comparacion,equipo|T-01|specs/03-comparacion.md
ETL-1|ETL Extract: lectura del CSV, fechas, SHA-256|A|Fase 1 - ETL y base|etl|T-02|etl/extract.py + tests
ETL-2|ETL Validate: reglas de calidad (errores vs advertencias)|B|Fase 1 - ETL y base|etl|T-01|etl/validate.py + tests
ETL-3|ETL Transform: calendario, participaciones, etiqueta, split cronologico|A|Fase 1 - ETL y base|etl|T-01|etl/transform.py + tests (incl. sin fuga)
ETL-4|ETL Load: transaccion, idempotencia, rollback, auditoria|C|Fase 1 - ETL y base|etl|T-03|etl/load.py + tests
ETL-5|ETL Pipeline y CLI run_etl.py + test de integracion con el CSV real|C|Fase 1 - ETL y base|etl|ETL-1,ETL-2,ETL-3,ETL-4|demanda.db reproducible
ETL-6|EDA de decision: metodos de etiqueta (D1), fuga por sectores (D2), balance de clases|B|Fase 1 - ETL y base|etl|ETL-5|notebooks/01_eda.ipynb + recomendacion
DB-1|repository.load_clean_data()|A|Fase 1 - ETL y base|base-compartida|ETL-5|Funcion + tests
DB-2|repository.save_run() en Tablas 2 y 3 (transaccional)|A|Fase 1 - ETL y base|base-compartida|T-03|Funcion + tests + contrato
MC-1|build_preprocessor() desde feature_sets (test anti-fuga)|B|Fase 1 - ETL y base|base-compartida|T-01,ETL-5|models/preprocessing.py + tests
MC-2|splits.py: split por columna + TimeSeriesSplit + chequeo de clases por fold|B|Fase 1 - ETL y base|base-compartida|ETL-5|models/splits.py + tests
MC-3|evaluate.py: Accuracy, Precision, Recall, F1 y matriz de confusion|B|Fase 1 - ETL y base|base-compartida|T-01|models/evaluate.py + tests
MC-4|Runner train.py (--model, --features, autodescubrimiento)|B|Fase 1 - ETL y base|base-compartida|MC-1,MC-2,MC-3,DB-1,DB-2|python -m demanda.models.train
T-15|CI en GitHub Actions (ruff + pytest) como check obligatorio|C|Fase 1 - ETL y base|infra|T-00|.github/workflows/ci.yml
VIZ-1|plots.py base: clases, demanda vs temperatura, estacionalidad, serie con criticos|C|Fase 1 - ETL y base|viz|ETL-5|viz/plots.py + tests de humo
VIZ-2|BD fixture con datos ficticios (3 tablas) para tests y dashboard|C|Fase 1 - ETL y base|viz|T-03|tests/fixtures.py
EOF
)

# Tareas de modelo: mismas 7 por integrante.  args: prefijo, persona, label, nombre, busqueda
model_tasks() {
  local P="$1" PERSON="$2" LABEL="$3" NAME="$4" SEARCH="$5"
  cat <<EOF
${P}-1|[${NAME}] Spec del modelo: justificacion, espacio de busqueda, desbalance|${PERSON}|Fase 2 - Modelos|${LABEL}|T-01|specs/02-modelo-${NAME}.md
${P}-2|[${NAME}] Modulo del modelo (contrato NAME/SEARCH/get_estimator/get_param_grid) + test|${PERSON}|Fase 2 - Modelos|${LABEL}|${P}-1,T-03|models/${NAME}.py + tests
${P}-3|[${NAME}] Baseline sin tuning con el pipeline comun (set base)|${PERSON}|Fase 2 - Modelos|${LABEL}|${P}-2,MC-1,MC-2|Baseline reproducible
${P}-4|[${NAME}] Busqueda de hiperparametros (${SEARCH}) con CV temporal y scoring f1_macro|${PERSON}|Fase 2 - Modelos|${LABEL}|${P}-3|Mejores parametros y cv_best_score
${P}-5|[${NAME}] Evaluacion en test y ablacion de features (base, con_participaciones, sin_potencia)|${PERSON}|Fase 2 - Modelos|${LABEL}|${P}-4,MC-3|Metricas y matrices por set
${P}-6|[${NAME}] Persistencia en Tablas 2 y 3 con run_id propio|${PERSON}|Fase 2 - Modelos|${LABEL}|${P}-5,MC-4,DB-2|Filas en demanda.db
${P}-7|[${NAME}] Notebook e informe del modelo: interpretacion y analisis de errores|${PERSON}|Fase 2 - Modelos|${LABEL}|${P}-6|notebook + seccion en docs/model_card.md
EOF
}

TASKS+=$'\n'"$(model_tasks LR A modelo-logreg logreg GridSearchCV)"
TASKS+=$'\n'"$(model_tasks RF B modelo-rf rf RandomizedSearchCV)"
TASKS+=$'\n'"$(model_tasks XG C modelo-xgb xgb RandomizedSearchCV)"

TASKS+=$'\n'"$(cat <<'EOF'
CMP-2|compare_runs(): consulta consolidada de los 3 run_id (mismo split y semilla)|A|Fase 3 - Comparacion|comparacion|LR-6,RF-6,XG-6,CMP-1|repository.compare_runs() + tests
CMP-3|Graficos de comparacion: metricas, matrices lado a lado, F1 por clase, tiempos, ablacion|C|Fase 3 - Comparacion|comparacion,viz|CMP-2,VIZ-1|viz/plots.py ampliado
CMP-4|Analisis comparativo: ganador, incertidumbre, deriva estacional|B|Fase 3 - Comparacion|comparacion|CMP-3|notebooks/05_comparacion.ipynb
CMP-5|Decision del modelo final segun el criterio de CMP-1|A+B+C|Fase 3 - Comparacion|comparacion,equipo|CMP-4|Seccion en docs/model_card.md
V-1|Dashboard Streamlit: modelos, comparacion, predicciones y calidad de datos|C|Fase 4 - Cierre|viz|CMP-3|viz/app.py sobre demanda.db
F-1|run_all.py + test de integracion (ETL -> 3 modelos -> BD)|B|Fase 4 - Cierre|base-compartida|CMP-2|Un comando de punta a punta
F-2|Revision cruzada final de codigo y specs (A->B, B->C, C->A)|A+B+C|Fase 4 - Cierre|equipo|V-1,F-1|PRs de revision cerrados
F-3|Informe final y README (una seccion por integrante)|A+B+C|Fase 4 - Cierre|equipo|CMP-5,V-1|docs/informe_final.md
F-4|Ensayo de demo desde cero|A+B+C|Fase 4 - Cierre|equipo|F-3|Demo reproducible
EOF
)"

# ---------- Primera pasada: crear issues ----------
declare -A NUM
COUNTER=0
while IFS='|' read -r ID TITLE WHO MS LABELS DEPS DELIV; do
  [ -z "$ID" ] && continue
  LBL=""; ASSIGNEES=()
  IFS='+' read -ra PEOPLE <<< "$WHO"
  for p in "${PEOPLE[@]}"; do
    LBL+="persona-$p,"
    ASSIGNEES+=(--assignee "$(user_for "$p")")
  done
  [ "$LABELS" != "-" ] && LBL+="$LABELS,"
  LBL="${LBL%,}"
  FICHA="$(ficha_for "${PEOPLE[0]}")"; [ "${#PEOPLE[@]}" -gt 1 ] && FICHA="PLAN_SDD.md y las fichas TAREAS_A/B/C.md"
  BODY="**ID:** $ID
**Responsable(s):** $WHO
**Depende de:** $DEPS
**Entregable:** $DELIV

**Ficha con el prompt para el agente de IA:** \`$FICHA\` (buscá \`$ID\`)

### Definición de hecho
- [ ] Spec/criterio escrito antes de implementar
- [ ] Mínimo 3 commits propios (Conventional Commits con \`($ID)\`)
- [ ] Tests y linter pasan en local y en CI
- [ ] El autor puede explicar el código (aunque lo haya generado el agente)
- [ ] Documentación actualizada
- [ ] PR aprobado por otro integrante (\`Closes #N\`)
- [ ] Merge sin squash

Rama sugerida: \`feat/$ID-<descripcion-corta>\`"
  if [ "$DRY_RUN" = "1" ]; then
    COUNTER=$((COUNTER+1)); NUM[$ID]="$COUNTER"
    echo "[dry-run] #$COUNTER $ID ($WHO) labels=[$LBL] milestone=[$MS]"
  else
    URL=$(gh issue create --title "[$ID] $TITLE" --body "$BODY" --label "$LBL" --milestone "$MS" "${ASSIGNEES[@]}")
    NUM[$ID]="${URL##*/}"
    echo "$ID -> #${NUM[$ID]}"
  fi
done <<< "$TASKS"

# ---------- Segunda pasada: reemplazar IDs de dependencias por #N ----------
# Con `set -u`, una dependencia que no exista como tarea aborta el script (sirve de validación).
while IFS='|' read -r ID TITLE WHO MS LABELS DEPS DELIV; do
  [ -z "$ID" ] && continue
  [ "$DEPS" = "-" ] && continue
  REFS=""
  IFS=',' read -ra DL <<< "$DEPS"
  for d in "${DL[@]}"; do REFS+="#${NUM[$d]} ($d), "; done
  REFS="${REFS%, }"
  if [ "$DRY_RUN" = "1" ]; then
    echo "[dry-run] $ID depende de: $REFS"
  else
    CURRENT=$(gh issue view "${NUM[$ID]}" --json body -q .body)
    NEW="${CURRENT//\*\*Depende de:\*\* $DEPS/**Depende de:** $REFS}"
    gh issue edit "${NUM[$ID]}" --body "$NEW" >/dev/null
  fi
done <<< "$TASKS"

echo "Listo: ${#NUM[@]} issues."
