---
name: prestashop-seo
description: >
  Conocimiento especializado sobre PrestaShop para auditorías SEO.
  Issues recurrentes, configuraciones del backoffice, estructura de URLs,
  sitemap y performance específicos de PrestaShop. Usar cuando el sitio
  auditado corra PrestaShop o cuando el usuario mencione "PrestaShop",
  "controlador", "CCC" o "1_index_sitemap".
---

# PrestaShop — Guía SEO Técnica

> Verificado en PrestaShop 1.7.x / 8.x con PHP 8.1.x.
> Documentación oficial SEO: https://docs.prestashop-project.org/v.8-documentation/user-guide/configuring-shop/shop-parameters/traffic/seo-and-urls
> Documentación performance: https://docs.prestashop-project.org/v.8-documentation/user-guide/configuring-shop/advanced-parameters/performance

---

## Contexto de plataforma

PrestaShop es un CMS e-commerce PHP con renderizado **server-side (SSR)**.
El contenido está en el HTML inicial — no requiere JS para ser indexado.

**Diferencias clave vs WordPress:**
- Sin page builder nativo. El frontend usa Smarty templates.
  Algunos sitios instalan **CreativeElements** (clon de Elementor para PS) —
  genera los mismos problemas de CSS/JS que Elementor en WordPress.
- El sistema de URLs incluye **ID numérico por defecto** en categorías:
  `/217-ramos-de-flores` en lugar de `/ramos-de-flores`.
- El sitemap se genera como `1_index_sitemap.xml` (no `sitemap.xml`).
- Caché desactivada por defecto (`Cache-Control: no-store`) — issue crítico.
- robots.txt **generado automáticamente** por PrestaShop con bloqueo de
  parámetros de consulta y controladores internos.

**Stack habitual:**
```
PrestaShop 8.x + PHP 8.1.x + Nginx/Plesk
+ CreativeElements (page builder opcional)
+ Google Analytics / GTM
+ Facebook Pixel
+ Módulo de sitemap nativo de PrestaShop
Hosting: Plesk / servidor dedicado / VPS
```

---

## Rutas de configuración en el backoffice

| Sección | Ruta |
|---------|------|
| Friendly URLs / SEO & URLs | Shop Parameters > Traffic & SEO > SEO & URLs |
| Robots.txt generator | Shop Parameters > Traffic & SEO > SEO & URLs (al final) |
| CCC (CSS/JS cache) | Advanced Parameters > Performance > CCC |
| Smarty cache | Advanced Parameters > Performance > Smarty |
| Server-side cache (Memcache/Redis) | Advanced Parameters > Performance > Caching |
| Sitemap XML | Catalog > (módulo de sitemap) o Modules > Sitemap |
| Meta tags por página | Shop Parameters > Traffic & SEO > SEO & URLs > lista de páginas |
| Canonical redirect | Shop Parameters > Traffic & SEO > SEO & URLs > "Redirect to Canonical URL" |

---

## Issues recurrentes — Detección y solución

### sitemap.xml devuelve 404 (CRÍTICO — frecuencia: muy alta)

**Síntoma:** `https://dominio.com/sitemap.xml` → HTTP 404.

**Causa:** PrestaShop genera el sitemap en una ruta no estándar:
`/1_index_sitemap.xml` (o `1_[lang]_[shop]_sitemap.xml`). La ruta estándar
`/sitemap.xml` no existe salvo que se configure explícitamente.

**Impacto:** Google Search Console y la mayoría de crawlers prueban
`/sitemap.xml` primero. El sitemap real puede quedar sin descubrir si no
está declarado en robots.txt.

**Verificación:** `curl -I https://dominio.com/sitemap.xml`

**Solución A — Redirect en Nginx:**
```nginx
location = /sitemap.xml {
    return 301 https://dominio.com/1_index_sitemap.xml;
}
```

**Solución B — Redirect en .htaccess (Apache):**
```apache
RedirectPermanent /sitemap.xml https://dominio.com/1_index_sitemap.xml
```

**Solución C — Verificar que robots.txt declara la ruta correcta:**
```
Sitemap: https://dominio.com/1_index_sitemap.xml
```

---

### URLs con ID numérico en categorías (ALTO — estructura)

**Síntoma:** Categorías en formato `/217-ramos-de-flores` en lugar de
`/ramos-de-flores`. La URL limpia devuelve 404.

**Causa:** PrestaShop incluye el ID de categoría en la URL por defecto para
garantizar unicidad interna. Es el comportamiento estándar del sistema
Friendly URLs de PrestaShop.

**Impacto:** URLs no limpias, difíciles de gestionar en migraciones. Sin embargo,
la canonical en la página apunta a la URL con ID — no hay duplicado. El impacto
SEO directo es bajo pero afecta usabilidad y migración futura.

**Verificación:** El canonical en la página de categoría debe apuntar a la
URL con ID numérico (correcto). Si hay dos versiones accesibles (con y sin ID)
ambas con 200, hay problema de duplicado.

**Solución (si se decide eliminar IDs):**
- Backoffice: Shop Parameters > Traffic & SEO > Schema of URLs
- Requiere **plan de migración completo**: 301 redirects de todas las URLs
  con ID a las nuevas URLs limpias antes de cambiar la configuración.
- No hacer sin migración planificada — rompe todas las URLs existentes.

**Nota:** Si el sitio no tiene historial de backlinks ni tráfico significativo
en URLs con ID, la migración tiene bajo riesgo. Si tiene backlinks, priorizar
la migración con herramienta de redirects.

---

### Cache-Control: no-store en todas las páginas (CRÍTICO — CWV)

**Síntoma:** Cabecera `Cache-Control: no-store, no-cache, must-revalidate` en
todas las respuestas HTML.

**Causa:** PrestaShop desactiva el caché de HTML por defecto porque las páginas
pueden contener datos de sesión del usuario (carrito, precios por grupo, etc.).

**Impacto:** Cada visita requiere un round-trip completo al servidor. Directo
sobre LCP y TTFB. Especialmente grave para Googlebot y usuarios en conexiones
lentas.

**Solución — Activar CCC en PrestaShop:**
Ruta: Advanced Parameters > Performance > CCC (Combine, Compress, Cache)

Opciones a activar:
| Opción | Acción |
|--------|--------|
| Smart cache for CSS | Activar — combina + comprime CSS |
| Smart cache for JavaScript | Activar — combina + comprime JS |
| Minify HTML | Activar — elimina whitespace del HTML |
| Compress inline JavaScript in HTML | Activar |
| Move JavaScript to the end | Activar — mueve JS al final del body |
| Apache optimization | Activar si el servidor lo soporta |

**Solución complementaria — Smarty cache:**
Ruta: Advanced Parameters > Performance > Smarty

| Opción | Valor recomendado en producción |
|--------|--------------------------------|
| Cache compilation | "Never recompile template files" |
| Cache | Enabled |
| Caching type | File system (por defecto) |

**Solución avanzada — Full-page cache:**
Para sitios con tráfico alto, añadir Varnish o módulo de full-page cache.
El módulo oficial de PrestaShop soporta Memcached y Redis para object cache
(Advanced Parameters > Performance > Caching).

**Advertencia:** Activar CCC puede romper temas personalizados. Probar en
staging antes de producción.

---

### URLs de controladores en el sitemap (CRÍTICO)

**Síntoma:** El sitemap incluye URLs como:
- `index.php?controller=module-creativeelements-ajax`
- `index.php?controller=module-creativeelements-preview`
- `index.php?controller=product`
- `index.php?controller=category`

**Causa:** El módulo de sitemap de PrestaShop (o CreativeElements) añade
endpoints internos AJAX/preview al sitemap.

**Impacto:** Google indexa o intenta indexar endpoints internos que devuelven
contenido vacío o de error. Desperdicio de crawl budget.

**Solución A — Excluir desde el módulo de sitemap:**
- Modules > Sitemap Generator > configurar qué tipos de páginas se incluyen
- Desactivar "Module pages" o "CMS pages" si incluyen controllers no deseados

**Solución B — Bloquear en robots.txt:**
```
Disallow: /*controller=module-creativeelements-ajax
Disallow: /*controller=module-creativeelements-preview
Disallow: /*controller=product$
Disallow: /*controller=category$
```

**Nota:** robots.txt de PrestaShop se regenera desde el backoffice:
Shop Parameters > Traffic & SEO > Generate robots.txt. Editar el archivo
físico puede sobrescribirse. Añadir reglas via el campo "Custom robots.txt"
si está disponible, o mediante hook `actionHtaccessCreate`.

---

### CSS/JS excesivos — sin CCC activo (CRÍTICO — CWV)

**Síntoma:** 30-50 archivos CSS y 20+ JS cargados en cada página.

**Causa:** PrestaShop carga un archivo CSS/JS por módulo. Sin CCC activo,
cada módulo instalado añade sus assets de forma independiente.

**Issues específicos observados:**
- CSS de módulo cargado dos veces (bug de CreativeElements)
- Google Fonts externo sin `font-display: swap`
- jQuery sin defer (al final del body por defecto en PS, pero bloquea si está
  en head)
- Font Awesome en múltiples bundles (FA brands + FA solid + eicons)

**Solución principal:** Activar CCC (ver sección anterior).

**Solución complementaria — Google Fonts:**
Autoalojamiento via Google Fonts Helper (gwfh.mranftl.com) o añadir
`&display=swap` al URL de Google Fonts + preconnect:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
```

**Duplicate CSS fix:** Auditar el fichero de registro del módulo problemático
en `/modules/[nombre]/views/templates/hook/` y eliminar el `registerStylesheet`
duplicado.

---

### Hero como CSS background-image (ALTO — LCP)

**Síntoma:** La imagen hero del slider usa `background-image` en estilo inline
del contenedor (habitual con CreativeElements o el módulo homeslider nativo).

**Causa:** Los sliders de PrestaShop (homeslider, LayerSlider, CreativeElements)
usan background-image CSS por defecto.

**Impacto:** Imagen no visible para el preload scanner → LCP elevado.

**Solución:**
```html
<!-- En el template Smarty del tema, añadir en <head>: -->
<link rel="preload" as="image"
      href="{$hero_image_url}"
      fetchpriority="high">
```

O via hook `displayHeader` en un módulo personalizado:
```php
public function hookDisplayHeader($params) {
    return '<link rel="preload" as="image"
            href="' . $this->context->link->getMediaLink('/img/cms/hero.jpg') . '"
            fetchpriority="high">';
}
```

---

### PHPSESSID con expiración de décadas (MEDIO — RGPD)

**Síntoma:** `Set-Cookie: PHPSESSID=...; expires=...-2082`.

**Causa:** Configuración por defecto de PrestaShop con `session.gc_maxlifetime`
excesivo.

**Impacto:** RGPD / ePrivacy — cookie de sesión con expiración de décadas.
Puede ser observación de auditoría AEPD.

**Solución en php.ini o .user.ini:**
```ini
session.cookie_lifetime = 0          ; cookie de sesión (sin expires)
session.gc_maxlifetime = 3600        ; 1 hora de inactividad
```

O en PrestaShop via `parameters.php` o `config/defines.inc.php`:
```php
ini_set('session.cookie_lifetime', 0);
```

---

### Canonical ausente en homepage (CRÍTICO si ocurre)

**Síntoma:** No hay `<link rel="canonical">` en la homepage.

**Causa:** Bug en tema o módulo que no inyecta el canonical en la raíz.

**Impacto:** Riesgo de duplicados via parámetros de URL (`?id_currency=`,
`?back=`, `?controller=index`).

**Solución en template Smarty (`head.tpl` o equivalente):**
```smarty
<link rel="canonical" href="{$urls.current_url|escape:'html':'UTF-8'}" />
```
O usar el módulo SEO integrado de PrestaShop que lo gestiona automáticamente.

---

### Multiple H1 en homepage (ALTO si ocurre)

**Causa:** Sliders y módulos de sección arrastran H1 a títulos de carrusel.

**Verificación:** `document.querySelectorAll('h1')` en DevTools.

**Solución:** Cambiar etiquetas de sección/carrusel de H1 a H2 en el template
Smarty o en la configuración del módulo de slider.

---

### Open Graph / Twitter Card ausentes (ALTO)

**Causa:** PrestaShop no genera OG tags por defecto. Requiere módulo SEO o
implementación manual en el tema.

**Solución — en template Smarty:**
```smarty
<meta property="og:title" content="{$page.meta.title|escape:'html':'UTF-8'}" />
<meta property="og:description" content="{$page.meta.description|escape:'html':'UTF-8'}" />
<meta property="og:url" content="{$urls.current_url|escape:'html':'UTF-8'}" />
<meta property="og:image" content="{$og_image_url|escape:'html':'UTF-8'}" />
<meta property="og:type" content="website" />
<meta name="twitter:card" content="summary_large_image" />
```

---

### Seguridad — headers (ALTO)

**Solución Nginx:**
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

**CSP con PrestaShop:** Compleja por el número de third-parties habituales.
Comenzar en modo report-only:
```nginx
add_header Content-Security-Policy-Report-Only "default-src 'self';
  script-src 'self' 'unsafe-inline' *.googletagmanager.com *.google-analytics.com
  *.facebook.net *.facebook.com;
  img-src 'self' data: https:;
  style-src 'self' 'unsafe-inline' fonts.googleapis.com;
  font-src 'self' fonts.gstatic.com;" always;
```

**X-Powered-By en Plesk + Nginx:**
```nginx
fastcgi_hide_header X-Powered-By;
```
En php.ini: `expose_php = Off`

---

### Schema Product + Offer (e-commerce)

**PrestaShop genera Product schema automáticamente** en versiones recientes
si está habilitado en las preferencias del módulo. Verificar si el módulo SEO
nativo lo genera o si requiere override.

Campos mínimos requeridos: `name`, `description`, `image`, `offers` (con
`price`, `priceCurrency`, `availability`).

**AggregateRating** requiere tener el módulo de valoraciones activo y
configurado para exportar datos al JSON-LD.

---

### IndexNow en PrestaShop (MEDIO)

**Solución:** Módulo de terceros disponible en PrestaShop Addons.
Alternativamente, implementar via API manualmente en el hook
`actionObjectProductUpdateAfter`:

```php
public function hookActionObjectProductUpdateAfter($params) {
    $url = $this->context->link->getProductLink($params['object']);
    $key = 'TU_CLAVE_INDEXNOW';
    file_get_contents("https://api.indexnow.org/indexnow?url={$url}&key={$key}");
}
```

---

## Checklist de auditoría técnica para sitios PrestaShop

```
CRÍTICO
[ ] sitemap.xml: ¿devuelve 200 o 404? Si 404, ¿hay redirect o declaración en robots.txt?
[ ] Cache-Control: ¿"no-store" en páginas HTML? → activar CCC
[ ] Controllers en sitemap: ¿hay URLs ?controller= en el sitemap?
[ ] Canonical: ¿presente en homepage?
[ ] H1: ¿uno solo por página?

ALTO
[ ] URLs de categoría: ¿formato /ID-slug? ¿la versión sin ID devuelve 404 (correcto) o 200 (duplicado)?
[ ] Hero image: ¿background-image CSS o <img>? ¿hay preload link?
[ ] CCC: ¿activado? (Advanced Parameters > Performance)
[ ] CSS count: ¿30+ archivos? → indica CCC inactivo
[ ] Open Graph: ¿presente en todas las páginas?
[ ] Twitter Card: ¿presente?
[ ] og:image: ¿presente y ≥1200×630px?
[ ] Security headers: HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy
[ ] X-Powered-By: ¿eliminado?
[ ] PHPSESSID: ¿expiración razonable? (no décadas)

MEDIO
[ ] Product schema: ¿presente con Offer (price, availability, currency)?
[ ] AggregateRating: ¿módulo de valoraciones activo y exportando a JSON-LD?
[ ] LocalBusiness schema en homepage (si negocio local)
[ ] SearchAction schema (WebSite)
[ ] robots.txt: ¿política de AI crawlers definida?
[ ] IndexNow: ¿módulo instalado?
[ ] Google Fonts: ¿externo o self-hosted?
[ ] CSS duplicado: verificar si hay stylesheets cargados 2 veces
[ ] Product images: ¿alt text en todos los productos?
[ ] Buscador / search page: ¿noindex?
[ ] Páginas funcionales (/pedido-rapido, /registro, /iniciar-sesion): ¿noindex?

BAJO
[ ] meta keywords: ¿vacíos o eliminados?
[ ] Theme path expuesto (/themes/[nombre]/): información disclosure menor
[ ] lastmod en sitemap: ¿actualizado en cada cambio?
[ ] HTML lang attribute: formato correcto ("es" no "lang-es")
```

---

## Positivos habituales en sitios PrestaShop bien configurados

- SSR confirmado: contenido visible sin JS (ventaja directa vs JS-heavy CMSs)
- HSTS con preload (`max-age=31536000; includeSubDomains; preload`)
- Security headers completos (cuando el hosting tiene configuración dedicada)
- Product schema con Offer bien implementado (generado nativamente por PS)
- BreadcrumbList correcto en páginas de producto
- Canonical self-referencing en producto y categoría
- Canonical coherente con URL numérica en categorías (sin duplicados)
- HTTPS enforced con 301 HTTP→HTTPS y www→no-www en un solo hop
- robots.txt generado automáticamente por PrestaShop con bloqueo de parámetros
  de carrito, búsqueda y sesión

---

## Referencias clave PrestaShop

- SEO & URLs (PS8): https://docs.prestashop-project.org/v.8-documentation/user-guide/configuring-shop/shop-parameters/traffic/seo-and-urls
- Performance / CCC (PS8): https://docs.prestashop-project.org/v.8-documentation/user-guide/configuring-shop/advanced-parameters/performance
- SEO Rules & Behaviours (specs): https://build.prestashop-project.org/prestashop-specs/1.7/broader-topics/seo-rules-and-behaviours.html
- Hooks disponibles: `displayHeader`, `actionHtaccessCreate`, `actionModifyFrontendSitemap`
