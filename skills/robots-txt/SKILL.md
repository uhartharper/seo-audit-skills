---
name: robots-txt
description: >
  robots.txt y control de indexabilidad: especificación oficial de Google, plantillas
  por tipo de sitio (informativo, e-commerce, WordPress, WooCommerce), requerimientos
  de Google Merchant Center, meta robots (noindex/nofollow/noarchive), X-Robots-Tag
  HTTP header, conflict resolution Disallow vs noindex, e interpretación del informe
  de cobertura en GSC.
---

# robots.txt — Guía Técnica SEO

> Basado en la especificación RFC 9309 y la implementación oficial de Google.
> Fuentes: developers.google.com/crawling/docs/robots-txt | support.google.com/merchants

---

## Especificación técnica — Cómo interpreta Google robots.txt

### Directivas soportadas por Google

| Directiva | Obligatoria | Descripción |
|-----------|-------------|-------------|
| `User-agent:` | Sí (≥1 por grupo) | Nombre del bot. Case-insensitive. `*` = todos excepto AdsBot variants |
| `Disallow:` | Sí (≥1 por grupo) | Ruta bloqueada. Vacío = allow all |
| `Allow:` | No | Ruta permitida dentro de un bloque bloqueado |
| `Sitemap:` | No | URL absoluta del sitemap. Múltiples permitidos |
| `Crawl-delay:` | No | No procesado por Googlebot (ignorado). Sí por otros bots |

**Directivas ignoradas por Google:** `Crawl-delay`, `Noindex` (en robots.txt — usar meta robots en página).

### Precedencia de reglas (crítico)

- Cuando hay conflicto entre `Allow` y `Disallow`, **gana la regla más larga** (más específica).
- Empate en longitud → gana `Allow`.
- Ejemplo: `Disallow: /page` (6 chars) vs `Allow: /page/featured` (21 chars) → `Allow` gana para `/page/featured`.

### Matching de User-agent

- **Bot con regla específica**: usa solo su grupo. No hereda del grupo `*`.
- **Bot sin regla específica**: usa el grupo `*`.
- **Múltiples grupos para el mismo bot**: se combinan internamente en uno.
- El orden de los grupos en el archivo es irrelevante para la lógica.
- Non-matching text se ignora: `googlebot/1.2` y `googlebot*` = `googlebot`.

### Wildcards

- `*` — cero o más caracteres válidos. Trailing wildcards ignorados.
- `$` — fin de URL. `/*.php$` coincide con `/file.php` pero NO con `/file.php?param`.
- Son soportados por Google en ambas directivas `Allow` y `Disallow`.

### Casos edge importantes

- `Disallow:` (vacío) = permite todo. Equivale a no tener robots.txt.
- `Disallow: /` = bloquea todo el sitio (URLs pueden seguir indexándose sin snippet).
- El archivo robots.txt es público — nunca usarlo para ocultar información sensible.
- AdsBot (`AdsBot-Google`, `AdsBot-Google-Mobile`) **no** está cubierto por `User-agent: *`. Debe nombrarse explícitamente si se quiere bloquear.
- Una directiva `Sitemap:` no interrumpe un grupo de user-agent — parsers la ignoran al construir grupos.

---

## Google Merchant Center — Requerimientos críticos

### Por qué es diferente a un sitio informativo

Merchant Center usa Googlebot para validar landing pages de productos y
Googlebot-image para validar imágenes de productos. Si cualquiera de los dos
está bloqueado por robots.txt, los productos pueden ser **desaprobados**.

### Errores de Merchant Center relacionados con robots.txt

| Error en MC | Causa en robots.txt | Consecuencia |
|-------------|---------------------|--------------|
| "Robots.txt error" | Googlebot bloqueado global o en URLs de producto | Productos desaprobados |
| "Desktop page not crawlable due to robots.txt" | Googlebot bloqueado en landing pages | Productos desaprobados |
| "Mobile page not crawlable due to robots.txt" | Googlebot bloqueado en versión mobile | Productos desaprobados |
| "Can't access product images" | Googlebot-image bloqueado | Productos sin imagen → próxima desaprobación |
| "Unable to do quality & policy checks on product pages" | Googlebot bloqueado en páginas de producto | Validación de calidad fallida |

### Solución oficial de Google para Merchant Center

```
User-agent: Googlebot
Disallow:

User-agent: Googlebot-image
Disallow:
```

Estas dos reglas deben aparecer **antes** del bloque `User-agent: *` o como bloques
separados. Al ser reglas específicas, Googlebot y Googlebot-image no heredan
las restricciones del bloque `*`.

### Merchant Center es especialmente sensible a robots.txt

MC reporta errores de robots.txt con más frecuencia y agresividad que Google Search.
Una directiva que en Search no genera ningún problema visible puede causar
desaprobaciones masivas de productos en MC. Ante cualquier duda sobre si una
directiva podría afectar a Googlebot en un sitio con MC activo, **no añadirla**.
El riesgo de bloquear accidentalmente algo que MC necesita supera el beneficio
de cualquier optimización de crawl budget.

### Directivas del bloque `*` que causan problemas en Merchant Center

Estas directivas son habituales en robots.txt "estándar" pero afectan a MC
cuando Googlebot no tiene su propio bloque explícito:

| Directiva peligrosa | Por qué afecta a MC |
|--------------------|---------------------|
| `Disallow: /*?` | Bloquea todas las URLs con parámetros. Muchas URLs de producto o tracking de MC los usan |
| `Disallow: /*.php` | Bloquea admin-ajax.php, necesario para WooCommerce |
| `Disallow: /wp-content/uploads/` | Bloquea imágenes de productos en WordPress |
| `Disallow: /product/` | Bloquea landing pages de producto directamente |
| `Disallow: /tienda/` o `/shop/` | Mismo problema |

**Regla clave:** Si Googlebot tiene su propio bloque con `Disallow:` vacío, todas las
directivas del bloque `*` son irrelevantes para Googlebot. El bloque específico
toma precedencia completa.

---

## Plantillas por tipo de sitio

### Sitio informativo / blog (WordPress)

```
# Sitio informativo — WordPress
User-agent: *

# Admin
Disallow: /wp-admin/
Allow: /wp-admin/admin-ajax.php

# Contenido sin valor SEO
Disallow: /xmlrpc.php
Disallow: /trackback/
Disallow: /*/trackback/
Disallow: /?s=
Disallow: /search/
Disallow: /feed/
Disallow: /comments/feed/

# Paginación profunda (opcional — solo si crawl budget es problema)
# Disallow: /page/

# Archivos sensibles
Disallow: /*.inc$
Disallow: /*.sql$
Disallow: /*.log$

# IA — bots de entrenamiento (bloquear — sin beneficio de tráfico)
User-agent: GPTBot
Disallow: /

User-agent: Google-Extended
Disallow: /

User-agent: CCBot
Disallow: /

User-agent: anthropic-ai
Disallow: /

User-agent: ClaudeBot
Disallow: /

# Bots de búsqueda IA (PerplexityBot, ChatGPT-User, OAI-SearchBot, Claude-User):
# NO declarar bloque explícito. Caen en User-agent: * y respetan todas las restricciones.
# Declarar Allow: / en bloque propio les daría acceso total ignorando todas las reglas de *.

Sitemap: https://dominio.com/sitemap_index.xml
```

---

### E-commerce SIN Merchant Center (WooCommerce / PrestaShop)

```
# E-commerce sin Merchant Center
User-agent: *

# Admin
Disallow: /wp-admin/
Allow: /wp-admin/admin-ajax.php
Disallow: /xmlrpc.php

# Transaccional — sin valor SEO
Disallow: /cart/
Disallow: /checkout/
Disallow: /my-account/
Disallow: /*add-to-cart=*

# Búsqueda interna y paginación
Disallow: /?s=
Disallow: /search/
Disallow: /page/

# Parámetros (gestionar con canonical si hay faceted navigation)
# Disallow: /*?  ← SOLO si no hay URLs de producto con parámetros

# Feeds
Disallow: /feed/
Disallow: /comments/feed/

# Archivos sensibles
Disallow: /*.inc$
Disallow: /*.sql$
Disallow: /*.log$
Disallow: /*.git$

# IA — bots de entrenamiento
User-agent: GPTBot
Disallow: /

User-agent: Google-Extended
Disallow: /

User-agent: CCBot
Disallow: /

User-agent: anthropic-ai
Disallow: /

User-agent: ClaudeBot
Disallow: /

Sitemap: https://dominio.com/sitemap_index.xml
```

---

### E-commerce CON Merchant Center (WooCommerce / PrestaShop)

**Esta es la plantilla crítica. Googlebot y Googlebot-image deben tener acceso total.**

```
# -----------------------------------------------
# E-commerce con Google Merchant Center
# -----------------------------------------------

# 1. Acceso total para Merchant Center (CRÍTICO — no modificar)
User-agent: Googlebot
Disallow:

User-agent: Googlebot-image
Disallow:

# 2. Reglas generales para el resto de bots
User-agent: *

# Admin
Disallow: /wp-admin/
Allow: /wp-admin/admin-ajax.php
Disallow: /xmlrpc.php

# Transaccional
Disallow: /cart/
Disallow: /checkout/
Disallow: /my-account/
Disallow: /*add-to-cart=*

# Búsqueda interna
Disallow: /?s=
Disallow: /search/

# Feeds
Disallow: /feed/
Disallow: /comments/feed/
Disallow: /*/feed/
Disallow: /*/feed/rss/

# Trackback
Disallow: /trackback/
Disallow: /*/trackback/

# Paginación (crawl budget)
Disallow: /page/

# Archivos sensibles
Disallow: /*.inc$
Disallow: /*.sql$
Disallow: /*.log$
Disallow: /*.git$

# IA — bots de entrenamiento (sin beneficio de tráfico)
User-agent: GPTBot
Disallow: /

User-agent: Google-Extended
Disallow: /

User-agent: CCBot
Disallow: /

User-agent: anthropic-ai
Disallow: /

User-agent: ClaudeBot
Disallow: /

User-agent: Bytespider
Disallow: /

User-agent: cohere-ai
Disallow: /

User-agent: MetaAI
Disallow: /

Sitemap: https://dominio.com/sitemap_index.xml
```

**Qué NO incluir en la plantilla con Merchant Center:**
- `Disallow: /*?` — bloquea parámetros, puede afectar URLs de producto
- `Disallow: /*.php` — bloquea admin-ajax.php
- `Disallow: /wp-content/uploads/` — bloquea imágenes de productos
- `Disallow: /product/` o `/tienda/` o `/shop/` — bloquea landing pages

---

## Governance de bots de IA (2026)

### Bots de entrenamiento — bloquear (sin beneficio de tráfico)

| User-agent | Empresa | Uso |
|------------|---------|-----|
| `GPTBot` | OpenAI | Entrenamiento de modelos |
| `Google-Extended` | Google | Entrenamiento de Gemini / Bard |
| `CCBot` | Common Crawl | Dataset público de entrenamiento |
| `anthropic-ai` | Anthropic | Entrenamiento (crawler masivo) |
| `ClaudeBot` | Anthropic | Entrenamiento (alias anterior) |
| `Bytespider` | ByteDance / TikTok | Entrenamiento |
| `cohere-ai` | Cohere | Entrenamiento |
| `MetaAI` | Meta | Entrenamiento |

### Bots de búsqueda IA — NO declarar bloque explícito

| User-agent | Empresa | Uso |
|------------|---------|-----|
| `PerplexityBot` | Perplexity | Indexación para respuestas de búsqueda |
| `ChatGPT-User` | OpenAI | Petición directa de usuario en ChatGPT |
| `OAI-SearchBot` | OpenAI | SearchGPT / ChatGPT Search |
| `Claude-User` | Anthropic | Petición directa de usuario en Claude |

**Regla crítica:** NO declarar estos bots con `Allow: /` en bloque propio. Un bot con bloque
explícito solo lee ese bloque e ignora completamente `User-agent: *`. Declarar `Allow: /`
les daría acceso total a `/wp-admin/`, `/carrito/`, archivos sensibles, etc.
La forma correcta es no declararlos — caen en `User-agent: *` y respetan todas las restricciones.

**Nota:** `GPTBot` (entrenamiento) y `ChatGPT-User` (búsqueda) son bots distintos.
Bloquear `GPTBot` no afecta a las respuestas de ChatGPT a usuarios.

---

## Regla arquitectural: cuándo usar bloque explícito vs User-agent: *

**Un bloque explícito con `Disallow:` vacío da acceso total pero elimina por completo
la protección del bloque `User-agent: *`.** Solo usar cuando el bot necesite
acceso total con razón técnica justificada.

| Bot | Bloque explícito | Motivo |
|-----|-----------------|--------|
| `Googlebot` | Sí — `Disallow:` vacío | Requerimiento oficial de Merchant Center |
| `Googlebot-image` | Sí — `Disallow:` vacío | Requerimiento oficial de Merchant Center (imágenes) |
| `AdsBot-Google` | Sí — `Disallow:` vacío | Validación de landing pages en Google Ads. No cubierto por `*` |
| `Storebot-Google` | Sí — `Disallow:` vacío | Necesita acceder a carrito y checkout para validar precios y envíos |
| `Bingbot` | NO — cae en `*` | No tiene requisito técnico especial. `*` protege el crawl budget |
| `DuckDuckBot` | NO — cae en `*` | Ídem |
| `YandexBot` | NO — cae en `*` | Ídem |
| `Baiduspider` | NO — cae en `*` | Ídem |
| `Applebot` | NO — cae en `*` | Ídem |
| Bots IA de búsqueda | NO — caen en `*` | Ídem |
| Bots IA de entrenamiento | Sí — `Disallow: /` | Bloqueo total explícito necesario, no cubiertos de forma útil por `*` |

**Consecuencia de dar bloque explícito innecesariamente:** el bot puede rastrear
`/carrito/`, `/finalizar-compra/`, `/search/`, archivos sensibles, bucles de
`/*add-to-cart=*` — saturando el servidor y desperdiciando crawl budget.

---

## Errores comunes a detectar en auditoría

### Error 1: `Disallow: /*?` sin bloque explícito de Googlebot
**Síntoma:** Merchant Center reporta "page not crawlable due to robots.txt".
**Causa:** `/*?` bloquea URLs con parámetros. Si Googlebot no tiene su propio bloque,
hereda esta regla.
**Fix:** Añadir bloque `User-agent: Googlebot` / `Disallow:` antes del bloque `*`.

### Error 2: `Disallow: /*.php` bloqueando admin-ajax.php
**Síntoma:** Comportamientos dinámicos de WooCommerce fallan o Merchant Center
no puede validar variaciones de producto.
**Fix:** Eliminar `Disallow: /*.php` o añadir `Allow: /wp-admin/admin-ajax.php`
antes de esa directiva (la regla más larga gana).

### Error 3: Sitemap apuntando a dominio incorrecto
**Síntoma:** `Sitemap: https://otro-dominio.com/sitemap_index.xml`
**Causa:** Copiar/pegar de plantilla o de otro cliente sin actualizar la URL.
**Fix:** Verificar siempre que el dominio en `Sitemap:` coincide con el sitio.

### Error 4: `Disallow: /page/` bloqueando paginación de productos
**Síntoma:** Páginas de categoría paginadas (`/categoria/page/2/`) no indexadas.
**Causa:** `Disallow: /page/` bloquea `/categoria/page/N/`.
**Fix:** Si Googlebot tiene su propio bloque con `Disallow:` vacío, no aplica.
Si no, evaluar si la paginación tiene valor de indexación para el sitio.

### Error 5: Wildcard `$` en Allow para JS/CSS
**Síntoma:** `Allow: /*.js$` no funciona como se espera en parsers no-Google.
**Nota:** Google sí soporta `$` como fin de URL. Pero en un bloque donde
Googlebot tiene acceso total de todas formas, estas reglas son redundantes.

### Error 6: AdsBot no bloqueado explícitamente
**Síntoma:** AdsBot sigue rastreando aunque `User-agent: *` tenga restricciones.
**Causa:** AdsBot no está cubierto por el wildcard `*`.
**Fix:** Si se quiere bloquear AdsBot: `User-agent: AdsBot-Google` / `Disallow: /`.

### Error 7: `*/trackback/` con wildcard al inicio — sintaxis no estándar
**Síntoma:** `Disallow: */trackback/` — algunos parsers no lo procesan correctamente.
**Fix:** Usar `Disallow: /*/trackback/` (forma estándar con `/` inicial obligatorio).

---

## Validación obligatoria contra el sitio real

Toda propuesta de robots.txt debe verificarse contra el sitio real antes de publicar.
Las plantillas usan slugs por defecto que pueden no coincidir con la configuración real del CMS.

**Páginas a verificar en línea antes de publicar:**

| Página | WordPress/WooCommerce | PrestaShop | Shopify |
|--------|----------------------|------------|---------|
| Carrito | `/cart/` o localizado (`/carrito/`) | `/commande/` o localizado | `/cart` |
| Checkout | `/checkout/` o localizado (`/finalizar-compra/`) | `/commande/` o localizado | `/checkouts/` |
| Mi cuenta | `/my-account/` o localizado (`/mi-cuenta/`) | `/mon-compte/` o localizado | `/account` |
| Admin | `/wp-admin/` | `/admin/` o `/adminXXXXX/` | No accesible (SaaS) |
| Búsqueda | `/?s=` | `/?search_query=` | `/search` |
| Feed | `/feed/` (solo WordPress) | No aplica | No aplica |
| admin-ajax | `/wp-admin/admin-ajax.php` | No existe | No aplica |

**Procedimiento:** hacer WebFetch de cada URL transaccional del sitio real y confirmar
que devuelve HTTP 200. Si devuelve 404, el slug real es otro — buscarlo antes de incluirlo.
Si tanto el slug en inglés como el localizado devuelven 200, incluir ambos.

---

## Checklist de evaluación de robots.txt

```
CRÍTICO (impacto directo en indexación o Merchant Center)
[ ] ¿El dominio en Sitemap: coincide con el sitio actual?
[ ] Si tiene Merchant Center: ¿Googlebot tiene bloque explícito con Disallow: vacío?
[ ] Si tiene Merchant Center: ¿Googlebot-image tiene bloque explícito con Disallow: vacío?
[ ] ¿Hay Disallow: /*? sin bloque explícito de Googlebot? (bloquea parámetros)
[ ] ¿Hay Disallow: /*.php? (puede bloquear admin-ajax.php)
[ ] ¿Hay Disallow: /wp-content/uploads/? (bloquea imágenes de producto)
[ ] ¿Hay Disallow: /product/ o equivalente sin bloque explícito de Googlebot?

ALTO (impacto en crawl budget o indexación de contenido valioso)
[ ] ¿Está bloqueado /cart/, /checkout/, /my-account/?
[ ] ¿Está bloqueada la búsqueda interna (/?s= o /search/)?
[ ] ¿El bloqueo de /page/ afecta a paginación de categorías con valor SEO?
[ ] ¿El bloqueo de /feed/ interfiere con feeds de producto usados en MC?
[ ] ¿Hay Disallow: / (bloqueo total)? ¿Es intencional?

MEDIO (buenas prácticas y governance)
[ ] ¿Hay política definida para bots de entrenamiento de IA?
[ ] ¿Se diferencian bots de entrenamiento vs bots de búsqueda IA?
[ ] ¿AdsBot está gestionado explícitamente si hay campañas de Google Ads?
[ ] ¿La sintaxis es estándar? (paths empiezan por /, no hay wildcards al inicio)
[ ] ¿Hay directivas Crawl-delay para bots agresivos (msnbot, Slurp)?

BAJO (limpieza y mantenimiento)
[ ] ¿Hay reglas redundantes (ej: */trackback/ y /*/trackback/ a la vez)?
[ ] ¿Hay comentarios que expliquen secciones no obvias?
[ ] ¿El archivo es UTF-8 plain text?
[ ] ¿Está en la raíz del dominio?
```

---

## Disallow vs meta robots — Conflict resolution

A common confusion: what happens when robots.txt says `Disallow` for a URL
but the page itself has `<meta name="robots" content="index">`?

### Rule: robots.txt blocks crawling; meta robots controls indexing

They operate at different levels:

| Directive | Controls | Evaluated by |
|-----------|----------|-------------|
| robots.txt `Disallow` | Whether Googlebot crawls the URL | Googlebot before requesting the URL |
| `<meta name="robots" content="noindex">` | Whether Google indexes the URL | Google after crawling the page |
| `X-Robots-Tag: noindex` | Whether Google indexes the URL | Google after crawling the page |

### What wins — decision tree

```
Is the URL blocked by robots.txt Disallow?
  YES → Google cannot crawl it. Google cannot read the page's meta robots.
        The URL can still be indexed if Google discovers it from external links
        (it will be indexed without a snippet — "information unavailable").
  NO  → Google crawls it. Then reads meta robots:
        noindex in meta robots → Google removes it from the index.
        index in meta robots (or no meta robots) → Google can index it.
```

### The dangerous combination: Disallow + noindex

A URL with `Disallow` in robots.txt AND `<meta name="robots" content="noindex">`
creates a conflict:

- Googlebot cannot crawl the page → cannot read the noindex directive
- If the URL is linked externally, Google may index it without a snippet
- The noindex is never executed because Googlebot never sees it

**Fix:** Choose one approach:
- **To keep URL out of index but allow crawling:** Remove the Disallow, keep the noindex
- **To prevent crawling entirely:** Keep the Disallow, remove the noindex (redundant)
- **Most common correct approach:** `noindex` in meta robots, no Disallow

### Practical implications

**WordPress wp-admin:**
`Disallow: /wp-admin/` is correct. The admin area should not be crawled OR indexed.
The noindex on wp-admin pages is irrelevant because Disallow prevents crawl.

**Search results pages (`/?s=`):**
`Disallow: /?s=` prevents Googlebot from crawling search results (correct — duplicate content).
Alternative approach: allow crawling but add `<meta name="robots" content="noindex,follow">`.
Both work. Disallow is simpler and prevents server load from Googlebot.

**Checkout and transactional pages:**
Use `Disallow` for checkout/cart — no SEO value AND prevents accidental indexation
even if someone forgets to set noindex. Defense in depth.

**Pages you want indexed:**
Never use `Disallow` on pages you want in Google's index.
If the URL is Disallowed and external links point to it, Google will index the URL
as a title-less, snippet-less result — undesirable.

---

## WordPress — Cómo editar robots.txt

WordPress genera robots.txt **virtualmente** (sin archivo físico) desde la raíz.
Si existe un archivo físico `/robots.txt`, este tiene precedencia sobre el virtual.

**Opción A — Plugin SEO (Yoast, RankMath, SEOPress):**
- Yoast: SEO > Herramientas > Editor de archivos > robots.txt
- RankMath: General Settings > Edit robots.txt
- Edición visual directa desde el backoffice.

**Opción B — Archivo físico:**
Crear `robots.txt` en la raíz del servidor (`/public_html/robots.txt` o `/www/robots.txt`).
Tiene precedencia sobre el virtual de WordPress.

**Opción C — Hook PHP (para reglas dinámicas):**
```php
add_filter( 'robots_txt', function( $output, $public ) {
    $output .= "\nUser-agent: GPTBot\nDisallow: /\n";
    return $output;
}, 10, 2 );
```

**Verificación:** Acceder a `https://dominio.com/robots.txt` en ventana privada.
Validar con Search Console > Configuración > robots.txt.

---

## Indexability — meta robots y X-Robots-Tag

### Meta robots — directivas disponibles

```html
<!-- En el <head> de cada página -->
<meta name="robots" content="noindex, nofollow" />
```

| Directiva | Efecto |
|-----------|--------|
| `index` | Google puede indexar la página (default) |
| `noindex` | Google excluye la página del índice |
| `follow` | Google sigue los links de la página (default) |
| `nofollow` | Google no pasa PageRank a través de los links |
| `noarchive` | Google no muestra el enlace de caché en SERP |
| `nosnippet` | Google no muestra meta description ni fragmento en SERP |
| `noimageindex` | Google no indexa las imágenes de la página |
| `none` | Equivale a `noindex, nofollow` |
| `all` | Equivale a `index, follow` (default — no hace falta declararlo) |

**Nota:** Google acepta `<meta name="googlebot" content="...">` para reglas
específicas a Googlebot. Si un sitio tiene audiencia en Rusia o China, considerar
`<meta name="robots">` (para todos) vs bot-específico.

### X-Robots-Tag — HTTP header

Funcionalmente equivalente a meta robots pero se aplica a nivel HTTP.
Usar cuando no se puede modificar el HTML: PDFs, imágenes, archivos descargables.

```bash
# Verificar X-Robots-Tag con curl
curl -I https://dominio.com/documento.pdf | grep -i x-robots-tag
```

**Bug conocido — LiteSpeed + X-Robots-Tag noindex:**
LiteSpeed Cache puede generar `X-Robots-Tag: noindex` en páginas que deberían
indexarse, si la configuración de cache está mal alineada con las reglas de indexación.
Verificar sistemáticamente con curl en páginas importantes cuando se usa LiteSpeed.

### Cuándo usar noindex vs Disallow

Ver sección "Disallow vs meta robots — Conflict resolution" más arriba para el
árbol de decisión completo.

Resumen rápido:

- **Páginas que no deben indexarse pero pueden crawlearse** (GSC puede leer el noindex):
  `<meta name="robots" content="noindex">` — SIN Disallow
- **Páginas que no deben crawlearse ni indexarse** (area admin, archivos internos):
  `Disallow` en robots.txt — el noindex es redundante porque Googlebot no llega a leerlo
- **Nunca combinar** Disallow + noindex en la misma URL si el objetivo es controlar
  la indexación — el Disallow impide que Google vea el noindex

### GSC — Informe de cobertura: estados de indexabilidad

**Indexadas:**
- "Indexada, no enviada en el sitemap" — Google la descubrió y decidió indexarla sin que estuviera en sitemap. Puede ser útil (Google validó la URL) o un problema (URL no deseada indexada).

**Excluidas — causas comunes:**

| Estado GSC | Causa probable |
|------------|----------------|
| Excluida por etiqueta "noindex" | `<meta name="robots" content="noindex">` o `X-Robots-Tag: noindex` |
| Rastreada, sin indexar actualmente | Google rastreó la página pero decidió no indexarla (thin content, duplicate) |
| Descubierta, sin rastrear | Google sabe que existe pero no la ha crawleado aún (crawl budget) |
| Bloqueada por robots.txt | robots.txt Disallow — Google no puede rastrear la URL |
| Duplicada — el usuario seleccionó una canonical diferente | URL no canonical, Google sigue la canonical declarada |
| Duplicada — Google eligió una canonical diferente | Canonical declarado ignorado — Google prefiere otra URL |
| Redireccionada | URL redirige a otra — solo la URL destino se indexa |
| Página 404 | URL devuelve 404 — no indexable |
| Página de marcador de posición | Google detectó página vacía o en construcción |

**Issue crítico: "Excluida por etiqueta noindex" en URLs que deben indexarse:**
- Verificar si el plugin SEO está configurando noindex globalmente en alguna sección
- Yoast: SEO > Search Appearance > Content Types > Posts/Pages: Search appearance > desactivado por error
- Rank Math: Titles & Meta > Categories/Tags > robots index — verificar
- Verificar también WordPress Settings > Reading > "Discourage search engines" — si está activo, noindex global

### Detección de problemas de indexabilidad con Screaming Frog

Columnas clave en la pestaña Internal:

| Columna | Qué detecta |
|---------|-------------|
| Indexability | Indexable / Non-Indexable |
| Indexability Status | Razón específica del estado (noindex, canonical a otra URL, blocked by robots, etc.) |
| Meta Robots 1 | Directiva meta robots declarada |
| X-Robots-Tag | Header HTTP de indexación |

**Filtros útiles:**
- Indexability > Non-Indexable → listar todas las URLs no indexables
- Indexability Status > Noindex → filtrar solo las que tienen noindex declarado
- Indexability Status > Blocked by robots.txt → filtrar bloqueadas por robots.txt

**Caso importante:** páginas en sitemap + non-indexable = issue alto.
Screaming Frog > Sitemaps > URLs in Sitemap Non-Indexable — lista todos estos casos.

---

## Referencias oficiales

- Especificación Google: https://developers.google.com/crawling/docs/robots-txt/robots-txt-spec
- Crear y enviar robots.txt: https://developers.google.com/crawling/docs/robots-txt/create-robots-txt
- Reglas útiles: https://developers.google.com/crawling/docs/robots-txt/useful-robots-txt-rules
- MC — Error robots.txt: https://support.google.com/merchants/answer/14526475
- MC — Imágenes no accesibles: https://support.google.com/merchants/answer/15092852
- MC — Página desktop no rastreable: https://support.google.com/merchants/answer/6098185
- MC — Página mobile no rastreable: https://support.google.com/merchants/answer/15488560
- RFC 9309 (estándar oficial): https://www.rfc-editor.org/rfc/rfc9309
