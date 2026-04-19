---
name: canonical
description: >
  Auditoría e implementación de canonical tags. Cubre self-referencing, paginación,
  parámetros URL, conflictos con hreflang, bugs por CMS (Yoast, Rank Math, WooCommerce,
  PrestaShop, Elementor), JavaScript rendering, canonical chains y casos donde
  canonical es la causa raíz de problemas de indexación o canibalización.
user-invokable: false
---

# Canonical Tags — Guía Técnica SEO

> Especificación oficial: https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls

---

## Qué hace el canonical

`<link rel="canonical" href="URL" />` indica a Google qué URL debe indexar cuando
varias URLs tienen contenido igual o muy similar. Google lo trata como una **señal
fuerte**, no como una directiva absoluta — puede ignorarlo si detecta una contradicción
con otros señales (hreflang, sitemap, internal links).

### Cuándo implementar

- Parámetros de URL que generan contenido duplicado (`?color=rojo`, `?page=1`, `?ref=`)
- Paginación (`/blog/page/2/` canonical a sí misma, NO a la primera página)
- Versiones con y sin trailing slash (`/servicio` vs `/servicio/`)
- Versiones HTTP/HTTPS o www/non-www duplicadas
- Productos en múltiples categorías (`/cat-a/producto/` y `/cat-b/producto/`)
- Contenido sindicado publicado en otro sitio (el original apunta a sí mismo)

### Cuándo el canonical NO es la solución

- Contenido sustancialmente diferente entre las URLs — usar canonical diferente es
  señal de manipulación y Google puede ignorarlo
- Páginas que deben indexarse de forma independiente — usar canonical a otra URL las
  elimina del índice efectivamente
- Redirección 301 disponible y apropiada — el 301 es más fuerte y limpio

---

## Sintaxis correcta

```html
<!-- En el <head>, siempre URL absoluta -->
<link rel="canonical" href="https://dominio.com/servicio/" />
```

### Reglas obligatorias

1. **URL absoluta**: incluir protocolo, dominio y ruta completa. Las URLs relativas
   son válidas pero arriesgadas — si el head se incluye en otro contexto, la URL
   relativa resolverá incorrectamente.
2. **Una sola etiqueta canonical por página**: múltiples canonical se ignoran por
   completo (Google descarta toda la directiva).
3. **Self-referencing en páginas canónicas**: la página canónica debe apuntar a sí
   misma. Sin self-reference, la cadena canonical puede romperse.
4. **Coherencia con sitemap**: las URLs en el sitemap deben coincidir con las URLs
   canonical. URL en sitemap ≠ URL canonical = señal contradictoria.
5. **Coherencia con hreflang**: las URLs declaradas en hreflang deben ser las URLs
   canonical de cada idioma/región. URL en hreflang ≠ canonical = hreflang ignorado.

---

## Paginación — regla crítica

```html
<!-- /blog/page/2/ — CORRECTO: self-referencing canonical -->
<link rel="canonical" href="https://dominio.com/blog/page/2/" />

<!-- /blog/page/2/ — INCORRECTO: canonical a página 1 -->
<link rel="canonical" href="https://dominio.com/blog/" />
```

**El canonical de página 2 a página 1 le dice a Google que página 2 es duplicado de
página 1 y no debe indexarse.** Google acepta esta señal — las páginas de paginación
desaparecen del índice. Esto elimina la capacidad de descubrir posts antiguos via
crawl de listado.

Yoast y Rank Math, correctamente configurados, generan self-referencing canonical en
paginación. Si no, verificar la configuración del plugin.

---

## Parámetros URL

### Parámetros que NO cambian el contenido (deben canonical a URL limpia)

```
/producto/?color=rojo → canonical: /producto/
/blog/?orderby=date  → canonical: /blog/
/categoria/?page=1   → canonical: /categoria/
```

### Parámetros que SÍ generan contenido distinto (self-referencing)

```
/buscar/?q=silla-ergonomica → canonical: /buscar/?q=silla-ergonomica (o noindex si es thin)
/producto/?variant=xl       → depende: si tiene contenido propio, self-referencing
```

### Parámetros de tracking y UTMs

Siempre canonical a URL sin UTM. Google puede crawlear `?utm_source=newsletter` —
sin canonical, genera duplicados.

```
/articulo/?utm_source=email → canonical: /articulo/
```

---

## Implementación en WordPress

### Yoast SEO

Yoast genera canonical automáticamente. La URL canónica es la URL de la página
tal como Yoast la resuelve — generalmente correcta.

**Sobrescribir canonical en Yoast:**
En cada post/página: SEO > Advanced > Canonical URL — introducir URL completa.

**Issue — canonical relativo en instalaciones multisite o subdirectorios:**
Yoast a veces genera canonical relativo (`/es/servicio/`) en instalaciones de
subdirectorio. Verificar en View Source que el canonical tiene protocolo y dominio.

**Issue — paginación de comentarios:**
Si los comentarios están paginados (`/articulo/comment-page-2/`), Yoast puede
generar canonical a la página de comentarios en lugar de al artículo original.
Verificar en posts con muchos comentarios.

### Rank Math

Rank Math genera canonical correctamente por defecto.

**Bug conocido — canonical duplicado con Elementor:**
En algunas versiones, Elementor y Rank Math pueden generar dos etiquetas canonical.
La primera se aplica; la segunda crea una señal contradictoria que Google ignora.
Verificar con View Source > buscar `rel="canonical"` — debe aparecer exactamente una vez.

**Sobrescribir canonical en Rank Math:**
Post editor > Rank Math > Advanced > Canonical URL.

### WooCommerce

**Issue crítico — productos en múltiples categorías:**

WooCommerce asigna una "categoría principal" (primary category) en Yoast para
determinar el canonical. Sin categoría principal configurada, WooCommerce puede
generar canonicals distintos para el mismo producto dependiendo de la URL de entrada.

```
/categoria-a/silla-ergonomica/  → canonical: /categoria-a/silla-ergonomica/
/categoria-b/silla-ergonomica/  → canonical: /categoria-b/silla-ergonomica/
```

Ambas apuntan a sí mismas — Google ve dos versiones canónicas distintas del mismo
producto y puede indexar ambas o elegir una arbitrariamente.

**Fix:** Configurar primary category en Yoast para cada producto:
Post editor > Yoast > Categories > marcar una como primary (icono de casa).

**Issue — variaciones de producto como páginas independientes:**
Las variaciones (`/producto/?attribute_pa_color=rojo`) no tienen URL propia en
WooCommerce por defecto. Si algún plugin genera URLs de variación (`/producto/rojo/`),
deben canonical al producto padre.

**Issue — URLs con endpoints de WooCommerce:**
```
/carrito/                 → noindex (correcto)
/mi-cuenta/               → noindex (correcto)
/checkout/                → noindex (correcto)
/tienda/page/1/           → canonical a /tienda/ o self-referencing según la config
```
Verificar que estos endpoints no aparezcan en sitemap y que su canonical sea consistente.

### PrestaShop

**Issue — URLs con parámetros de facetas de LayerNavigation:**
El módulo de facetas genera URLs con parámetros (`/categoria?q=Color-Rojo/Talla-L`).
Canonical incorrecto o ausente en estas URLs genera miles de duplicados.

**Verificar:**
```bash
# Screaming Frog: filtrar URLs con ? en el path de listados de categoría
# Columna canonical: verificar que apunta a la URL sin parámetros
```

PrestaShop `ps_configuration`:
- `PS_CANONICAL_REDIRECT`: si está a 0, las URLs alternativas no redirigen al canonical
- `PS_LAYERED_FULL_TREE`: si está activo, genera más URLs de facetas

**Issue — URLs con ID de categoría en la ruta:**
PrestaShop puede generar tanto `/3-ropa/` (con ID) como `/ropa/` (sin ID) para la
misma categoría. La URL con ID debe redirigir 301 a la sin ID, no coexistir.

---

## Canonical chains (cadenas de canonicals)

Una canonical chain ocurre cuando:
- A canonical apunta a B
- B canonical apunta a C
- C es la URL real canónica

Google sigue la cadena pero depreca la señal en cada salto. Tras 2-3 saltos,
puede resolver B como canonical en lugar de C.

**Causa frecuente:** migración de URLs sin actualizar todos los canonicals.
```
/producto-viejo/ → canonical: /producto-nuevo/
/producto-nuevo/ → canonical: /producto-final/   ← cadena de 2 saltos
```

**Fix:** el canonical de `/producto-viejo/` debe apuntar directamente a `/producto-final/`.

**Detección en Screaming Frog:**
Reports > Canonicals > Canonical Chains — lista todas las cadenas detectadas.

---

## Canonical vs 301 — cuándo usar cada uno

| Situación | Solución correcta |
|-----------|-------------------|
| Dos URLs con contenido idéntico, solo una debe existir | 301 redirect |
| Dos URLs con contenido idéntico que deben coexistir (e.g., tracking) | Canonical |
| Versión HTTP y HTTPS del mismo sitio | 301 redirect + canonical |
| Producto en dos categorías con la misma URL de producto | Canonical (primary category) |
| Página de paginación | Self-referencing canonical |
| Parámetro de UTM o tracking | Canonical a URL limpia |
| Contenido sindicado en otro sitio | Canonical al original (desde el sindicado) |

Un 301 transmite PageRank. Un canonical también consolida señales pero de forma
más lenta y menos garantizada. Para URLs que deben eliminarse permanentemente,
301 > canonical.

---

## JavaScript rendering y canonical

Si el canonical se inyecta via JavaScript (React, Vue, SPA), Google necesita renderizar
la página para leerlo. El canonical HTML estático se lee en el primer crawl; el canonical
JS se lee solo después del rendering (puede tomar días o semanas).

**Regla:** siempre incluir el canonical en el HTML estático. Si el framework lo genera
via JS, añadir también el tag estático o configurar SSR/prerendering.

**Verificar rendering en GSC:**
URL Inspection > Ver página renderizada > buscar `rel="canonical"` en el código renderizado.

---

## Errores comunes

### Error 1: Canonical a URL con redirect

El canonical apunta a `/pagina/` pero esa URL redirige 301 a `/pagina-nueva/`.
Google puede seguir el redirect y resolver `/pagina-nueva/` como canónica, o puede
ignorar el canonical por la inconsistencia.

**Fix:** actualizar canonical para apuntar directamente a la URL final, sin redirects.

**Detección:** Screaming Frog > Reports > Canonicals > Canonical Points to Redirect.

---

### Error 2: Canonical en página noindex

Una página con `meta robots: noindex` y un canonical apuntando a otra URL.
Google no indexará la página por el noindex — el canonical es irrelevante.
Más problemático: si la página tiene noindex pero el canonical apunta a una página
que Google quiere indexar, la señal es contradictoria.

**Regla:** noindex y canonical no deben coexistir apuntando a URLs distintas.

---

### Error 3: Canonical a URL que devuelve 404

Idéntico en comportamiento a un redirect incorrecto — Google descarta el canonical.

**Detección:** Screaming Frog > Reports > Canonicals > Non-Indexable Canonicals.

---

### Error 4: Múltiples etiquetas canonical en el mismo `<head>`

Ocurre con themes que añaden canonical + plugin SEO que también lo añade.

```html
<!-- Resultado: Google ignora ambos -->
<link rel="canonical" href="https://dominio.com/servicio/" />
<link rel="canonical" href="https://dominio.com/servicios/servicio/" />
```

**Detección:** View Source > buscar `rel="canonical"`. Screaming Frog detecta esto
automáticamente bajo "Multiple Canonicals".

---

### Error 5: Canonical relativo

```html
<!-- Arriesgado: qué dominio resuelve /servicio/? -->
<link rel="canonical" href="/servicio/" />
```

Si el HTML es reutilizado en otro dominio (sindicación, staging, multisite), el canonical
relativo resuelve al dominio equivocado. Usar siempre URL absoluta.

---

## Detección en Screaming Frog

Columnas clave en la pestaña Internal:

| Columna | Qué buscar |
|---------|------------|
| Canonical Link Element 1 | URL canonical declarada |
| Canonical Link Element 1 (Match) | Yes/No — ¿coincide con la URL crawleada? |
| Indexability | Indexable / Non-Indexable |
| Canonical — Non-Indexable | Páginas cuyo canonical apunta a URL no-indexable |
| Canonical — Points to Redirect | Canonical que apunta a un redirect |
| Canonical — Contains Rel=Canonical | Páginas sin canonical declarado |

**Reports > Canonicals** consolida todos los issues detectados en categorías.

---

## GSC — señales de canonical incorrecto

- **"Duplicate without user-selected canonical"**: Google encontró duplicados pero
  ninguno tiene canonical. Google eligió uno por su cuenta.
- **"Duplicate, Google chose different canonical than user"**: canonical declarado pero
  Google ignoró la señal y eligió otra URL como canonical. Indica contradicción:
  el canonical declarado puede estar apuntando a una URL peor (menos links, peor
  rendimiento) que la URL que Google prefiere.
- **"Excluded by 'noindex' tag"**: URL excluida — verificar que no había un canonical
  apuntando desde otra URL a esta.

---

## Checklist de auditoría canonical

```
CRÍTICO
[ ] ¿Alguna página con múltiples etiquetas canonical?
[ ] ¿Canonical apuntando a URL con redirect?
[ ] ¿Canonical apuntando a URL que devuelve 404?
[ ] ¿Canonical apuntando a URL noindex?
[ ] ¿GSC reporta "Google chose different canonical"? → señal de contradicción

ALTO
[ ] ¿Productos WooCommerce en múltiples categorías con primary category configurada?
[ ] ¿Paginación con canonical a página 1 en lugar de self-referencing?
[ ] ¿Parámetros UTM o de tracking sin canonical a URL limpia?
[ ] ¿Canonicals relativos en lugar de absolutos?
[ ] ¿Canonical chains (A→B→C)? → consolidar a A→C

MEDIO
[ ] ¿URLs en sitemap coinciden con URLs canonical?
[ ] ¿URLs en hreflang coinciden con URLs canonical?
[ ] ¿Canonical generado por JS en lugar de HTML estático?
[ ] ¿Páginas sin canonical declarado en sitios con muchos parámetros URL?

BAJO
[ ] ¿PrestaShop LayerNavigation con canonical en URLs de facetas?
[ ] ¿Comentarios paginados con canonical incorrecto?
[ ] ¿Contenido sindicado sin canonical al original?
```

---

## Referencias

- Consolidar URLs duplicadas: https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
- Canonical y paginación: https://developers.google.com/search/docs/specialty/ecommerce/pagination-and-incremental-page-loading
- Informe de cobertura GSC: https://support.google.com/webmasters/answer/7440203
