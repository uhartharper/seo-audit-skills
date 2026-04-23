---
name: semrush
description: >
  Uso e interpretación de Semrush en auditorías SEO: Organic Research,
  Keyword Gap, Backlink Gap, Site Audit, Traffic Analytics, Position Tracking.
  Cómo cruzar con SE Ranking, Screaming Frog y GSC. Precisión de datos
  y cuándo confiar en cada fuente.
user-invokable: false
---

# Semrush — Knowledge Base

## Rol en el flujo de auditoría

Semrush complementa SE Ranking y Screaming Frog con:
- Visión del dominio completo (no solo keywords rastreadas manualmente)
- Competitive intelligence: keywords de competidores, backlinks, comparativa de dominios
- Estimación de autoridad de dominio (Authority Score)
- Backlink profile inicial antes de usar herramientas especializadas
- Keyword research con intención de búsqueda clasificada

**No usar Semrush como fuente única para:** posiciones exactas (usar SE Ranking), estado técnico de páginas (usar SF), tráfico real (usar GA4/GSC).

---

## Organic Research

Ruta: Semrush > Organic Research > dominio del cliente

### Qué muestra

- Keywords orgánicas estimadas en top 100
- Tráfico orgánico estimado (mensual)
- Authority Score del dominio
- Distribución de posiciones (top 3, 4-10, 11-20, 21-50, 51-100)
- Páginas top rankeadas

### Cómo usar en auditoría

1. **Distribución de posiciones** → Si >60% de keywords están en posiciones 21-100, el sitio tiene potencial pero necesita mejoras de contenido/autoridad para subir.
2. **Top páginas** → Las páginas que más tráfico orgánico reciben. Cruzar con GA4 para confirmar. Son las páginas prioritarias en la auditoría.
3. **Tendencia histórica** → Gráfico de tráfico estimado en el tiempo. Cruza con Google Updates para detectar correlaciones.
4. **Branded vs non-branded** → Filtrar keywords que contienen el nombre del cliente vs las que no. Un sitio dependiente de tráfico branded es vulnerable.

### Precisión de los datos de Semrush

| Métrica | Precisión | Notas |
|---|---|---|
| Tráfico estimado | Baja-media (±40%) | Solo referencial, comparativa vs competidores |
| Posiciones | Media | Puede diferir de SE Ranking por fecha de extracción |
| Keywords totales | Media | Semrush indexa un subconjunto de SERPs |
| Authority Score | Referencial | No es PageRank; algoritmo propio de Semrush |

---

## Keyword Gap (competitor analysis)

Ruta: Semrush > Keyword Gap > introducir dominio cliente + dominios competidores

### Filtros más útiles para identificar oportunidades

- **Missing**: keywords donde los competidores rankean pero el cliente NO aparece en top 100. Mayor oportunidad.
- **Weak**: keywords donde el cliente rankea pero en posición muy inferior a los competidores. Oportunidad de mejora.
- **Untapped**: keywords donde al menos 2 competidores rankean pero el cliente no. Valida demanda antes de crear contenido.

### Flujo recomendado

1. Exportar "Missing" filtrado por volumen > X (ajustar según nicho) y KD < 50.
2. Agrupar por intent con la columna "Intent" de Semrush.
3. Verificar post-sitemap.xml del cliente para descartar canibalización de intent antes de proponer contenido nuevo.
4. Priorizar los que tienen intent Transaccional o Comercial si el cliente busca conversiones.

### Intents en Semrush

| Intent | Icono | Qué significa |
|---|---|---|
| Informational | I | El usuario busca información |
| Navigational | N | El usuario busca una marca/sitio específico |
| Commercial | C | El usuario está investigando para comprar |
| Transactional | T | El usuario quiere completar una acción (compra, registro) |

---

## Backlink Gap

Ruta: Semrush > Backlink Gap

Compara el perfil de backlinks del cliente vs competidores para identificar dominios que enlazan a los competidores pero no al cliente.

### Cómo usar

1. Exportar dominios que enlazan a 2+ competidores pero no al cliente.
2. Filtrar por Authority Score > 30 (dominios con cierta relevancia).
3. Evaluar si son oportunidades reales de link building o solo directorios/spam.

**Nota:** Para análisis profundo de backlinks, las herramientas especializadas (Ahrefs, Moz, o la skill `seo-backlinks`) son más precisas. Semrush Backlink Gap es útil para una primera vista comparativa rápida.

---

## Site Audit de Semrush

### Posición en el flujo

Semrush Site Audit es un crawler básico. En el flujo de auditoría:
- SF es el crawler principal (más datos, más configuración)
- Semrush Site Audit es un check secundario o para clientes sin licencia de SF

### Diferencias con Screaming Frog

| Funcionalidad | Semrush Site Audit | Screaming Frog |
|---|---|---|
| JS Rendering | Limitado | Completo (modo dedicado) |
| Velocidad | Más lento (servidor remoto) | Más rápido (local) |
| Datos on-page | Básicos | Muy detallados |
| Integración GSC/GA4 | Sí | Sí |
| Custom extraction | No | Sí (regex) |
| Core Web Vitals | Sí (via API) | Sí (via PSI API) |
| Crawl budget analysis | Básico | Avanzado |

### Issues de Site Audit: falsos positivos frecuentes

Los mismos que Screaming Frog en modo Spider. Ver skill `screaming-frog` > sección Falsos Positivos.

---

## Traffic Analytics

Ruta: Semrush > Traffic Analytics > dominio

Estimación de tráfico total (no solo orgánico) basada en clickstream data.

### Cuándo es útil

- Comparar tráfico estimado del cliente vs competidores (en términos relativos, no absolutos)
- Ver qué canales usa el competidor (Direct, Search, Social, Referral, Paid)
- Identificar si un competidor está invirtiendo fuertemente en Paid Search (señal para la estrategia)

### Cuándo NO usar

- Para reportar tráfico real del cliente → usar GA4
- Para tomar decisiones sobre keywords específicas → usar SE Ranking + GSC

---

## Position Tracking en Semrush vs SE Ranking

Si el cliente tiene SE Ranking configurado correctamente, no es necesario duplicar el tracking en Semrush.

**Usar Semrush Position Tracking solo para:**
- Comparativa directa con competidores en las mismas keywords (Share of Voice)
- Clientes sin SE Ranking aún configurado

### Por qué las posiciones difieren entre herramientas

- Diferente fecha/hora de medición
- Diferente localización de la solicitud (SF mide desde UK por defecto, SE Ranking desde España si está configurado así)
- Diferentes SERPs: Semrush puede medir desde datacenter distinto

---

## Authority Score

Métrica propia de Semrush. No equivale a PageRank de Google.

| AS | Interpretación general |
|---|---|
| < 20 | Dominio nuevo o sin backlinks relevantes |
| 20-40 | Autoridad baja-media, típico de PYMES locales |
| 40-60 | Autoridad media, sitios establecidos con backlinks |
| 60-80 | Autoridad alta, publishers o marcas con presencia nacional |
| > 80 | Dominios de referencia (Wikipedia, periódicos, etc.) |

**Usar como referencia comparativa**, no como objetivo absoluto. Lo importante es la tendencia (¿sube o baja?) y la posición relativa vs competidores directos.

---

## Exports útiles para informes

| Export | Ruta en Semrush | Uso |
|---|---|---|
| Organic keywords | Organic Research > Positions > Export | Base para análisis de visibilidad |
| Top pages | Organic Research > Pages > Export | Páginas prioritarias del cliente |
| Missing keywords | Keyword Gap > Missing > Export | Oportunidades de contenido |
| Referring domains | Backlink Analytics > Referring Domains | Perfil de backlinks |
| Competitor comparison | Traffic Analytics > Bulk Analysis | Comparativa de canales |

---

## Integración con otras herramientas del flujo

### Semrush + SE Ranking

- Semrush: visión completa del dominio, discovery de keywords no rastreadas
- SE Ranking: seguimiento preciso de keywords definidas, histórico de posiciones

Flujo: Semrush identifica keywords valiosas no rastreadas → añadir al proyecto de SE Ranking.

### Semrush + GSC

- Semrush tráfico estimado vs GSC clics reales: usar GSC como verdad
- Si Semrush estima mucho más tráfico que GSC muestra en clics → probable que haya keywords rankeando en imágenes, noticias u otros SERPs que no generan clics web

### Semrush + Screaming Frog

- Semrush identifica páginas con tráfico estimado
- SF audita esas páginas en profundidad
- Priorizar correcciones técnicas en páginas que Semrush marca con tráfico relevante

---

## Limitaciones a comunicar al cliente

- Las cifras de tráfico de Semrush son estimaciones, no datos reales.
- El Authority Score es una métrica de Semrush, no una señal directa de Google.
- Semrush puede no indexar todas las keywords de nicho — especialmente en nichos locales o en español con poco volumen.
- Los datos de backlinks pueden tener lag de varias semanas vs backlinks reales actuales.
