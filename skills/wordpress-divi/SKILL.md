---
name: wordpress-divi
description: >
  Conocimiento especializado sobre WordPress + Divi para auditorías SEO.
  Issues recurrentes, soluciones y checklist de verificación específicos para
  sitios construidos con Divi Theme de Elegant Themes. Usar cuando el sitio
  auditado corra WordPress + Divi o cuando el usuario mencione "Divi", "Elegant
  Themes", "Divi Builder" o "Divi Theme".
---

# WordPress + Divi — Guía SEO Técnica

> Verificado en Divi 4.27.x + WordPress 6.x. Revisar ante salto de versión
> mayor (especialmente Divi 5, que introduce cambios de arquitectura).
> Documentación oficial WordPress: https://developer.wordpress.org/reference/
> Documentación oficial Divi: https://www.elegantthemes.com/documentation/divi/

---

## Contexto de plataforma

Divi Theme (Elegant Themes) es un page builder basado en shortcodes y módulos
propietarios. Versión habitual en producción: **4.27.x**.

**Características clave con impacto SEO:**
- Renderizado **server-side (SSR)**: el contenido está en el HTML inicial. No es
  un SPA. Googlebot puede leer el contenido sin ejecutar JS. Señalarlo como positivo en auditorías.
- El CSS se genera dinámicamente por página (`et-dynamic-critical-css`) y se
  inyecta como bloques `<style>` inline de gran tamaño (habitualmente >200 KB).
- Los scripts Divi (core, popups, smooth scroll, fitvids) se cargan sin `async`
  ni `defer` por defecto.
- Los módulos Title/Heading de Divi **no generan H1 automáticamente** — usan
  `<div>` con clases propias salvo que se configure explícitamente la etiqueta HTML.

**Stack habitual:**
```
WordPress 6.x + Divi 4.27.x
+ Yoast SEO
+ WP Rocket o LiteSpeed Cache (cuando hay caché activa)
+ Plugin GDPR (Moove GDPR Cookie Compliance)
+ Ninja Forms (formularios de contacto)
+ Hosting: Plesk / cPanel / Nginx o Apache
```

---

## Issues recurrentes — Detección y solución

### H1 ausente o incorrecto (CRÍTICO — frecuencia: muy alta)

**Síntoma:** WebFetch no devuelve `<h1>` en el HTML, o devuelve H2 como primer
encabezado.

**Causa:** Divi Builder coloca el texto del módulo Title en un `<div>` o en la
etiqueta que asigne el módulo (normalmente H2). El H1 semántico no se genera
salvo que el editor lo configure manualmente.

**Verificación:**
```javascript
// Chrome DevTools > Console
document.querySelectorAll('h1,h2,h3,h4').forEach(h =>
  console.log(h.tagName, h.textContent.trim().slice(0,60))
)
```

**Solución en Divi:**
- Abrir la página en el Divi Builder
- Seleccionar el módulo que actúa como título principal
- Diseño > Configuración de texto > Etiqueta de encabezado: seleccionar `H1`
- Solo debe haber **un** H1 por página
- Repetir para cada página de servicio / landing importante

**Consecuencia si no se corrige:** Google no puede determinar el tópico
principal de la página → pérdida de relevancia temática.

---

### CSS inline masivo (CRÍTICO — CWV / LCP)

**Síntoma:** El `<head>` contiene bloques `<style>` de cientos de KB generados
por Divi.

**Causa:** El sistema de Dynamic CSS de Divi escribe los estilos de cada módulo
directamente en el HTML. Este CSS no puede ser cacheado por el navegador entre
páginas.

**Impacto:** Incremento de TTFB, LCP alto, CLS potencial, render-blocking.

**Solución:**
1. Divi > Opciones del tema > Velocidad de página > activar **"Critical CSS"** y
   **"Defer All JavaScript"**
2. Instalar plugin de caché con optimización CSS: WP Rocket, LiteSpeed Cache o
   W3 Total Cache
3. Si disponible en la versión instalada: activar el experimento
   **"Improved Asset Loading"** (carga solo el CSS de los widgets presentes en
   cada página, no el CSS global de todos los módulos)

**Patrón correcto de Divi (señalarlo como positivo si está implementado):**
```html
<link rel="preload" as="style" href="et-dynamic-critical-css.css"
      onload="this.onload=null;this.rel='stylesheet'">
```

---

### JS render-blocking (CRÍTICO — CWV / LCP + INP)

**Síntoma:** 10-20 scripts en el `<head>` o body temprano sin `async`/`defer`.

**Scripts habituales de Divi sin diferir:**
- `jquery.min.js` — jQuery core (**mantener síncrono** — Divi depende de él)
- `jquery-migrate.min.js`
- `scripts.min.js` (Divi core)
- `smoothscroll.js`
- `jquery.fitvids.js`
- `et-core-common.js`
- `sticky-elements.js`
- `ie-compat.min.js` + `front.min.js` (Divi Popups — diferibles)
- `moove_gdpr_frontend.js` — GDPR plugin (diferible)
- `front-end.js` / `front-end-deps.js` — Ninja Forms (diferible)

**Solución preferida:** WP Rocket o Asset CleanUp Pro para aplicar `defer` sin
tocar código.

**Solución PHP — diferir scripts específicos** (`functions.php` del child theme):
```php
// Fuente: WordPress developer.wordpress.org/reference/hooks/script_loader_tag/
// Hook: script_loader_tag(string $tag, string $handle, string $src) — WP 4.1+
add_filter('script_loader_tag', function($tag, $handle, $src) {
    if (is_admin()) return $tag;
    $defer_handles = [
        'moove_gdpr_frontend',
        'ninja-forms-front-end',
        'ninja-forms-front-end-deps',
        'ie-compat',          // Divi Popups
        'popups-for-divi',    // Divi Popups front
    ];
    if (in_array($handle, $defer_handles)) {
        return str_replace(' src', ' defer src', $tag);
    }
    return $tag;
}, 10, 3);
```

**Solución PHP — defer global excluyendo críticos:**
```php
add_filter('script_loader_tag', function($tag, $handle) {
    if (is_admin()) return $tag;
    // jQuery debe ser síncrono para Divi
    $exclude = ['jquery', 'jquery-core', 'jquery-migrate'];
    if (!in_array($handle, $exclude)) {
        $tag = str_replace('></script>', ' defer></script>', $tag);
    }
    return $tag;
}, 10, 2);
```

**Nota:** El shim IE (`html5.js`) puede eliminarse — IE está EOL desde 2022.

---

### Hero en CSS background-image (ALTO — LCP)

**Síntoma:** La imagen principal above-the-fold es un `background-image` en
estilo inline, no un `<img>` tag.

**Causa:** El módulo Section/Row de Divi usa `background-image` por defecto para
imágenes de fondo.

**Impacto:** El preload scanner del navegador no detecta la imagen hasta que
parsea el CSS → LCP elevado, especialmente en mobile.

**Solución A — preload manual en `<head>`:**
```html
<link rel="preload" as="image"
      href="/wp-content/uploads/[imagen-hero].jpg"
      fetchpriority="high">
```

**Solución B — via `wp_enqueue_scripts`** (`functions.php`):
```php
// Fuente: developer.wordpress.org/reference/functions/wp_enqueue_script/
add_action('wp_head', function() {
    if (is_front_page()) {
        echo '<link rel="preload" as="image" href="/wp-content/uploads/hero.jpg" fetchpriority="high">';
    }
}, 1);
```

**Solución C (ideal):** Convertir la sección hero a un módulo Image de Divi con
`<img>` real — el preload scanner lo detecta automáticamente. Añadir
`fetchpriority="high"` vía filtro o atributo personalizado en el módulo.

---

### Seguridad — exposición de stack (ALTO)

**Issues recurrentes en WordPress + Divi:**

| Issue | Causa | Solución |
|-------|-------|---------|
| `<meta name="generator" content="WordPress X.X">` | WordPress core | Ver snippet abajo |
| `X-Powered-By: PHP/X.X.X` | PHP config | `expose_php = Off` en php.ini |
| `X-Powered-By: PleskLin` | Plesk | Desactivar branding en Plesk > Herramientas > Branding |
| WP REST API público `/wp-json/` | WordPress core | Ver snippet abajo |
| `/wp-json/wp/v2/users` — user enumeration | REST API | Bloquear endpoint |
| `<link rel="pingback" href="">` | WordPress legacy | Ver snippet abajo |

**Snippet PHP — hardening en `functions.php`:**
```php
// Eliminar generator meta (WP + Divi)
// Fuente: developer.wordpress.org/reference/hooks/wp_head/
remove_action('wp_head', 'wp_generator');
remove_action('wp_head', 'xmlrpc_rsd');
remove_action('wp_head', 'wp_shortlink_wp_head');
remove_action('wp_head', 'pingback_url');
add_filter('the_generator', '__return_empty_string');

// Restringir REST API a usuarios autenticados
// Fuente: developer.wordpress.org/reference/hooks/rest_authentication_errors/
// Hook: rest_authentication_errors(WP_Error|null|true $errors) — WP 4.4+
add_filter('rest_authentication_errors', function($result) {
    if (!is_user_logged_in()) {
        return new WP_Error(
            'rest_not_logged_in',
            'API REST restringida.',
            ['status' => 401]
        );
    }
    return $result;
});
```

**Cabeceras de seguridad en `.htaccess` (Apache):**
```apache
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"
```

**Cabeceras en Nginx:**
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
fastcgi_hide_header X-Powered-By;
```

**CSP con Divi:** Divi y jQuery requieren `'unsafe-inline'` y `'unsafe-eval'`
para funcionar. Una CSP estricta no es viable en Divi 4.x. Señalarlo como
limitación de plataforma. Divi 5 introduce soporte de nonces (en desarrollo).

---

### Robots.txt — WordPress virtual vs físico

**WordPress genera robots.txt virtualmente** si no existe un archivo físico.
El contenido por defecto es mínimo. Para añadir reglas de AI crawlers o
rutas adicionales sin crear un archivo físico:

```php
// Fuente: developer.wordpress.org/reference/hooks/robots_txt/
// Hook: robots_txt(string $output, bool $public) — WP 3.0+
add_filter('robots_txt', function($output, $public) {
    if (!$public) return $output;
    $output .= "\n# AI Training Crawlers\n";
    $output .= "User-agent: GPTBot\nAllow: /\n\n";
    $output .= "User-agent: PerplexityBot\nAllow: /\n\n";
    $output .= "User-agent: CCBot\nDisallow: /\n\n";
    $output .= "User-agent: Bytespider\nDisallow: /\n\n";
    $output .= "User-agent: Google-Extended\nDisallow: /\n\n";
    return $output;
}, 99, 2);
```

**Nota:** Si existe archivo físico `robots.txt` en la raíz, WordPress ignora
este filtro. Verificar con `curl -I https://dominio.com/robots.txt`.

---

### Meta robots — control por página

```php
// Fuente: developer.wordpress.org/reference/hooks/wp_robots/
// Hook: wp_robots(array $robots) — WP 5.7+
// Noindex en una página específica por ID
add_filter('wp_robots', function($robots) {
    if (is_page(123)) { // ID de la página /gracias/
        $robots['noindex'] = true;
        unset($robots['follow']); // opcional
    }
    return $robots;
});
```

---

### Carga condicional de scripts de plugins

Ninja Forms y plugins similares cargan CSS/JS en **todas las páginas** aunque
solo haya formularios en una. Carga condicional con `wp_enqueue_scripts`:

```php
// Fuente: developer.wordpress.org/reference/functions/wp_enqueue_script/
// wp_enqueue_script($handle, $src, $deps, $ver, $args)
// $args acepta: strategy ('defer'/'async'), in_footer, fetchpriority — WP 6.3+
add_action('wp_enqueue_scripts', function() {
    // Desencolar Ninja Forms en páginas sin formulario
    if (!is_page('contacto') && !is_page('presupuesto')) {
        wp_dequeue_script('ninja-forms-front-end');
        wp_dequeue_script('ninja-forms-front-end-deps');
        wp_dequeue_style('ninja-forms-display-structure');
    }
    // Desencolar Dashicons en frontend (solo necesario en admin)
    wp_deregister_style('dashicons');
}, 100); // prioridad alta para ejecutar después de los enqueues de plugins
```

---

### Jerarquía de encabezados rota (MEDIO)

**Síntoma:** Páginas con H2 como primer encabezado visible, o saltos H1 → H3.

**Causa:** Como Divi no genera H1 automáticamente, la jerarquía habitual es
H2 → H3 → H4 sin H1.

**Alcance:** Auditar todas las páginas de servicios/productos, no solo la homepage.

---

### IndexNow no implementado (MEDIO)

**Síntoma:** No existe archivo `[key].txt` en la raíz del dominio.

**Solución con Yoast SEO (v21+):**
- SEO > General > Crawl Optimization > IndexNow > Activar
- Yoast genera el archivo de clave automáticamente

**Verificación:** `curl https://dominio.com/[clave-yoast].txt` debe devolver la clave.

---

### Sitemap — páginas de utilidad indexadas (MEDIO)

**Páginas habituales a excluir del sitemap:**
- `/gracias/` (thank-you pages de formularios)
- `/mapa-del-sitio/` (HTML sitemap)
- `/politica-de-cookies/`
- `/aviso-legal/`
- `/politica-de-privacidad/`

**Cómo excluir en Yoast:** Página > SEO > Avanzado > Indexación: "No"

**Issue relacionado:** `post_tag-sitemap.xml` genera páginas de tag de baja
calidad. Si no aportan valor: Yoast > Apariencia en búsquedas > Taxonomías >
Post Tags > No mostrar en resultados.

**Robots.txt redundante:** Si `robots.txt` lista tanto `sitemap_index.xml` como
sub-sitemaps hijos, eliminar los hijos — el índice ya los incluye.

---

### URLs de blog largas (BAJO)

**Causa:** Divi no impone límite en el slug del post.
**Umbral:** flag si >100 caracteres.
**Solución:** Nueva URL corta + 301 redirect + actualizar canonical.

---

### Viewport `user-scalable=0` (CRÍTICO si está presente)

**Síntoma:** `<meta name="viewport" content="..., user-scalable=0">`

**Impacto:** Falla Mobile Usability en GSC + viola WCAG 2.1 SC 1.4.4.
Relevante desde que mobile-first indexing es universal (julio 2024).

**Solución:** `<meta name="viewport" content="width=device-width, initial-scale=1.0">`

En Divi: Divi > Opciones del tema > General > Diseño responsive > editar el
valor del viewport meta.

---

## Optimización de rendimiento WordPress — referencia oficial

Fuente: `developer.wordpress.org/advanced-administration/performance/optimization/`

**Prioridades por tipo de hosting:**

| Hosting | Acciones prioritarias |
|---------|-----------------------|
| Compartido | Plugin de caché + optimización WP + CDN |
| VPS/Dedicado | Varnish + optimización servidor + CDN |

**Object cache:** Para sitios con tráfico alto, añadir Memcached o Redis reduce
consultas a base de datos. Clave para sites con WooCommerce en Divi.

**Autoloaded options:** Mantener bajo 800 KB. Plugins mal desarrollados acumulan
opciones autoloaded. Verificar con:
```sql
SELECT option_name, LENGTH(option_value) as size
FROM wp_options WHERE autoload='yes'
ORDER BY size DESC LIMIT 20;
```

---

## Checklist de auditoría técnica para sitios Divi

```
CRÍTICO
[ ] H1 presente y correcto en homepage y páginas principales
[ ] Jerarquía H1>H2>H3 sin saltos en páginas de servicio
[ ] Viewport: sin user-scalable=0
[ ] CSS inline: tamaño de bloques <style> en <head>
[ ] JS sin async/defer: listar scripts bloqueantes
[ ] Hero image: ¿es background-image CSS o <img> tag?
[ ] LCP image tiene fetchpriority="high" o preload link

ALTO
[ ] <meta name="generator"> eliminado
[ ] X-Powered-By eliminado de cabeceras HTTP
[ ] WP REST API restringido (/wp-json/wp/v2/users bloqueado)
[ ] Pingback link eliminado
[ ] Security headers: HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy
[ ] CSP presente (anotar limitación Divi + unsafe-inline si aplica)
[ ] OG image: presente y ≥1200×630px (no logos pequeños)
[ ] Twitter Card completa (title + description + image)
[ ] Open Graph activado en Yoast

MEDIO
[ ] IndexNow activo (Yoast v21+ o plugin)
[ ] Sitemap: páginas legales/utilidad con noindex y excluidas
[ ] Sitemap: post_tag verificado (¿genera index bloat?)
[ ] Robots.txt: política de AI crawlers definida
[ ] Ninja Forms / GDPR plugin: ¿cargan JS/CSS en todas las páginas?
[ ] Dashicons: ¿se cargan en frontend?

BAJO
[ ] URLs de blog: flag si >100 caracteres
[ ] html5.js IE shim: eliminar si presente
[ ] Robots.txt: sin sub-sitemaps redundantes si ya están en sitemap_index.xml
[ ] Autoloaded options: verificar si >800 KB
```

---

## Positivos habituales en sitios Divi bien configurados

- SSR confirmado: contenido visible sin JS (ventaja directa frente a SPAs)
- Divi Dynamic CSS con patrón preload correcto (`rel="preload" as="style" onload`)
- Canonical self-referencing presente en HTML inicial (no inyectado por JS)
- xmlrpc.php devuelve 404 (XML-RPC desactivado)
- Yoast schema graph completo (WebPage, WebSite, BreadcrumbList)
- HTTPS enforced con redirect 301 HTTP → HTTPS
- Cookies con `SameSite=Strict` y `Secure`

---

## Referencias rápidas — Rutas de configuración

**Divi:**
- Performance Settings: Divi > Opciones del tema > Velocidad de página
- Etiqueta H1 en módulo: módulo > Diseño > Configuración de texto > Etiqueta de encabezado
- Viewport meta: Divi > Opciones del tema > General > Diseño responsive
- Improved Asset Loading: Divi > Opciones del tema > Builder > Experimentos

**Yoast SEO:**
- Open Graph: SEO > Apariencia en búsquedas > Compartir en redes sociales
- IndexNow: SEO > General > Crawl Optimization
- Noindex página: Página > SEO > Avanzado > Indexación: "No"
- Excluir tags del sitemap: SEO > Apariencia en búsquedas > Taxonomías > Post Tags

**WordPress core (hooks documentados):**
- `script_loader_tag` — async/defer en scripts (WP 4.1+): https://developer.wordpress.org/reference/hooks/script_loader_tag/
- `wp_robots` — control meta robots por página (WP 5.7+): https://developer.wordpress.org/reference/hooks/wp_robots/
- `rest_authentication_errors` — restringir REST API (WP 4.4+): https://developer.wordpress.org/reference/hooks/rest_authentication_errors/
- `robots_txt` — modificar robots.txt virtual (WP 3.0+): https://developer.wordpress.org/reference/hooks/robots_txt/
- `wp_head` — insertar meta tags en `<head>`: https://developer.wordpress.org/reference/hooks/wp_head/
- `wp_enqueue_scripts` — carga condicional de scripts: https://developer.wordpress.org/reference/functions/wp_enqueue_script/
