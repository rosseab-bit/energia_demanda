# Diccionario de datos

Fuente: `data/raw/demanda_electricidad_original_mensual1.csv` · 308 filas × 30 columnas · serie **mensual** 2001-01 a 2026-08 (sin meses faltantes). Unidades de demanda y potencia: tal como vienen en el origen (confirmar con la fuente y completar abajo).

## Columnas del CSV crudo

| Columna | Tipo | Disponible | Descripción |
|---|---|---|---|
| `indice_tiempo` | fecha | 2001-01 → 2026-08 | Primer día de cada mes |
| `demanda_total` | float | completa | Demanda total del mes |
| `demanda_residencial` | float | 2005-01 → 2026-08 (48 nulos al inicio) | Sector residencial |
| `comercio_e_industria` | float | ídem | Sector comercio e industria |
| `grandes_usuarios` | float | ídem | Grandes usuarios |
| `temperatura_promedio` | float (°C) | completa | Temperatura media del mes (rango 9,3 – 27,1) |
| `potencia_maxima` | float | completa | Potencia máxima del mes |
| 23 columnas de distribuidoras (`ede_tucuman`, `edenor_distribuidor`, `epec_distribuidor`, …) | float | 2014-01 → 2026-06 (158 nulos: 2001-2013 y 2026-07/08) | Demanda por empresa distribuidora |

## Hallazgos de calidad (verificados sobre el CSV)

1. **Sectores:** en las filas donde existen, `residencial + comercio_e_industria + grandes_usuarios = demanda_total` de forma exacta. Consecuencia: si la etiqueta se deriva de `demanda_total`, los sectores en valores absolutos **la reconstruyen** (fuga de datos). Usar participaciones (`part_*`) o excluirlos; se compara en el experimento de ablación (ver `specs/03-comparacion.md`).
2. **Distribuidoras:** cubren en promedio ~71 % de `demanda_total` (66 %–76 %); **no** suman el total. No se usan como features en la v1; se guardan en formato largo en `demanda_distribuidora`.
3. **`potencia_maxima`** tiene correlación ≈ 0,96 con `demanda_total` (y `temperatura_promedio` ≈ 0,04 con la demanda total, pues el efecto es no lineal: sube en verano y en invierno). Es una variable concurrente muy informativa; se mantiene como feature pero se evalúa su peso en la ablación.
4. **Tendencia:** la demanda anual media crece de ~6.500 (2001) a ~12.200 (2026). Con percentiles globales, los meses recientes caerían casi todos en Alta/Crítica. Por eso la etiqueta por defecto es `relativo_tendencia` (demanda / media móvil centrada de 12 meses).
5. **Estacionalidad:** picos en enero, julio y diciembre; mínimos en abril y septiembre-octubre. La amplitud del pico estacional **crece** con los años (ratio máximo a la tendencia: 1,05 en 2001 → 1,16–1,19 en 2023-2025), por lo que hay más meses Crítica en el período de test que en el de train.
6. Sin valores negativos ni outliers (|z| > 3) en `demanda_total`.

## Tabla `datos_limpios` (Tabla 1 — salida del ETL)

Clave primaria: `fecha` (TEXT ISO `YYYY-MM-01`).

| Columna | Origen / regla |
|---|---|
| `anio`, `mes`, `trimestre` | Derivadas de la fecha |
| `estacion` | Verano (dic-feb), Otoño (mar-may), Invierno (jun-ago), Primavera (sep-nov) — hemisferio sur |
| `mes_sin`, `mes_cos` | Codificación cíclica del mes (dic y ene quedan cercanos) |
| `demanda_total`, `temperatura_promedio`, `potencia_maxima` | Copia validada (sin nulos) |
| `demanda_residencial`, `comercio_e_industria`, `grandes_usuarios` | Copia; **NULL antes de 2005-01** (no se imputa en el ETL) |
| `part_residencial`, `part_comercio_industria`, `part_grandes_usuarios` | sector / `demanda_total`; NULL si no hay sectores |
| `tiene_sectores` | 1 si los tres sectores están presentes |
| `demanda_ratio_tendencia` | `demanda_total` / media móvil centrada 12 m (solo método `relativo_tendencia`). **Derivada de la etiqueta: no usar como feature** |
| `etiqueta` | `Normal` (≤ P75), `Alta` (P75–P90), `Crítica` (> P90); umbrales calculados **solo con train** |
| `split` | `train` (primeros 80 % de los meses) / `test` (últimos 20 %), cronológico |

Columnas **prohibidas como feature** (definidas en `config.yaml`): `fecha`, `etiqueta`, `split`, `demanda_total`, `demanda_ratio_tendencia`.

## Tablas extra del ETL

- `demanda_distribuidora(fecha, distribuidora, demanda)` — formato largo, 150 meses × 23 distribuidoras = 3.450 filas.
- `etl_auditoria` — una fila por corrida: archivo, SHA-256, filas leídas/cargadas, nulos por columna, umbrales de etiqueta, advertencias y configuración usada.
