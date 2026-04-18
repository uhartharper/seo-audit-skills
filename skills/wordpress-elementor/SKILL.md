---
name: wordpress-elementor
description: >
  Conocimiento especializado sobre WordPress + Elementor para auditorías SEO.
  Issues recurrentes, soluciones y checklist de verificación específicos para
  sitios construidos con Elementor (free y Pro). Usar cuando el sitio auditado
  corra WordPress + Elementor o cuando el usuario mencione "Elementor", "Hello
  Elementor", "Elementor Pro" o "elementor-post".
---

# WordPress + Elementor — Guía SEO Técnica

> Verificado en Elementor 4.0.x / Elementor Pro 3.35.x + WordPress 6.x.
> Documentación oficial Elementor: https://elementor.com/help/
> Documentación desarrolladores: https://developers.elementor.com/

---

## Contexto de plataforma

Elementor es un page builder visual con sistema de widgets. A diferencia de
Divi, **genera archivos CSS externos** por post/página (`elementor-post-XXXXX.css`)
además de bloques `<style>` inline para estilos widget-específicos.

**Características clave con impacto SEO:**
- Renderizado **server-side (SSR)**: contenido en HTML inicial. No es SPA.
  Googlebot puede indexar sin ejecutar JS. Señalarlo como positivo.
- CSS externo por página: `elementor-post-[ID].css` — cargado como stylesheet
  externo, no como CSS inline masivo (diferencia clave vs. Divi).
- Sin embargo: genera **bloques `<style>` inline** para estilos widget-específicos
  que se inyectan en el `<head>`.
- **Lazy loading nativo**: Elementor aplica lazy load a secciones mediante CSS:
  `.e-con.e-parent:nth-of-type(n+4):not(.e-lazyloaded)` → oculta backgrounds
  hasta que JS lo marca como cargado. Afecta CLS y LCP.
- Google Fonts puede servirse localmente desde
  `/wp-content/uploads/elementor/google-fonts/` — verificar si está activo.

**Stacks habituales en cartera PubliUp:**

| Variante | Componentes |
|----------|------------|
| Básico | Elementor (free) + Hello Elementor theme + Yoast SEO |
| Pro | Elementor Pro + Hello Elementor o GeneratePress + Yoast + WP Rocket |
| WooCommerce | Elementor Pro + WooCommerce + WP Rocket + Yoast SEO + Schema Pro |

**Temas frecuentes:** Hello Elementor (child: `helloup`), GeneratePress

---

## Issues recurrentes — Detección y solución

### LCP hero image lazy-loaded (CRÍTICO — frecuencia: muy alta)

**Síntoma A — Elementor nativo:** La imagen hero above-the-fold tiene
`class="lazyload"` y `data-src` en lugar de `src`. El `src` real es un
placeholder SVG base64.

```html
<!-- Patrón problemático -->
<img data-src="https://dominio.com/hero.jpg"
     src="data:image/svg+xml;base64,..."
     class="lazyload wp-image-53">
```

**Síntoma B — WP Rocket + Elementor:** WP Rocket reemplaza el `src` real con
un placeholder SVG y mueve la URL real a `data-lazy-src`. Incluso si
`fetchpriority="high"` está en el elemento, el preload scanner no puede
descubrir la imagen.

```html
<!-- WP Rocket conflicto -->
<img src="data:image/svg+xml,..."
     data-lazy-src="https://cdn.shortpixel.ai/.../hero.webp"
     fetchpriority="high">  ← fetchpriority inútil si src es SVG placeholder
```

**Causa:** Elementor aplica lazy load a imágenes y backgrounds por defecto.
WP Rocket duplica el problema con su propio sistema de lazy load.

**Impacto:** LCP imagen no descubierta por preload scanner → LCP elevado en
mobile y conexiones lentas.

**Solución A — desactivar lazy load en sección hero (Elementor):**
- Abrir sección hero en Elementor Builder
- Advanced > Attributes: añadir `data-no-lazyload` o aplicar clase `e-no-lazyload`
- El CSS de Elementor excluye estas secciones del lazy load:
  `.e-con.e-parent:nth-of-type(n+4):not(.e-lazyloaded):not(.e-no-lazyload)`

**Solución B — excluir de WP Rocket lazy load:**
- WP Rocket > Media > LazyLoad > Excluded Images: añadir el filename de la imagen hero
  (ej: `hero-portada`, `envio-flores-domicilio`)

**Solución C — preload manual en `<head>`:**
```html
<link rel="preload" as="image"
      href="https://dominio.com/wp-content/uploads/hero.jpg"
      fetchpriority="high">
```

**Solución D — imagen con `<img>` real y `fetchpriority`:**
```php
// En el widget Image de Elementor, o via filtro:
add_filter('wp_get_attachment_image_attributes', function($attr, $attachment, $size) {
    // Aplicar solo a la imagen hero (identificar por ID o clase)
    if ($attachment->ID === HERO_IMAGE_ID) {
        $attr['fetchpriority'] = 'high';
        $attr['loading'] = 'eager';
        unset($attr['class']); // eliminar clase lazyload si existe
    }
    return $attr;
}, 10, 3);
```

---

### fetchpriority en elemento incorrecto (CRÍTICO — impacto LCP)

**Síntoma:** `fetchpriority="high"` aplicado a una imagen decorativa (separador,
divider) en lugar de a la imagen LCP real. A veces aparece duplicado en el
mismo elemento.

**Causa:** Elementor o el editor asigna manualmente `fetchpriority="high"` sin
criterio en el widget Image.

**Verificación:** Buscar en el HTML `fetchpriority="high"` y verificar que
corresponde a la imagen visualmente más grande above-the-fold.

**Solución:**
- Quitar `fetchpriority="high"` de imágenes decorativas (separadores, iconos)
- Añadirlo a la imagen hero / LCP real
- En Elementor > Widget Image > Advanced > Attributes

---

### CSS/JS excesivos — render-blocking (CRÍTICO — CWV)

**Síntoma:** 40-90+ recursos CSS y JS en el `<head>` o body temprano.

**Causas específicas de Elementor:**
- CSS widget-específico cargado globalmente (no por página):
  `widget-image.min.css`, `widget-icon-list.min.css`, `widget-divider.min.css`,
  `widget-social-icons.min.css`, etc.
- CSS de Font Awesome (eicons, fa-brands, fa-solid) cargado en todas las páginas
- jQuery + jQuery Migrate sin `defer`
- Plugins de eventos (The Events Calendar), GDPR, sliders — cargan en todas
  las páginas sin carga condicional

**Solución principal — Improved Asset Loading (Elementor):**
- Elementor > Settings > Performance (o Experiments)
- Activar **"Improved Asset Loading"**: carga solo el CSS de los widgets
  presentes en cada página, no el CSS global de todos los widgets
- Activar **"Inline Font Icons"** si está disponible: reduce peticiones de fonts

**Solución complementaria — WP Rocket o LiteSpeed Cache:**
- Diferir jQuery (con exclusión si hay conflictos con Elementor)
- Minificar y combinar CSS
- Activar "Delay JS execution" para scripts no críticos

**Carga condicional PHP** para plugins que no respetan páginas:
```php
// Desencolar The Events Calendar en páginas sin eventos
add_action('wp_enqueue_scripts', function() {
    if (!is_singular('tribe_events') && !is_post_type_archive('tribe_events')) {
        wp_dequeue_script('tec-user-agent-js');
        wp_dequeue_style('tribe-events-calendar-style');
        wp_dequeue_style('tribe-events-full-calendar-style');
    }
}, 100);
```

---

### Inline CSS masivo — bloques `<style>` de Elementor (ALTO — CWV)

**Síntoma:** 40+ bloques `<style>` inline en el `<head>` sumando ~94 KB
(observado en Coronas Urgentes).

**Causa:** Elementor inyecta estilos personalizados de cada widget directamente
en el HTML. En sitios con muchos widgets y secciones, esto acumula CSS inline
significativo.

**Diferencia con Divi:** El CSS principal de Elementor es externo
(`elementor-post-XXXXX.css`), pero los estilos personalizados del editor
se inyectan inline. Divi inyecta todo inline.

**Solución:**
- Activar "Improved Asset Loading" (reduce CSS inline moviendo estilos a archivo externo)
- WP Rocket > File Optimization > "Minify CSS" + "Combine CSS"
- Reducir uso de estilos custom por widget en el editor (usar clases CSS globales
  en lugar de estilos inline por elemento)

---

### WP Rocket + Elementor — HTML payload masivo (ALTO — CWV)

**Síntoma:** HTML de la página supera 500 KB o 1 MB.

**Causa:** WP Rocket inyecta inline la clase `RocketLazyLoadScripts` completa y
el objeto de configuración `elementorFrontendConfig` como script inline. En
Bopel se detectaron 737 KB; en Coronas Urgentes 1.39 MB.

**Impacto:** TTFB parsing alto, INP degradado, TBT elevado.

**Solución:**
- WP Rocket > File Optimization > "Minify JavaScript" activo
- Revisar si el objeto `elementorFrontendConfig` puede moverse a archivo externo
  via JS deferral settings
- Reducir número de secciones/widgets por página
- Activar "Improved Asset Loading" para reducir el objeto de configuración

---

### Elementor backgrounds como CSS background-image (ALTO — LCP)

**Síntoma:** La sección hero usa `background-image` en CSS inline del contenedor,
no un `<img>` tag.

**Causa:** El módulo Section/Container de Elementor aplica background vía CSS
por defecto para imágenes de sección.

**Impacto:** Imagen no visible para el preload scanner → LCP elevado.

**Comportamiento específico de Elementor lazy load:**
```css
/* CSS inyectado por Elementor — oculta backgrounds de secciones 4+ */
.e-con.e-parent:nth-of-type(n+4):not(.e-lazyloaded):not(.e-no-lazyload) {
    background-image: none !important;
}
```
Las secciones con background image después de la 3ª (desktop) o 2ª (mobile)
son invisible hasta que JS las marca como `e-lazyloaded`. Causa CLS cuando
"aparecen" al scroll.

**Solución:** Marcar secciones críticas con `e-no-lazyload`. Para secciones
hero que usen background, añadir preload manual del background.

---

### Seguridad — headers ausentes (CRÍTICO — frecuencia: 100%)

Observado en los 4 clientes Elementor. Sin excepción.

**Solución Nginx:**
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
fastcgi_hide_header X-Powered-By;
```

**Solución Apache / .htaccess:**
```apache
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
```

**CSP con Elementor:** Elementor y WooCommerce requieren `'unsafe-inline'` para
scripts y estilos. CSP estricta no viable sin nonces. CSP mínima recomendada:
```
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'
'unsafe-eval' *.googletagmanager.com *.facebook.net;
img-src 'self' data: *.facebook.com;
```
Advertencia: ajustar tras auditar todos los third-parties (GTM, Pixel, etc.).

---

### Exposición de versiones (ALTO — seguridad)

**Elementor expone su versión** en meta generator:
```html
<meta name="generator" content="Elementor 4.0.0; features: e_optimized_markup">
```

**Solución PHP:**
```php
// Eliminar generator de WordPress y Elementor
remove_action('wp_head', 'wp_generator');
add_filter('the_generator', '__return_empty_string');

// Eliminar generator meta de Elementor
add_action('wp_head', function() {
    remove_action('wp_head', [\Elementor\Core\Base\App::class, 'add_generator_tag']);
}, 0);
```

**X-Powered-By:** Igual que en Divi — eliminar en Nginx/Apache/php.ini.

---

### WP REST API — REST Link header expone IDs (MEDIO)

**Síntoma:** La cabecera `Link` en cada respuesta HTTP expone el ID interno
de WordPress de la página:
```
Link: <https://dominio.com/wp-json/wp/v2/pages/29615>; rel="alternate"
```

**Nota Elementor Pro:** Elementor Pro puede requerir el REST API para algunas
funcionalidades (formularios, templates). Verificar antes de restringir.

**Solución — eliminar Link header sin bloquear REST API:**
```php
// Eliminar header Link (REST API discovery) sin bloquear el API
remove_action('template_redirect', 'rest_output_link_header', 11);
```

**Solución — eliminar endpoint users (enumeración):**
```php
add_filter('rest_endpoints', function($endpoints) {
    unset($endpoints['/wp/v2/users']);
    unset($endpoints['/wp/v2/users/(?P<id>[\d]+)']);
    return $endpoints;
});
```

---

### DOM size — estructura Section/Column vs Container (MEDIO)

**Elementor Sections (legado):** Cada sección genera 4 divs de envoltura
(`section > .elementor-container > .elementor-row > .elementor-column > .elementor-widget-wrap`).

**Elementor Containers (Flexbox — moderno):** Genera solo 2 divs.
Lighthouse avisa si el body supera 818 nodos (warning) o 1.400 nodos (error).

**Solución:** Migrar layouts Section/Column → Containers vía el botón "Convert"
de Elementor. Reducción de DOM ~50% en secciones de una sola columna.
Ruta: Elementor > Tools > Replace URL / Converter.

---

### WooCommerce + Elementor — issues específicos (MEDIO)

**Duplicate schema breadcrumb:** Si se usan Yoast SEO + Schema Pro simultáneamente,
se generan dos `BreadcrumbList` conflictivos. Desactivar breadcrumbs en Schema Pro
y dejar solo el de Yoast.

**FAQPage schema en sitios e-commerce:** Google restringió FAQ rich results a
sitios gov/salud desde 2023. No genera rich results en e-commerce. No añadir
nuevas implementaciones de FAQPage en sitios comerciales.

**Product schema ausente:** WooCommerce no genera automáticamente `Product` +
`Offer` schema sin Yoast WooCommerce SEO add-on o Schema Pro correctamente
configurado. Verificar en cada producto.

**Mi cuenta en sitemap:** `/mi-cuenta/` suele estar marcada `noindex` pero
aparece en `page-sitemap.xml`. Excluir vía Yoast: SEO > Search Appearance >
WooCommerce > My Account: No.

**Robots.txt — bloquear URLs transaccionales WooCommerce:**
```
Disallow: /carrito/
Disallow: /checkout/
Disallow: /mi-cuenta/
Disallow: /cart/
Disallow: /checkout/
```

---

### PHP EOL — Elementor y PHP 7.4 (CRÍTICO si presente)

Detectado en Sana Quiropráctica: PHP 7.4.33 (EOL nov 2022).
Elementor 4.x requiere mínimo PHP 7.4 pero **recomienda PHP 8.0+**.

**Fix:** Actualizar en el panel del hosting (Hostinger hPanel, cPanel, Plesk).
Pasos: PHP Manager > Seleccionar PHP 8.2 o 8.3 > Guardar.
Verificar compatibilidad de plugins antes de actualizar.

---

### Google Tag Manager — posición bloqueante (MEDIO)

GTM se implementa frecuentemente como script síncrono en `<head>`. Aunque el
script principal de GTM se carga con `async`, el fragmento de inicialización
inline es render-blocking.

**Fix:** No existe solución perfecta — GTM requiere ser lo más early como sea
posible. Mitigaciones:
- Auditar tags dentro del contenedor GTM para eliminar los que bloquean
- Configurar tags de GTM para dispararse en `DOM Ready` o `Window Loaded`
  en lugar de `Page View` cuando sea posible
- Evaluar Partytown para mover GTM a web worker (experimental)

---

### Canibalización en páginas de localización (MEDIO)

Observado en Primera Imagen Limpiezas (14+ páginas de localización) y
Bopel (8.106 URLs de tanatorios). Elementor facilita duplicar templates
de página cambiando solo el nombre de localidad.

**Señales de alerta:**
- Múltiples páginas con la misma imagen decorativa (separador, divider)
- `lastmod` idéntico en grupo de URLs similares en el sitemap
- Patrón URL: `/servicio-[ciudad]/` con contenido idéntico salvo el nombre

**Fix:** Cada página de localización debe tener:
- Párrafo introductorio único con referencia a barrios / landmarks de esa ciudad
- Schema `areaServed` apuntando a esa municipalidad específica
- Mínimo 400-600 palabras de contenido único

---

## Checklist de auditoría técnica para sitios Elementor

```
CRÍTICO
[ ] LCP hero: ¿imagen con src real o SVG placeholder (data-src / data-lazy-src)?
[ ] fetchpriority="high": ¿está en la imagen LCP o en elemento incorrecto?
[ ] Security headers: HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy
[ ] PHP version: ¿EOL? Detectar en X-Powered-By
[ ] CSS/JS count: ¿>40 recursos en el head?

ALTO
[ ] WP Rocket: ¿reemplaza src hero con SVG placeholder?
[ ] Secciones hero: ¿marcadas con e-no-lazyload?
[ ] HTML payload: ¿supera 500 KB?
[ ] CSS inline blocks: ¿cuántos <style> en <head>?
[ ] Improved Asset Loading: ¿activo en Elementor Settings > Performance?
[ ] <meta name="generator"> Elementor: ¿eliminado?
[ ] X-Powered-By: ¿eliminado de headers HTTP?
[ ] WP REST API: Link header con IDs expuesto
[ ] WooCommerce: /mi-cuenta/ en sitemap con noindex (conflicto)
[ ] WooCommerce: schema Product + Offer en páginas de producto

MEDIO
[ ] DOM size: ¿Section/Column legado o Containers modernos?
[ ] GTM: ¿tags audited? ¿fire en Page View o DOM Ready?
[ ] WooCommerce + Yoast + Schema Pro: ¿BreadcrumbList duplicado?
[ ] FAQPage schema: ¿implementado en sitio e-commerce? (no genera rich results)
[ ] Index bloat: páginas de localización con contenido idéntico
[ ] Author archives: ¿indexados? (Yoast > Apariencia > Archivos)
[ ] "Sin categoría": ¿en sitemap?
[ ] og:type: ¿"article" en páginas de servicio? (debe ser "website")
[ ] OG image: ≥1200×630px, no decorativa

BAJO
[ ] IndexNow: ¿implementado?
[ ] Robots.txt: política AI crawlers
[ ] RSS feeds: ¿necesarios para este tipo de sitio?
[ ] Dofollow links a agencia en footer
[ ] URLs >100 caracteres en secciones programáticas
```

---

## Positivos habituales en sitios Elementor bien configurados

- SSR confirmado: contenido en HTML inicial sin necesidad de JS
- CSS externo por página (`elementor-post-XXXXX.css`) — no todo inline como Divi
- Google Fonts servidas localmente (`/wp-content/uploads/elementor/google-fonts/`)
- Imágenes con `width` + `height` explícitos → previene CLS
- `srcset` y `sizes` en imágenes → delivery responsivo
- ShortPixel CDN con WebP/AVIF si está configurado
- Canonical self-referencing en HTML inicial

---

## Clientes en cartera con WordPress + Elementor

| Cliente | Dominio | Variante | Server | Notas clave |
|---------|---------|---------|--------|-------------|
| Primera Imagen Limpiezas | primeraimagenlimpiezas.es | Elementor 4.0.0 + Hello Elementor | Nginx/Plesk | fetchpriority en decorativa; 90 recursos; 14+ páginas loc. |
| Coronas Urgentes | coronasurgentes.es | Elementor + WooCommerce + WP Rocket | Apache/Ubuntu | 1.39 MB HTML; robots.txt bloqueante global |
| Bopel | bopel.es | Elementor Pro + WooCommerce + WP Rocket + Schema Pro | Apache/Ubuntu | WP Rocket SVG placeholder en LCP; 8.106 URLs sitemap |
| Sana Quiropráctica | sanaquiropractica.com | Elementor 4.0.0 + Hello Elementor | LiteSpeed/Hostinger | PHP 7.4 EOL; sitemap con noindex header; GTM bloqueante |

---

## Referencias rápidas — Rutas de configuración

**Elementor:**
- Improved Asset Loading: Elementor > Settings > Performance
- Lazy load hero image: Widget > Advanced > Attributes: `data-no-lazyload` o clase `e-no-lazyload`
- DOM Converter (Section → Container): Elementor > Tools
- Google Fonts local: Elementor > Settings > Advanced > Google Fonts

**WP Rocket:**
- Excluir imagen de lazy load: WP Rocket > Media > LazyLoad > Excluded Images
- Defer JS: WP Rocket > File Optimization > Defer JS execution
- Minify CSS/JS: WP Rocket > File Optimization

**Yoast SEO:**
- WooCommerce pages en sitemap: SEO > Search Appearance > WooCommerce
- Author archives: SEO > Search Appearance > Archives
- OG/Twitter Card: SEO > Search Appearance > Social

**WordPress core (mismo stack que Divi — ver wordpress-divi skill):**
- Eliminar generator: `remove_action('wp_head', 'wp_generator')`
- Restringir REST API users: `unset($endpoints['/wp/v2/users'])`
- Eliminar REST Link header: `remove_action('template_redirect', 'rest_output_link_header', 11)`
