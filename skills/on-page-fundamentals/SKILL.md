---
name: on-page-fundamentals
description: >
  Title tags, meta descriptions y H1: reglas de optimización, longitudes, duplicados,
  ausencias, canibalización, casos por tipo de página (homepage, categoría, producto,
  artículo, local), bugs por CMS (Yoast, Rank Math, WooCommerce, PrestaShop),
  impacto en CTR y detección con Screaming Frog y GSC. Usar en cualquier auditoría
  de contenido o al optimizar páginas para CTR o posicionamiento.
user-invokable: false
---

# On-Page Fundamentals — Title, Meta Description, H1

---

## Title tag

### Qué hace

El title tag es el texto del enlace azul en SERP. Es el factor on-page de mayor
peso directo en el ranking para la keyword objetivo. Google puede reescribir el title
mostrado en SERP si considera que el declarado no representa bien el contenido de la página.

### Longitud

Google no tiene límite de caracteres — trunca visualmente en ~600px de ancho.
En desktop, esto equivale aproximadamente a 55-60 caracteres. En mobile, algo menos.

**Recomendación práctica:**
- Objetivo: 50-60 caracteres
- Máximo antes de truncación garantizada: 60 caracteres
- Herramienta de verificación: Portent SERP Preview, Screaming Frog

**Title demasiado corto (<30 caracteres):** señal de que la keyword y el contexto
no están suficientemente representados. Oportunidad de añadir modificadores.

**Title demasiado largo (>70 caracteres):** truncado en SERP. El texto que queda
fuera del truncado no aporta al CTR pero sí al ranking semántico.

### Estructura recomendada por tipo de página

| Tipo de página | Estructura | Ejemplo |
|---------------|------------|---------|
| Homepage | Marca + propuesta de valor + keyword principal | Clínica Ejemplo — Fisioterapia en Madrid |
| Categoría | Keyword + modificador + marca | Sillas ergonómicas — Tienda Ejemplo |
| Producto | Nombre producto + atributo diferenciador + marca | Silla Ergonómica X200 con reposabrazos — Tienda Ejemplo |
| Artículo blog | Keyword en primeras palabras + beneficio/contexto | Cómo elegir silla ergonómica: guía completa 2025 |
| Página local | Servicio + ciudad + marca | Fisioterapia en Salamanca — Clínica Ejemplo |
| Página de servicio | Servicio + diferenciador + ciudad/marca | Fisioterapia deportiva en Madrid — Clínica Ejemplo |

### Errores frecuentes

**Title duplicado:** múltiples páginas con el mismo title.
- Causa: CMS usando el mismo template sin campo de title personalizado
- Impacto: canibalización de señal, Google confunde qué página mostrar
- Detección: Screaming Frog > Page Titles > Duplicate

**Title ausente:** la página devuelve title vacío o solo `<title></title>`.
- Causa: template defectuoso, plugin SEO no aplicado a ese tipo de contenido
- Impacto: Google genera un title propio — habitualmente el H1 o el nombre del sitio
- Detección: Screaming Frog > Page Titles > Missing

**Title = nombre del sitio solamente:** `Tienda Ejemplo` sin keyword.
- Causa: homepage sin title personalizado, configuración por defecto del plugin
- Fix: personalizar en Yoast / Rank Math / PrestaShop backoffice

**Title reescrito por Google:** Google decide mostrar en SERP un texto diferente al declarado.
- Causa: el title declarado no coincide con el contenido real de la página, es demasiado
  largo, es genérico, o contiene keyword stuffing
- No controlable directamente — mejorar alineación entre title y contenido

**Keyword stuffing en title:** `Fisioterapia Madrid | Fisioterapeuta Madrid | Clínica Fisioterapia Madrid`
- Google puede penalizar o reescribir automáticamente
- Fix: un solo uso de la keyword principal, en primeras palabras

### WordPress — implementación

**Yoast:** Post/página editor > Yoast SEO > SEO title
Template disponible: `%%title%% %%sep%% %%sitename%%`

**Rank Math:** Post editor > Rank Math > Title (Edit Snippet)
Variables: `%title% %sep% %sitename%`

**Configuración de separador:**
- Yoast: SEO > Search Appearance > General > Title separator → `|`, `-`, `·`, `«»`
- Rank Math: General Settings > Titles & Meta > Separator

**Issue — WooCommerce productos sin title personalizado:**
Si el title de producto se genera solo desde el nombre del producto, todos los productos
de la tienda usan `Nombre Producto - Nombre Tienda` sin keyword de compra.
Añadir template en Yoast: SEO > Search Appearance > WooCommerce > Product title:
`%%wc_shortdesc%% %%sep%% %%sitename%%` o personalizar manualmente para productos clave.

### PrestaShop — implementación

Backoffice > Catálogo > Productos > SEO > Meta title (campo directo por producto/categoría)

**Template global:** Parámetros de la tienda > SEO & URLs > Meta title — afecta a páginas sin
title individual definido.

**Issue — título de categoría = nombre de categoría:**
PrestaShop usa el nombre de la categoría como title por defecto. Para categorías competitivas,
editar el campo Meta title individualmente.

---

## Meta description

### Qué hace

La meta description no afecta directamente al ranking. Sí afecta al CTR desde SERP:
una meta description bien redactada aumenta el porcentaje de clics.

Google puede ignorar la meta description declarada y extraer un fragmento del contenido
de la página que considera más relevante para la query del usuario. Esto ocurre con
más frecuencia en páginas con contenido rico y variedad de queries.

### Longitud

Aproximadamente 155-160 caracteres para desktop. Google trunca con `...` al superar
el límite visual (~920px en desktop).

**Recomendación práctica:**
- Objetivo: 140-155 caracteres
- Incluir la keyword principal de forma natural (Google la muestra en negrita si coincide con la query)
- Terminar con un CTA implícito o diferenciador claro

### Estructura recomendada

| Tipo de página | Contenido de la meta description |
|---------------|----------------------------------|
| Homepage | Qué ofrece el negocio + diferenciador + localización si es local |
| Categoría | Qué incluye la categoría + número de productos/posts si es relevante + CTA |
| Producto | Beneficio principal + atributo diferenciador + CTA de compra |
| Artículo blog | De qué trata el artículo + qué aprende el lector |
| Página local | Servicio + ciudad + disponibilidad / contacto |

### Errores frecuentes

**Meta description duplicada:**
- Causa: template global sin personalización por página
- Impacto: bajo CTR — Google genera un snippet propio (habitualmente mejor que una genérica)
- Detección: Screaming Frog > Meta Description > Duplicate

**Meta description ausente:**
- Consecuencia esperada: Google extrae un fragmento de la página. No siempre es malo —
  si el contenido es rico, Google puede elegir bien. En páginas de conversión (producto,
  servicio), la ausencia sí es un problema porque Google puede mostrar un fragmento
  irrelevante para la intent del usuario
- Detección: Screaming Frog > Meta Description > Missing

**Meta description demasiado larga (>160 caracteres):**
- Truncada en SERP. El texto que queda fuera no genera impacto en CTR
- Fix: condensar el mensaje clave en los primeros 155 caracteres

**Meta description como campo de keyword stuffing:**
`Fisioterapia Madrid. Fisioterapeuta en Madrid. Clínica de fisioterapia Madrid.`
- Google ignora esta meta description y genera su propio fragmento
- Fix: texto natural orientado al usuario, no a los bots

---

## H1

### Qué hace

El H1 es el título principal visible de la página. Señala a Google el tema central
del contenido. No debe confundirse con el title tag — el H1 es visible en la página;
el title tag aparece en la pestaña del navegador y en SERP.

**Relación H1 — title tag:** no deben ser idénticos pero sí coherentes. El title tag
incluye la marca; el H1 normalmente no. El H1 puede ser más largo y conversacional;
el title tag es más corto y orientado al click.

### Reglas

1. **Una sola etiqueta H1 por página.** Múltiples H1 no penalizan directamente pero
   diluyen la señal de tema principal.
2. **Incluir la keyword principal**, idealmente en las primeras palabras.
3. **No usar H1 como decoración:** si el theme usa H1 para el nombre del sitio en el
   header de todas las páginas, cada página tiene efectivamente dos H1 — el del header
   y el del contenido.
4. **H1 ≠ H2:** no saltar niveles. La estructura de headings debe ser jerárquica:
   H1 > H2 > H3.

### Errores frecuentes

**H1 ausente:**
- Causa: template del theme que no genera H1, o el contenido usa H2 directamente
- Detección: Screaming Frog > H1 > Missing

**Múltiples H1:**
- Causa: theme con H1 en header + H1 en el contenido, o page builder añadiendo H1
  en varios bloques
- Detección: Screaming Frog > H1 > Multiple H1s
- Fix en WordPress: cambiar el heading del header del theme a un elemento no semántico
  (`<div>`, `<p>`) o a H2

**H1 = título de categoría genérico:**
`/categoria-productos/` con H1 "Productos" sin keyword.
El H1 debe contener la keyword de la categoría, no solo el nombre interno.

**H1 duplicado entre páginas:**
Ocurre en e-commerce cuando varios productos de la misma familia usan el mismo H1.
- Detección: Screaming Frog > H1 > Duplicate

### WordPress — issues con page builders

**Elementor:**
Elementor puede generar H1 en el Heading widget mientras el post title también genera
un H1 desde el template del theme. Resultado: dos H1.

Verificar en Elementor: si el template usa `{{Post Title}}` en un Heading widget
configurado como H1, y el theme también muestra el post title como H1 fuera del
Elementor canvas, hay duplicación.

Fix: convertir uno de los dos a H2 o configurar el template para no mostrar el post
title del theme cuando Elementor toma el control del template.

**Divi:**
Similar — el módulo de título de la página de Divi y el heading del theme pueden generar
dos H1. Verificar con View Source en páginas que usan Divi Builder.

---

## Canibalización de keywords entre title/H1

Cuando dos páginas del mismo sitio tienen el mismo title tag o compiten por la misma
keyword principal en el H1, pueden canibalizarse en SERP — Google elige una de las
dos de forma inconsistente, y ninguna obtiene el posicionamiento esperado.

**Señal en GSC:** la keyword aparece con rankings fluctuantes entre dos URLs distintas
en el mismo período. Ver en GSC > Performance > Queries > hacer click en la query >
ver URLs que aparecen para esa query.

**Detección con Screaming Frog:**
Export de todos los H1 y title tags → ordenar por valor → identificar duplicados
entre páginas distintas.

**Fix:**
- Si ambas páginas tienen contenido valioso: diferenciar el enfoque de cada una —
  una para el término genérico, otra para la variante long-tail o con modificador
- Si una página es claramente inferior: 301 redirect + consolidar contenido en la página fuerte
- Canonical de la débil a la fuerte solo si el contenido es esencialmente duplicado

---

## Análisis con Screaming Frog

Columnas y filtros clave:

| Sección | Filtro | Qué detecta |
|---------|--------|-------------|
| Page Titles | Missing | Páginas sin title tag |
| Page Titles | Duplicate | Títulos repetidos entre páginas |
| Page Titles | Over X Characters | Titles largos (configurar a 60) |
| Page Titles | Below X Characters | Titles cortos (configurar a 30) |
| Meta Description | Missing | Sin meta description |
| Meta Description | Duplicate | Meta descriptions repetidas |
| Meta Description | Over X Characters | Demasiado largas (configurar a 160) |
| H1 | Missing | Páginas sin H1 |
| H1 | Multiple H1s | Páginas con más de un H1 |
| H1 | Duplicate | H1 repetido entre páginas |

**Workflow de auditoría:**
1. Exportar todos los issues a CSV
2. Priorizar por tráfico: cruzar con GSC para identificar qué páginas tienen impresiones
   pero bajo CTR (posibles mejoras de title/meta description)
3. Separar issues técnicos (ausentes, duplicados) de optimizaciones (keywords, longitud)

### GSC — CTR bajo como señal de title/meta subóptimo

Performance > Filtrar por páginas con >100 impresiones y CTR <2% (desktop, non-brand):
Son candidatas a mejora de title tag o meta description.

No confundir CTR bajo con posición baja: una página en posición 8-10 puede tener
CTR bajo simplemente por la posición, no por el title. Filtrar por posición 1-5 +
CTR bajo para identificar casos donde el title es el problema.

---

## Checklist de auditoría on-page

```
CRÍTICO
[ ] ¿Páginas sin title tag? (Screaming Frog > Page Titles > Missing)
[ ] ¿Páginas sin H1? (Screaming Frog > H1 > Missing)
[ ] ¿Title tags duplicados en páginas con tráfico? (Page Titles > Duplicate)
[ ] ¿H1 duplicados entre páginas que compiten por la misma keyword?

ALTO
[ ] ¿Title tags >70 caracteres? (truncados en SERP)
[ ] ¿Meta descriptions ausentes en páginas de conversión (producto, servicio, categoría)?
[ ] ¿Meta descriptions duplicadas en secciones importantes?
[ ] ¿Múltiples H1 por página? (Page Builders, themes con H1 en header)
[ ] ¿H1 del header del theme aplicándose en todas las páginas?

MEDIO
[ ] ¿Keyword principal en las primeras palabras del title?
[ ] ¿Meta descriptions >160 caracteres? (truncadas)
[ ] ¿Meta descriptions <70 caracteres? (infrautilizadas)
[ ] ¿H1 coherente con el title tag (misma keyword, diferentes formulaciones)?
[ ] ¿WooCommerce/PrestaShop: productos con title = solo nombre de producto sin keyword?
[ ] ¿GSC: páginas con >100 impresiones y CTR <2% en posición 1-5? → title candidato a mejora

BAJO
[ ] ¿Separador del title configurado correctamente en el plugin SEO?
[ ] ¿Estructura jerárquica de headings (H1 > H2 > H3) sin saltos?
[ ] ¿Title tag contiene el nombre de la marca? (recomendado para brand queries)
```

---

## Referencias

- Cómo Google usa los titles: https://developers.google.com/search/docs/appearance/title-link
- Meta description: https://developers.google.com/search/docs/appearance/snippet
- Headings y estructura: https://developers.google.com/search/docs/fundamentals/seo-starter-guide
