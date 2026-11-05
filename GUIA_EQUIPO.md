# Guía de trabajo del equipo (v0.2)

Complementa a `PLAN_SDD.md` (qué hacemos y cuándo) y a `TAREAS_A.md`, `TAREAS_B.md`, `TAREAS_C.md` (fichas con prompts para el agente de IA). Esta guía explica **cómo** trabajamos: configuración, primer día, ciclo por tarea, uso del agente de IA, ETL, coordinación y problemas frecuentes.

**Qué cambió en v0.2:** se agrega el ETL (§6), el trabajo con agente de IA (§4), un primer día ordenado (§2) y las fichas por integrante.

---

## 1. Preparación (una vez, cada integrante)

### 1.1 Git con identidad propia
Los commits tienen que quedar a nombre de cada uno: es el registro de avances.
```bash
git config --global user.name  "Nombre Apellido"
git config --global user.email "el-mismo-mail-de-tu-cuenta-de-GitHub@ejemplo.com"
git config --global pull.rebase false
git config --list | grep user          # verificar
```
Si el mail no coincide con el de GitHub, los commits no se asocian a tu perfil.

### 1.2 Clonar y preparar el entorno
```bash
git clone https://github.com/<organizacion>/proyecto-demanda.git
cd proyecto-demanda
python -m venv .venv
source .venv/bin/activate              # Windows: .venv\Scripts\activate
pip install -r requirements.txt
pip install -e .
pytest                                  # debe pasar antes de tocar nada
```

### 1.3 Agente de IA
Cada integrante usa su propio agente (Claude Code u otro) **abierto en la raíz del repositorio**, para que lea `CLAUDE.md` automáticamente. Verificá con "¿qué reglas del proyecto conocés?": debe mencionar SDD, ramas por tarea, commits chicos y no-fuga de datos.

### 1.4 GitHub CLI (solo quien cree los issues)
```bash
gh auth login
```

---

## 2. Primer día: orden de arranque

| Orden | Quién | Acción |
|---|---|---|
| 1 | **C** | **T-00:** arma el repo, sube el commit inicial, protege `main`, invita a A y B (ver `TAREAS_C.md`) |
| 2 | A y B | Clonan, instalan el entorno (§1.2) y confirman que `pytest` y `load_config()` funcionan |
| 3 | **C** | Crea los issues: `export GH_USER_A=… GH_USER_B=… GH_USER_C=…` y `bash scripts/crear_issues.sh` |
| 4 | **C** | **T-15:** CI, y la marca como check obligatorio |
| 5 | A+B+C | **Reunión de arranque (60 min)** — agenda abajo |
| 6 | A, B, C | Empiezan en paralelo: A → T-02/ETL-1; B → ETL-2/MC-3; C → XG-1/ETL-4 |

**Para no esperar nada:** como el ETL de referencia ya corre sobre el CSV real, cualquiera puede generar su propio `db/demanda.db` local (el archivo no se sube a git) mientras ETL-5 no esté mergeado. Se hace una sola vez desde el zip: `python scripts/run_etl.py`.

### Agenda de la reunión de arranque (T-01)
1. Confirmar roles y revisores cruzados (A→B→C→A).
2. **Cerrar las decisiones D1–D7** de `PLAN_SDD.md §1.4` mirando los hallazgos de `docs/data_dictionary.md` (sectores que suman el total, potencia 0,96 de correlación, tendencia, 62 meses de test con 3 Alta).
3. Aprobar contratos de `specs/00-contratos.md`: `evaluate`, `save_run`, `feature_sets`, `NEEDS_SAMPLE_WEIGHT`, mapeo de probabilidades por nombre de clase.
4. Repasar el ciclo por tarea (§3) con un ejemplo en vivo.
5. Acordar canal de comunicación, horario de la sincronía semanal y si se deja el trailer `Co-Authored-By` que algunos agentes agregan en los commits (recomendado: sí, por transparencia).

---

## 3. Ciclo por tarea (se repite siempre)

Cada tarea sigue los mismos pasos. Ejemplo con `ETL-1` (Integrante A).

### Arranque de tarea
```bash
git checkout main && git pull origin main
git checkout -b feat/ETL-1-extract          # <tipo>/<ID>-<slug>
# abrir el agente en la raíz del repo
```
1. Abrí el issue en GitHub. Revisá **"Depende de"**: todo debe estar **mergeado en `main`**. Si no, trabajá contra el contrato o pasá a otra tarea sin bloqueo.
2. Mové el issue a *En progreso*.

### Pasos
| # | Paso | Qué hacer |
|---|---|---|
| 1 | **Spec** | Dejá por escrito el criterio de aceptación en el `.md` correspondiente (`specs/…`). **Commit `docs`** |
| 2 | **Test** | Escribí el test que falla. **Commit `test`** |
| 3 | **Implementación** | Código mínimo para que pase. **Commit `feat`** |
| 4 | **Verificación** | `pytest` y `ruff check src tests` en verde |
| 5 | **Documentación** | Docstrings y actualización de docs. **Commit `docs`** |
| 6 | **PR** | `git push -u origin <rama>`, abrir PR con `Closes #N`, pedir revisión al que corresponde |
| 7 | **Revisión** | El revisor comenta; el autor corrige con **commits nuevos** (no reescribir historial publicado) |
| 8 | **Merge** | Con aprobación y CI verde: **"Create a merge commit"** (nunca *squash*). Borrar rama, `git pull`, marcar `docs/avance.md` |

### Convención de commits
```
<tipo>(<ID>): <qué cambió, en imperativo y en una línea>
```
| Tipo | Uso |
|---|---|
| `feat` | Funcionalidad nueva |
| `fix` | Corrección de un error |
| `test` | Tests |
| `docs` | Documentación, specs, notebooks explicativos |
| `refactor` | Reorganización sin cambiar comportamiento |
| `data` | Cambios en datos, esquema o configuración de datos |
| `chore` | Dependencias, CI, mantenimiento |

Buenos: `feat(ETL-3): implementa etiqueta con umbrales de train`, `fix(MC-1): excluye demanda_total de las features`.
Malos: `cambios`, `listo`, `arreglos varios`. **Mínimo 3 commits por tarea.**

### Mantener la rama al día
```bash
git checkout main && git pull origin main
git checkout feat/ETL-1-extract && git merge main
```
Resolvé conflictos (§9), corré `pytest` y hacé push.

---

## 4. Trabajar con el agente de IA

El agente acelera, pero **el proyecto es tuyo**: tenés que poder explicar cada línea que entregás.

### 4.1 Prompt de arranque (pegalo al comenzar una tarea, antes del prompt de la ficha)
```text
Voy a trabajar la tarea <ID> (<título>) en la rama <rama>, según PLAN_SDD.md y mi ficha en TAREAS_<A|B|C>.md.
Leé CLAUDE.md, PLAN_SDD.md, specs/ y docs/data_dictionary.md. Trabajá en este orden: spec, test, implementación,
docs. Tocá solo los archivos de esta tarea. Hacé pasos chicos y al terminar cada uno proponeme el mensaje de
commit (formato tipo(ID): descripción) sin hacer el commit vos. Si algo no está en los datos o en la spec,
preguntame en lugar de inventarlo.
```
Después pegás el **prompt de la ficha** de la tarea.

### 4.2 Qué hacer vos en cada paso
- **Leer el diff completo** antes de cada commit (`git diff`). Si no entendés una línea, pedile al agente que la explique o la simplifique.
- **Correr los tests vos**, no confiar en "los tests pasan" del agente.
- **Verificar que los tests prueban algo:** que fallen antes de implementar, y que fallen si rompés la regla a propósito.
- **Verificar los números:** cualquier cifra de un informe o notebook debe salir de un comando que viste correr.
- **Commits chicos y tuyos:** usá tu identidad de Git; el agente propone el mensaje, vos hacés el commit.

### 4.3 Señales de alarma (frenar y corregir)
| Señal | Qué hacer |
|---|---|
| El agente toca archivos fuera de tu tarea | Revertir (`git checkout -- <archivo>`) y recordarle `CLAUDE.md` regla 4 |
| Aparece `test_df`/`X_test` antes del `.fit` o dentro de la CV | **Fuga de datos**: corregir antes de seguir |
| Una feature es `demanda_total`, `demanda_ratio_tendencia`, `etiqueta`, `split` o los sectores en valores absolutos | Fuga: usar un `feature_set` de `config.yaml` |
| Valores hardcodeados (semilla, umbrales, rutas) | Moverlos a `config/config.yaml` |
| Mensajes tipo "mejoré la precisión" sin números | Pedir el comando y la salida |
| Código "ingenioso" que no podés explicar | Pedir la versión más simple |
| Resultados que parecen demasiado buenos | Sospechar fuga (con potencia y sectores es esperable un rendimiento alto: revisar la ablación) |

### 4.4 Buenos hábitos de prompts
- Un prompt = un objetivo verificable. Mejor "implementá X con estos tests" que "armá todo el módulo".
- Dar el contexto exacto: archivos, nombres de columnas y criterios de aceptación (están en las fichas).
- Pedir que explique las decisiones y los riesgos antes de codear en tareas con decisiones de diseño.
- Cuando algo falla, pegar el error completo y el comando que lo produjo.

---

## 5. Reglas de convivencia en el repositorio

1. **Nadie pushea directo a `main`.** Todo entra por PR.
2. **Un PR = una tarea.** PR chicos (menos de ~400 líneas) se revisan mejor.
3. **No modificar archivos de otro integrante** sin avisar: cada modelo y cada etapa del ETL tiene dueño (`CODEOWNERS`).
4. **Si necesitás cambiar un contrato** (columnas de Tabla 1, claves de `save_run`/`evaluate`, interfaz de modelo): primero PR a `specs/00-contratos.md`, aprobado por los 3, y recién después el código.
5. **No subir** `db/*.db`, `.venv`, credenciales ni datos fuera de `data/raw/` (todo en `.gitignore`).
6. **Misma semilla, mismo split, mismo preprocesador y mismo `evaluate`** para los 3 modelos: salen de `config.yaml` y de los módulos comunes de B.
7. **Reproducibilidad:** cualquiera regenera la BD y los resultados con `scripts/run_all.py`.
8. **Revisar PRs ajenos dentro de las 24 h**: es parte del trabajo.

### Checklist del revisor (copiar en cada review)
- [ ] El PR cierra el issue correcto y cumple su entregable.
- [ ] Hay 3+ commits con mensajes claros y el ID de tarea.
- [ ] Hay tests significativos (probé romper la regla y falla) y pasan en CI.
- [ ] **Sin fuga de datos:** test no participa de ningún `fit`, ni de la CV, ni del cálculo de umbrales.
- [ ] Ninguna feature prohibida; los sectores no entran en valores absolutos.
- [ ] Respeta los contratos (columnas, claves, firmas).
- [ ] Sin valores hardcodeados.
- [ ] Documentación y docstrings actualizados.
- [ ] El autor puede explicar el código (preguntale una cosa al azar).

---

## 6. ETL: cómo se ejecuta y cómo se re-ejecuta

```bash
python scripts/run_etl.py            # CSV -> SQLite (conserva resultados de modelos)
python scripts/run_etl.py --reset    # BORRA TODAS las tablas, incluidos los resultados de modelos
```

| Situación | Qué hacer |
|---|---|
| Primera vez / BD nueva | `python scripts/run_etl.py` |
| Cambió el CSV | Re-ejecutar el ETL y **re-entrenar los 3 modelos** (las etiquetas pueden cambiar) |
| Cambió el método de etiqueta o los percentiles (D1) | `--reset`, ETL, y re-entrenar. Los resultados anteriores ya no son comparables |
| El ETL falla con "DATOS INVÁLIDOS" | No se escribió nada. Leer el mensaje: indica qué regla de `validate.py` falló |
| Quiero ver qué se cargó | `SELECT * FROM etl_auditoria` (archivo, SHA-256, filas, nulos, umbrales, advertencias) |

Reglas del ETL (detalle en `specs/01-datos.md`): los nulos de sectores y distribuidoras **no se imputan** (no existe el dato); los umbrales de la etiqueta salen **solo del período train**; la carga es atómica e idempotente.

**Estado verificado del ETL de referencia sobre el CSV real:** 308 filas en `datos_limpios`, 3.450 en `demanda_distribuidora`, 25 tests OK. Con el método por defecto: train 184 Normal / 37 Alta / 25 Crítica; test 42 Normal / 3 Alta / 17 Crítica (la amplitud del pico estacional crece con los años).

---

## 7. Cómo se conectan los trabajos (sin bloquearse)

```
Sem 1:  A  T-02, ETL-1, T-03 ─┬─► C  ETL-4 ──► ETL-5 (ETL completo) ─┬─► B  MC-1, MC-2, ETL-6
        B  ETL-2, MC-3, RF-1  │                                       ├─► A  DB-1
        C  T-00, T-15, XG-1 ──┘                                       └─► C  VIZ-1
Sem 2-3: A  DB-2 ──► B  MC-4 (runner) ──► los 3: X-3 baseline y X-4 tuning
Sem 4:   cada uno persiste su run (X-6) ──► A  CMP-2 compare_runs
Sem 5:   C  CMP-3 gráficos ──► B  CMP-4 análisis ──► los 3: CMP-5 decisión
Sem 6:   F-1 run_all, F-2 revisión cruzada, F-3 informe, F-4 demo
```
**Mientras algo no esté listo:** trabajá contra el contrato y la BD que generaste con el ETL de referencia; si necesitás una función que todavía no existe, escribí un *stub* en tu rama y no lo mergees si choca con el real. Para los tests de resultados usá la fixture de C (`tests/fixtures.py`, VIZ-2).

**Orden de ejecución una vez integrado todo:**
```bash
python scripts/run_etl.py
python -m demanda.models.train --model logreg --features base       # A
python -m demanda.models.train --model rf     --features base       # B
python -m demanda.models.train --model xgb    --features base       # C
streamlit run src/demanda/viz/app.py
```

---

## 8. Organización y comunicación

### Sincronía semanal (30 min)
Cada integrante responde: ¿qué tareas cerré (PR mergeado)? ¿en qué estoy? ¿qué me bloquea o qué necesito de otro? Se actualiza `docs/avance.md` y se revisa `git shortlog -sn --no-merges` para ver que los aportes estén equilibrados.

### Comunicación diaria
- Un canal único para avisos rápidos; **las decisiones técnicas se registran en el issue o PR**, no solo en el chat.
- Avisar cuando: se abre un PR que espera revisión, se cambia un contrato, **se mergea algo que desbloquea a otro** (ETL-5, DB-2, MC-4, CMP-2), o hay un bloqueo.
- Si algo no se resuelve en el chat en 15 minutos: llamada breve.

### Tablero
GitHub Projects con columnas **Backlog → En progreso → En revisión → Hecho**. Los issues creados por el script se agregan al tablero; filtrar por label `persona-A/B/C` y por milestone.

### Equilibrio de aportes
- Tareas propias: A 14, B 15, C 15 (más las conjuntas). Revisar PRs también cuenta.
- Si alguien termina antes, toma una tarea de otro **acordándolo en el issue** (reasignar, no pisarse).

---

## 9. Problemas frecuentes

| Problema | Solución |
|---|---|
| "Mi commit no figura en mi perfil de GitHub" | El mail de `git config user.email` no coincide con el de la cuenta |
| "El PR no se puede mergear" | Conflicto con `main`: `git merge main` en tu rama |
| Conflicto de merge | `git merge main` marca los archivos; buscar `<<<<<<<`, decidir con quien tocó el mismo archivo, `git add` y `git commit`. Si dos personas editan siempre el mismo archivo, dividirlo |
| "CI falla solo en GitHub" | Dependencia faltante en `requirements.txt` o ruta absoluta en el código |
| "Mis resultados no coinciden con los de mis compañeros" | Revisar semilla, `split`, versión de scikit-learn y que todos usen el mismo `feature_set` |
| "Me falta una función de otro" | Contrato + stub en tu rama; avisar en el issue |
| "Rompí `main`" | No hacer force-push; PR con `git revert <commit>` y avisar |
| "Subí `demanda.db` por error" | `git rm --cached db/demanda.db`; ya está en `.gitignore`; commit y push |
| "XGBoost falla con las etiquetas" | Etiquetas de texto: usar el wrapper de XG-2 |
| "Las probabilidades salen en columnas cambiadas" | `classes_` es alfabético (Alta, Crítica, Normal): mapear por nombre, no por posición |
| "El agente cambió archivos de otro" | `git checkout -- <archivo>` y recordarle `CLAUDE.md` |
| "Un fold de la CV no tiene clase Crítica" | Esperable en los primeros folds (picos chicos en 2001-2005): ver `check_cv_class_presence` (MC-2) y el F1 macro con `zero_division=0` |
| "Los resultados son casi perfectos" | Sospechar fuga: revisar el set de features y comparar con la ablación `sin_potencia` |

---

## 10. Checklist de entrega final

- [ ] `python scripts/run_all.py --reset` regenera todo desde cero.
- [ ] ETL con tests verdes y auditoría en `etl_auditoria`.
- [ ] Los 3 modelos entrenados y persistidos con su `run_id` en Tablas 2 y 3.
- [ ] Métricas (Accuracy, Precision, Recall, F1) y matriz de confusión de cada modelo, con la ablación de features.
- [ ] Comparación documentada y decisión según `specs/03-comparacion.md`, **con las limitaciones** (62 meses de test, 3 Alta, deriva estacional).
- [ ] Dashboard funcionando contra `demanda.db`.
- [ ] Todos los issues cerrados y PRs mergeados sin squash; 3+ commits por tarea y por integrante.
- [ ] Informe final con una sección por integrante y README de instalación y ejecución.
