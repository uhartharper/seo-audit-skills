---
name: se-ranking
description: >
  Interpretación de datos de SE Ranking en auditorías SEO: rank tracking,
  histórico de posiciones, Site Audit, keyword research, competitor gap,
  estimaciones de tráfico. Cómo cruzar con Screaming Frog, Semrush y GSC.
  Señales a priorizar y falsos positivos conocidos.
user-invokable: false
---

# SE Ranking — Knowledge Base

## Rol en el flujo de auditoría

SE Ranking es la fuente principal de:
- Posiciones actuales e históricas por keyword
- Variaciones de ranking (subidas/bajadas)
- Estimación de tráfico orgánico (referencial, no absoluto)
- Detección de keywords canibalización (misma keyword, varias URLs rankeando)
- Competitor gap (keywords del competidor que el cliente no tiene)

**No usar SE Ranking para:** estado de indexación, diagnóstico técnico de páginas concretas, validación de meta tags. Para eso: GSC + Screaming Frog + WebFetch.

---

## Rank Tracking — Interpretación de posiciones

### Volatilidad vs caída real

| Patrón | Interpretación |
|---|---|
| Posición fluctúa ±3 en días consecutivos | Volatilidad normal del SERP, no acción |
| Caída sostenida >5 posiciones en 7+ días | Señal real — cruzar con GSC impresiones |
| Caída brusca en un día (>10 posiciones) | Posible update de Google o penalización — cruzar con fechas de updates |
| Sube y baja alternando cada día | Google está testando posiciones — esperar 2 semanas |
| Desaparece del top 100 | URL desindexada o penalización grave — verificar con GSC URL Inspection |

### Antes de actuar sobre una caída

1. Confirmar en GSC que las impresiones también cayeron (si GSC muestra impresiones estables pero SE Ranking baja → posible error de medición o SERP feature desplazando posición sin pérdida de visibilidad real).
2. Cruzar con historial de Google Updates (CLAUDE.md: siempre cruzar caídas con updates).
3. Verificar que la URL sigue indexada: GSC URL Inspection o `site:dominio.com/url`.
4. Comprobar si el competidor que ocupó la posición es nuevo o si subió un resultado existente.

### SERP Features

SE Ranking muestra si la keyword tiene Features activos (Featured Snippet, PAA, Local Pack, etc.). Tener en cuenta:
- Una keyword en posición 4 con Featured Snippet del cliente puede generar más CTR que posición 1 sin feature.
- Si el cliente perdió un Featured Snippet, la caída de posición SE Ranking puede ser menor de lo que parece pero el impacto en tráfico es mayor.

---

## Site Audit de SE Ranking

### Limitación crítica

SE Ranking Site Audit es un crawler estático (no renderiza JS). Los issues que reporta sobre páginas JavaScript-rendered deben validarse con Screaming Frog en modo JS o WebFetch antes de confirmar.

**Regla:** Issues de SE Ranking = señales. Validar antes de incluir en informe al cliente.

### Priorización de issues por impacto real

**Alta prioridad (validar primero):**
- Páginas con `noindex` en producción (especialmente si el cliente no las puso intencionalmente)
- Redirects en cadena (3+) o redirect loops
- Páginas con status 4xx/5xx en el sitemap
- Duplicate title/meta description en páginas de categoría o producto
- Canonical apuntando a URL diferente a la indexada

**Media prioridad:**
- Title demasiado largo/corto (validar con WebFetch — SF/SE Ranking pueden truncar mal)
- H1 ausente (en sitios con Divi/Elementor, puede existir en el DOM aunque no lo detecte el crawler)
- Meta description ausente (verificar si hay schema o snippet alternativo)

**Baja prioridad / falsos positivos frecuentes:**
- "Missing alt text" en imágenes decorativas (CSS background o SVG icons)
- "Thin content" en páginas de categoría con paginación (el crawler ve solo la página, no el conjunto)
- "Multiple H1" en páginas con Elementor/Divi (a veces el theme header genera un H1 invisible)

---

## Estimación de tráfico orgánico

SE Ranking muestra tráfico estimado basado en posiciones × CTR esperado × volumen de keyword.

### Precisión esperada

- Para sitios grandes con muchas keywords: margen de error ±40-60%.
- Para sitios pequeños o nicho: puede ser muy inexacto.
- No usar como cifra absoluta. Usar como **indicador de tendencia**: si el estimado sube 30% MoM, es señal de crecimiento real aunque la cifra exacta sea imprecisa.

### Comparar con fuentes reales

| Fuente | Precisión | Uso |
|---|---|---|
| GA4 organic sessions | Alta (real) | Cifra real de tráfico |
| GSC clics | Alta (real) | Tráfico desde Google específicamente |
| SE Ranking tráfico estimado | Baja-media | Tendencia, comparativa vs competidores |
| Semrush tráfico estimado | Baja-media | Ídem |

Si GA4/GSC muestran estabilidad pero SE Ranking muestra caída en tráfico estimado → probable cambio en composición de keywords (el cliente perdió keywords de volumen alto pero ganó muchas de volumen bajo).

---

## Keyword Research en SE Ranking

### Flujo recomendado

1. **Seed keywords** desde el negocio del cliente (no empezar desde herramienta).
2. **Keyword Suggestions** en SE Ranking para expandir.
3. **Filtrar por dificultad** — para sitios nuevos o con poca autoridad: KD < 40.
4. **Agrupar por intent** antes de asignar a páginas:
   - Informacional → blog/guía
   - Navegacional → homepage/about
   - Comercial → categoría/producto
   - Transaccional → producto/landing de conversión
5. **Verificar canibalización** antes de asignar: buscar si alguna URL del sitio ya rankea para esa keyword (SE Ranking > Rankings > filtrar por keyword).

### Volumen: SE Ranking vs Semrush vs Google Ads

SE Ranking usa datos de Google Ads Keyword Planner como fuente. Semrush también. Las cifras pueden diferir por:
- Diferente fecha de extracción
- Diferente agrupación de variantes
- Semrush agrupa más variantes en un mismo término principal

Para decisiones importantes, cruzar con Google Ads Keyword Planner directamente o con la skill `google-tag-manager` > sección keywords (Tier 3).

---

## Competitor Analysis

### Competitor Gap (keywords del competidor que el cliente no tiene)

SE Ranking > Competitive Research > Compare.

Filtros útiles:
- Posición competidor: 1-10 (keywords donde ya rankea bien)
- Volumen: > umbral mínimo según el nicho
- Dificultad: ajustar según autoridad del cliente

**Antes de proponer contenido nuevo:** verificar post-sitemap.xml del cliente (regla de CLAUDE.md — canibalización).

### Share of Voice

SE Ranking muestra visibilidad relativa entre el cliente y sus competidores para un conjunto de keywords rastreadas. Útil para:
- Presentar evolución al cliente en términos de mercado, no solo posiciones
- Identificar en qué categorías de keywords el cliente está perdiendo terreno

---

## Integración con otras herramientas

### SE Ranking + GSC

- SE Ranking posiciones vs GSC posición media: pueden diferir porque SE Ranking mide desde una ubicación fija, GSC agrega todas las localizaciones/dispositivos.
- Si GSC muestra posición media 8 y SE Ranking muestra posición 12 → normal; GSC incluye rankings de imagen, noticias, etc.
- Para caídas: GSC es la fuente de verdad sobre visibilidad real en Google.

### SE Ranking + Screaming Frog

- SE Ranking identifica qué URLs rankean → Screaming Frog audita esas URLs en profundidad.
- Flujo: exportar top URLs rankeadas de SE Ranking → crawl selectivo en SF sobre esas URLs.
- Issues técnicos en URLs que rankean bien tienen mayor prioridad de corrección.

### SE Ranking + Semrush

- SE Ranking: posiciones reales de las keywords que el cliente rastrea (conjunto definido).
- Semrush: visibilidad estimada del dominio completo, incluyendo keywords no rastreadas.
- Usar Semrush para descubrir keywords no monitorizadas. Añadir las relevantes al proyecto de SE Ranking.

---

## Exports y formatos

SE Ranking exporta CSV/Excel para:
- Rankings históricos por keyword
- Site Audit issues
- Backlinks
- Competitor keywords

Al trabajar con exports de SE Ranking en análisis, las columnas clave son:
- `Keyword`, `Search Volume`, `Position`, `Previous Position`, `URL`, `Difficulty`, `Traffic Forecast`
- Para histórico: columnas de fecha por período rastreado

---

## Falsos positivos documentados

| Issue reportado | Por qué puede ser falso | Validación |
|---|---|---|
| H1 missing | Divi/Elementor generan H1 en JS | WebFetch o SF modo JS |
| Duplicate content | Paginación, filtros de categoría | Verificar canonical |
| Slow page speed | Medición sin caché de CDN | PSI real o CrUX |
| Broken links | Links en JS no renderizado | SF modo JS o crawl manual |
| Missing meta description | CMS genera dinámica en JS | WebFetch directo |
