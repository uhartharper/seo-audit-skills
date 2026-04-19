---
name: screaming-frog
description: >
  Uso e interpretación de Screaming Frog SEO Spider en auditorías técnicas.
  Modos de crawl (Spider vs JS Rendering), configuración por tipo de CMS,
  reports clave, exportación y cruce con GSC/GA4/PSI. Limitaciones y
  falsos positivos frecuentes.
user-invokable: false
---

# Screaming Frog SEO Spider — Knowledge Base

## Rol en el flujo de auditoría

Screaming Frog es la fuente principal de:
- Inventario completo de URLs del sitio
- Status codes (200, 301, 302, 404, 500)
- Redirects y cadenas de redirect
- Datos on-page: title, meta description, H1, H2, canonical, meta robots
- Estructura de enlaces internos
- Detección de páginas huérfanas (sin enlaces entrantes internos)
- Imágenes: alt text, tamaño, formato

**Limitación fundamental:** En modo Spider (sin JS rendering), no ejecuta JavaScript. Todo lo que un CMS genera dinámicamente (títulos via JS, contenido de SPA, lazy load) no será visible. Ver sección Modos de Crawl.

**Regla de CLAUDE.md:** Los datos de SF son señales, no conclusiones. Validar issues con WebFetch antes de confirmar, especialmente en sitios con Divi, Elementor o cualquier constructor de páginas con JS.

---

## Modos de Crawl

### Spider Mode (defecto)

Comportamiento de Googlebot sin rendering de JS. Rápido, bajo consumo de recursos.

**Usar para:**
- Inventario inicial de URLs
- Status codes y redirects
- Detección de issues en sitios con HTML estático o WordPress con contenido en PHP

**No usar para:**
- Sitios Divi/Elementor donde H1, title o meta description se generan vía JS
- SPAs o sitios con React/Vue/Angular
- Cualquier contenido que requiera rendering para ser visible

### JavaScript Rendering Mode

SF usa Chromium integrado para renderizar cada página antes de crawlearla. Comportamiento similar a Googlebot con rendering habilitado.

**Activar:** Configuration > Spider > Rendering > JavaScript

**Cuándo usar:**
- Clientes con Divi, Elementor, o cualquier page builder
- Cuando WebFetch muestra un H1 diferente al que SF detecta en modo Spider
- Cuando SE Ranking o Semrush reportan keywords para las que la página debería optimizar pero SF no detecta el contenido relevante

**Desventaja:** 5-10x más lento. Consumo alto de RAM para sitios grandes. En sitios con >5.000 URLs, considerar crawl selectivo (lista de URLs específicas) en lugar de crawl completo en modo JS.

### Crawl selectivo (lista de URLs)

Mode > List. Pegar o importar lista de URLs específicas.

**Usar para:**
- Auditar solo las URLs que rankean (exportadas desde SE Ranking)
- Re-auditar URLs corregidas tras implementar fixes
- Validar un subconjunto antes de un informe

---

## Configuración recomendada por CMS

### WordPress + Divi / Elementor

```
Configuration > Spider:
  - Rendering: JavaScript (obligatorio)
  - JS Rendering Timeout: 10 segundos (default 5 puede cortar rendering)
  - Crawl outside of start folder: unchecked (evita rastrear wp-admin)

Configuration > Exclusions:
  - /wp-admin/
  - /wp-login.php
  - /?s= (búsquedas internas)
  - /feed/
  - /xmlrpc.php

Configuration > Robots.txt:
  - Respect robots.txt: checked
```

### PrestaShop

```
Configuration > Spider:
  - Rendering: Spider mode (PS genera HTML en PHP, no JS)
  - Excepciones: páginas con filtros de categoría pueden ser JS

Configuration > Exclusions:
  - /module/
  - /?id_currency=
  - /?id_lang= (si multiidioma, crawl por idioma por separado)
  - /order/ (checkout)
  - /cart

Configuration > Custom:
  - Añadir header "Accept-Language: es-ES" para forzar idioma correcto
```

---

## Reports clave y qué buscar

### Response Codes

| Code | Qué revisar |
|---|---|
| 3xx | ¿Son redirects temporales (302) que deberían ser permanentes (301)? ¿Hay cadenas? |
| 404 | ¿Están enlazadas desde páginas internas? ¿Hay links rotos relevantes? |
| 500 | Errores de servidor — prioridad alta, afectan indexación |
| 200 con noindex | ¿Son intencionales? Páginas importantes con noindex accidental |

**Redirect chains:** Internal > Filter > "Redirect Chains". Cadenas de 3+ redirects pierden PageRank y ralentizan crawl.

### Page Titles

Filtros en SF:
- "Missing" → páginas sin title tag
- "Duplicate" → mismo title en múltiples URLs (canibalización potencial)
- "Over 60 characters" / "Under 30 characters" → fuera de rango recomendado

**Nota:** En Divi/Elementor, SF modo Spider puede reportar titles incorrectos. Validar con WebFetch.

### Meta Description

- "Missing" → no hay meta description (Google generará snippet automático)
- "Duplicate" → mismo texto en varias páginas
- "Over 155 characters" → se truncará en SERP

### H1

- "Missing" → validar con WebFetch antes de reportar (puede existir en JS)
- "Multiple" → más de un H1 en la página (problema real si son redundantes; puede ser intencional en diseños complejos)
- "Duplicate H1 = Title" → no es un issue, es buena práctica alineación

### Canonicals

Tab Canonicals o filtro en Internal:
- Canonical a URL diferente → ¿es intencional (paginación, filtros) o error?
- Canonical a URL que devuelve 404 → error crítico
- Páginas sin canonical → añadir para consolidar señales

### Directives (meta robots)

Filtros:
- "noindex" → listar todas. ¿Son todas intencionales?
- "nofollow" → ¿hay páginas importantes con nofollow en meta robots por error?
- Combinar con status 200 → páginas accesibles pero excluidas del índice

### Images

- "Missing Alt Text" → imágenes con rol de contenido sin alt. Imágenes decorativas (CSS background, íconos SVG inline) no aparecen aquí.
- "Alt Text Over 100 Characters" → alt text demasiado largo (potencial keyword stuffing)
- "Over 100kb" → imágenes sin optimizar

---

## Detección de páginas huérfanas

Bulk Export > All Inlinks → identificar URLs con 0 inlinks internos.

O: Site Structure > Crawl Depth → páginas a depth muy alta (>4 clicks desde home) tienen menor probabilidad de ser crawleadas regularmente.

**Páginas huérfanas importantes:** páginas que rankean en SE Ranking pero no tienen enlaces internos → oportunidad de mejora de PageRank interno.

---

## Integración con herramientas externas

### SF + Google Search Console

Configuration > API Access > Google Search Console.

Permite añadir columnas de GSC (impresiones, clics, posición) a cada URL en el crawl. Muy útil para priorizar qué issues técnicos afectan páginas con visibilidad real.

### SF + Google Analytics / GA4

Configuration > API Access > Google Analytics.

Añade sesiones/usuarios a cada URL. Priorizar correcciones en URLs con tráfico real.

### SF + PageSpeed Insights

Configuration > API Access > PageSpeed Insights.

Ejecuta PSI para cada URL crawleada. Lento para sitios grandes — usar solo en crawl selectivo de URLs prioritarias.

---

## Exportación y trabajo con datos

### Export útiles para informes

- **Bulk Export > Internal > HTML** → todas las URLs HTML con sus datos on-page
- **Bulk Export > Response Codes > 4xx** → URLs rotas
- **Bulk Export > Redirects > All Redirects** → mapa completo de redirects
- **Bulk Export > Images > Missing Alt Text**
- **Reports > Crawl Overview** → resumen ejecutivo del crawl

### Filtros en columnas

SF permite filtrar cualquier columna. Para encontrar patterns:
- Title contains "sin título" o "sample page" → restos de instalación WordPress
- URL contains "?page_id=" → permalinks no configurados en WordPress
- URL contains "PHPSESSID" → sesión en URL (PrestaShop bug conocido)

---

## Falsos positivos frecuentes en clientes

| Issue reportado por SF | Por qué puede ser falso | Cómo validar |
|---|---|---|
| H1 missing (Divi/Elementor) | H1 generado en JS | SF modo JS o WebFetch |
| Title duplicado en paginación | `/categoria/` y `/categoria/page/2/` | ¿Tienen canonical a página 1? |
| Meta description missing (PrestaShop) | Generada dinámicamente para categorías | WebFetch directo a la URL |
| Broken internal link | Link en popup o modal JS | Inspeccionar manualmente |
| Carácter Unicode oculto en title | Carácter invisible (U+200B, NBSP) en el title | Exportar CSV y abrir con editor hex; reescribir el campo desde cero |
| H1 tardío en documento | H1 precedido por H2/H3 de widgets — SF solo verifica presencia, no posición | Console DevTools: querySelectorAll h1-h6 para ver orden real |
| Slow page (SF mide TTFB sin caché CDN) | Primera petición siempre más lenta | PSI real o CrUX |
| Images missing alt (Divi background) | CSS background-image no es `<img>` | No es un issue real de alt text |

---


## Patrones que requieren validación manual

### Carácter Unicode oculto en title tag

**Síntoma en SF:** El title aparece correcto en la columna "Title" pero tiene
longitud anormal, o Google muestra un snippet diferente al title configurado.

**Causa:** Carácter invisible como `U+200B` (zero-width space), `U+00A0` (non-breaking space)
o `U+FEFF` (BOM) insertado al copiar/pegar desde Word, Google Docs o un editor rico del CMS.

**Detección en SF:**
- Custom Extraction > XPath: `//title/text()` → exportar y abrir CSV con editor hex
- O comparar la longitud en caracteres reportada por SF con la longitud visual

**Impacto:** Google puede truncar el title en el carácter invisible, mostrar snippet
alternativo o ignorar el title. Afecta también a herramientas de rank tracking
que comparan titles exactos.

**Fix:** Eliminar el campo de title en el CMS y reescribirlo desde cero sin copiar/pegar.

---

### H1 tardío en el documento HTML (posición >50%)

**Síntoma en SF:** H1 presente y correcto, pero precedido por múltiples H2, H3 o H4.

**Causa:** Page builders colocan widgets de contenido (features, sliders, secciones de intro)
antes del módulo de título principal. Esos widgets usan encabezados H2/H3 antes del H1 real.

**Por qué SF no lo detecta como issue:** SF verifica presencia del H1, no su posición
en el documento ni la jerarquía relativa al resto de encabezados.

**Impacto:** Google puede interpretar los encabezados anteriores al H1 como indicadores
del tópico principal. La jerarquía semántica queda invertida.

**Verificación:**
```javascript
// Chrome DevTools > Console
document.querySelectorAll('h1,h2,h3,h4,h5,h6').forEach((h, i) =>
  console.log(i, h.tagName, h.textContent.trim().slice(0,50))
);
```

**Fix:** Reordenar módulos del page builder para que el H1 aparezca en la primera
sección visible, o cambiar las etiquetas de los widgets anteriores a `<div>` con clases CSS.

---

## Custom extraction with XPath

Screaming Frog's Custom Extraction feature allows extracting specific elements
from the HTML of each crawled page using XPath or CSS selectors. Useful for
bulk-extracting data that SF does not report natively.

### Activating Custom Extraction

Configuration > Custom > Extraction > Add

Set a name, select XPath or CSS selector, and choose what to extract:
- **Extract inner text:** the visible text content of the element
- **Extract HTML:** the full HTML of the element
- **Extract attribute:** a specific attribute value (href, content, src)

### Useful XPath patterns for SEO

**Schema JSON-LD — extract all schema types on a page:**
```xpath
//script[@type="application/ld+json"]
```
Extract: HTML — gives you the full JSON-LD content.
Use: check what schema types are present on each URL. Export and review
for missing Product schema, incorrect datePublished, etc.

**Canonical URL:**
```xpath
//link[@rel="canonical"]/@href
```
Extract: attribute (href). Gives canonical URL for every page in the crawl.
Use: build a canonical map, detect mismatches between URL and canonical.

**robots meta content:**
```xpath
//meta[@name="robots"]/@content
```
Extract: attribute (content). Shows the exact robots directive on each page.
Use: bulk-identify pages with noindex, nofollow, or other directives.

**OG image URL:**
```xpath
//meta[@property="og:image"]/@content
```
Use: verify OG image is present and consistent across pages.

**First H2 on the page:**
```xpath
(//h2)[1]
```
Extract: inner text. Useful for auditing heading structure in bulk.

**Article published date:**
```xpath
//meta[@property="article:published_time"]/@content
```
Use: bulk-export publishing dates, cross-reference with lastmod in sitemap.

**Price on product pages (WooCommerce):**
```xpath
//p[@class="price"]//bdi
```
Use: verify product prices are rendering correctly in Spider mode.

**Word count approximation (body text only):**
```xpath
//article | //main | //*[@class="entry-content"]
```
Extract: inner text. Export character count as a proxy for content length.

### Combining Custom Extraction with filters

After crawling, go to the Custom Extraction tab and apply column filters:
- Filter XPath result is empty → pages missing the element
- Filter XPath result contains a specific string → pages with a particular value

**Example workflow — find pages missing schema:**
1. Add XPath: `//script[@type="application/ld+json"]` > Extract HTML
2. Crawl site
3. Custom Extraction tab > filter "Schema JSON-LD" is empty
4. Export: these URLs have no schema markup at all

---

## Configuración para re-crawl de verificación

Después de implementar correcciones técnicas, crawl selectivo para confirmar:

1. Mode > List → pegar URLs corregidas
2. Rendering: mismo modo que el crawl original
3. Verificar solo las columnas relevantes al fix
4. Comparar con export anterior del crawl inicial

---

## Límites y performance

| Tamaño sitio | Modo recomendado | Tiempo estimado |
|---|---|---|
| < 500 URLs | JS Rendering completo | 15-30 min |
| 500-5.000 URLs | JS Rendering + exclusiones | 1-3 horas |
| > 5.000 URLs | Spider mode completo + JS en selectivo | 3-8 horas |
| > 50.000 URLs | Spider mode, crawl por sección | Múltiples sesiones |

RAM recomendada: mínimo 8GB libre para JS rendering en sitios medianos. En Windows, cerrar otras aplicaciones pesadas antes del crawl.
