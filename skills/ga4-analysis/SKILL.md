---
name: ga4-analysis
description: >
  Análisis de GA4: orgánico vs pagado, attribution models, channel groupings,
  DebugView, informes de adquisición, métricas de engagement, comparativa de
  períodos. Cubre también integración con GSC y Google Ads. Aplica cuando se
  pide interpretar datos de tráfico, analizar caídas, o cruzar fuentes de
  adquisición.
user-invokable: false
---

# GA4 Analysis — Knowledge Base

## Diferencias clave UA → GA4

| Universal Analytics | GA4 |
|---|---|
| Sesiones como unidad central | Eventos como unidad central |
| Bounce rate | Engaged sessions / Engagement rate |
| Goals | Conversions (cualquier evento marcado) |
| Views | Data Streams |
| Attribution: último clic por defecto | Attribution: Data-driven por defecto |
| Pageviews = hits | `page_view` = evento automático |
| Sampling en vistas | Sin sampling (BigQuery para volumen) |

---

## Estructura de datos en GA4

### Jerarquía

```
Account → Property → Data Stream (web / iOS / Android)
```

Un Data Stream = un snippet de medición (gtag.js o GTM).

### Tipos de eventos

| Tipo | Quién lo crea | Ejemplos |
|---|---|---|
| Automáticos | GA4 | `page_view`, `session_start`, `first_visit`, `scroll` (90%) |
| Medición mejorada | GA4 (opcional) | `click` (salidas), `view_search_results`, `file_download`, `video_start` |
| Recomendados | Dev/GTM | `purchase`, `generate_lead`, `sign_up`, `add_to_cart` |
| Personalizados | Dev/GTM | Cualquier nombre no reservado |

Activar medición mejorada: GA4 Admin > Data Streams > Enhance Measurement.

---

## Orgánico vs Pagado — Análisis de adquisición

### Ruta en GA4

Reports > Acquisition > Traffic Acquisition
- Dimension principal: **Session default channel group**
- Dimension secundaria: Session source / Session medium / Session campaign

### Channel groups relevantes

| Channel | Condición (simplificada) |
|---|---|
| Organic Search | medium = organic |
| Paid Search | medium = cpc/ppc/paidsearch |
| Organic Social | medium = social/social-network + source en lista conocida |
| Paid Social | medium = paid-social/social_paid |
| Direct | source = (direct), medium = (none) |
| Referral | medium = referral |
| Email | medium = email |
| Display | medium = display/banner/cpm |

**Problema habitual:** UTMs mal configurados en campañas de pago → tráfico de pago cae en Organic Search o en "Unassigned". Verificar siempre los UTMs de campañas activas cuando el tráfico orgánico sube repentinamente.

### Cómo separar orgánico de pago en un informe

1. Reports > Acquisition > Traffic Acquisition
2. Añadir filtro: Session default channel group = Organic Search
3. Comparar períodos para detectar variaciones

O con dimensión secundaria "Session source/medium":
- `google / organic` = SEO
- `google / cpc` = Google Ads
- `(direct) / (none)` = Direct (incluye dark social y tráfico no atribuido)

---

## Atribución en GA4

### Modelos disponibles (2025)

| Modelo | Descripción | Cuándo usar |
|---|---|---|
| Data-driven | Machine learning distribuye el crédito | Default, cuando hay suficiente volumen |
| Last click | 100% al último canal antes de conversión | Comparativa con UA |
| First click | 100% al primer canal | Awareness analysis |
| Linear | Distribución igual entre todos los touchpoints | Sin datos ML |
| Time decay | Más crédito a touchpoints más cercanos a conversión | — |
| Position-based | 40% primero, 40% último, 20% resto | — |

**Cambio de modelo:** GA4 Admin > Attribution Settings > Reporting attribution model.

### Lookback windows

- Adquisición (first user): 30 días por defecto.
- Engagement (otras conversiones): 30 días clic, 1 día visualización por defecto.
- Modificables en Attribution Settings.

### Por qué GA4 y Google Ads muestran cifras distintas

1. **Modelo de atribución diferente:** GA4 data-driven vs Ads last-click.
2. **Cross-device:** GA4 puede atribuir a orgánico si el mismo usuario buscó en móvil sin clic en ad.
3. **Import delay:** Las conversiones importadas de GA4 a Ads tienen lag de 24-48h.
4. **Conversiones importadas vs Conversiones de Ads:** Ads puede contar smart bidding conversions adicionales.

---

## Métricas de engagement (reemplaza bounce rate)

| Métrica | Definición |
|---|---|
| Engaged sessions | Sesiones con ≥1 evento de conversión, ≥2 páginas vistas, O ≥10 segundos de duración |
| Engagement rate | Engaged sessions / Total sessions |
| Bounce rate (GA4) | 1 - Engagement rate (inverso) |
| Average engagement time | Tiempo activo en primer plano (no tiempo en página pasivo) |

Una sesión con un único pageview y 15 segundos = sesión engaged (>10s). UA la contaría como bounce.

---

## Comparativa de períodos

### Herramientas en GA4

1. Reports: date picker > "Compare" > Previous period / Previous year.
2. Explorations: tabla con columnas calculadas para % de variación.
3. Insights automáticas: GA4 detecta anomalías estadísticas y las reporta en Overview.

### Cómo interpretar caídas de tráfico orgánico

1. Aislar canal: filtrar solo Organic Search.
2. Separar por país/dispositivo para descartar cambios en audiencia.
3. Verificar si la caída es en sesiones o en usuarios (si solo caen sesiones, puede ser cambio en comportamiento de regreso, no en adquisición).
4. Cruzar con Google Search Console:
   - GSC muestra impresiones + clics reales de Google. Si bajan en paralelo → problema de visibilidad.
   - Si GA4 baja pero GSC no → problema de tracking (GTM, Consent Mode).
5. Cruzar con fechas de Google Algorithm Updates (ver instrucciones en CLAUDE.md).

---

## Integración GA4 + Google Search Console

### Requisitos

GA4 Admin > Property Settings > Search Console linking.
El usuario de GA4 debe tener permisos en GSC.

### Qué datos aparecen

Reports > Acquisition > Search Console:
- Google organic search queries
- Google organic search traffic (landing pages)

**Limitación importante:** Los datos de GSC en GA4 son para sesiones que vinieron de Google orgánico Y donde GA4 registró la sesión. Si Consent Mode bloquea GA4 para algunos usuarios, habrá discrepancia con los datos directos en GSC.

---

## Integración GA4 + Google Ads

### Setup

GA4 Admin > Google Ads linking.

Una vez vinculado:
- Las conversiones de GA4 se pueden importar a Google Ads.
- Los datos de Ads aparecen en GA4 Reports > Acquisition.
- Remarketing audiences de GA4 disponibles en Ads.

### Análisis orgánico vs pagado en GA4 con Ads vinculado

Exploration > Free Form:
- Dimensión: Session default channel group
- Métricas: Sessions, Conversions, Revenue (si e-commerce)
- Filtro: incluir solo "Organic Search" y "Paid Search"

Permite ver ROAS efectivo de pago vs tráfico orgánico side-by-side.

---

## DebugView

Ruta: GA4 Admin > DebugView

### Activar

**Opción 1 — GTM:** En GA4 Configuration Tag, añadir Field `debug_mode` = `true`.
**Opción 2 — Chrome Extension:** "Google Analytics Debugger" activa debug automáticamente.
**Opción 3 — URL param:** `?_gl=debug` (no documentado oficialmente).

### Qué muestra

- Eventos en tiempo real (< 1 minuto).
- Parámetros de cada evento expandibles.
- Device ID para seguir un usuario específico.
- Errores de validación de parámetros (p.ej., parámetro excede 100 caracteres).

### Casos de uso

- Verificar que un evento de GTM llega correctamente antes de publicar.
- Confirmar parámetros de e-commerce (items array, transaction_id, value).
- Diagnosticar por qué una conversión no se registra.

---

## Informes más útiles para SEO

### Organic landing pages

Reports > Engagement > Landing Page
Filtrar: Session default channel group = Organic Search
Ordenar por: Sessions desc

Muestra qué páginas reciben más tráfico orgánico. Útil para identificar páginas en declive.

### Organic queries (vía Search Console)

Reports > Acquisition > Search Console > Google organic search queries
Muestra queries con clics, impresiones, CTR, posición promedio en el mismo informe de GA4.

### Páginas con alta tasa de rebote orgánico

Explorations > Free Form:
- Dimensión: Landing page + query string
- Métricas: Sessions, Bounce rate, Average engagement time
- Filtro: Organic Search
- Ordenar por: Bounce rate desc + Sessions > umbral mínimo (ej. >100)

Identifica páginas donde los usuarios orgánicos llegan y se van — señal de mismatch entre intent de búsqueda y contenido.

---

## Dimensiones y métricas clave (referencia rápida)

| Concepto | Dimensión/Métrica en GA4 |
|---|---|
| Canal de adquisición | Session default channel group |
| Fuente/medio | Session source/medium |
| Página de entrada | Landing page + query string |
| Dispositivo | Device category |
| País | Country |
| Sesiones | Sessions |
| Usuarios activos | Active users |
| Nuevos usuarios | New users |
| Tasa de engagement | Engagement rate |
| Conversiones | Conversions |
| Ingresos | Total revenue (e-commerce) |

---

## Errores comunes de configuración

| Error | Síntoma | Solución |
|---|---|---|
| Tráfico de pago en Organic | UTMs incorrectos o ausentes en campañas | Auditar UTM builder, verificar en GSC vs GA4 |
| Sesiones infladas | Una visita = múltiples sesiones | Timeout de sesión ajustado muy bajo (default: 30min) |
| Self-referral | El propio dominio aparece como fuente | Añadir dominio en GA4 Admin > Data Streams > Configure Tag Settings > List unwanted referrals |
| Conversiones duplicadas | Mismo evento marcado como conversión en GTM y en GA4 | Marcar solo en uno de los dos |
| Tráfico directo excesivo | Dark social, email sin UTM, copia-pega de URL | Normal hasta ~20-25%; por encima, revisar UTMs de newsletters y social |

---

## Exportación a BigQuery

GA4 Admin > BigQuery linking (gratuito para GA4 standard).

Exporta crudos de eventos diarios. Útil para:
- Análisis histórico sin sampling.
- Combinación con otras fuentes de datos.
- Informes personalizados sin límites de GA4 UI.

Tablas: `events_YYYYMMDD` y `events_intraday_YYYYMMDD`.

---

## Referencias

- GA4 Help Center: https://support.google.com/analytics
- GA4 Dimensions & Metrics: https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema
- Attribution Settings: https://support.google.com/analytics/answer/10597962
- GA4 + Search Console: https://support.google.com/analytics/answer/10737381
- BigQuery Export schema: https://support.google.com/analytics/answer/7029846
