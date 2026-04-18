# SEO Skills for Claude Code

Custom knowledge base for technical SEO audits. Each skill is a Markdown file
that Claude Code loads automatically when the relevant topic is invoked.

Built from real audit patterns across WordPress, PrestaShop, and analytics
stacks. All knowledge is anonymized and RGPD compliant — no client data.

---

## Skills

### CMS — WordPress + Divi

**File:** `skills/wordpress-divi/SKILL.md`

Covers WordPress sites built with Divi Theme (Elegant Themes) 4.27.x.

- **H1 ausente** — Divi no genera H1 automáticamente. Fix: módulo > Diseño > Etiqueta de encabezado
- **CSS inline masivo** — Dynamic CSS de Divi inyecta cientos de KB por página. Fix: Critical CSS + Improved Asset Loading
- **JS render-blocking** — 10-20 scripts sin `async`/`defer`. Snippets PHP con hook `script_loader_tag` (WP 4.1+) para diferir por handle, con exclusión de jQuery
- **Hero como CSS background-image** — invisible para el preload scanner. Fix: `<link rel="preload">` o convertir a `<img>` real
- **Seguridad** — `<meta generator>`, `X-Powered-By`, REST API abierto, user enumeration, pingback. Snippets PHP con hooks `wp_robots` (WP 5.7+) y `rest_authentication_errors` (WP 4.4+)
- **Robots.txt virtual** — WordPress genera robots.txt sin archivo físico. Hook `robots_txt` (WP 3.0+) para añadir reglas de AI crawlers
- **Carga condicional** — Ninja Forms, Dashicons y plugins GDPR cargan en todas las páginas. Fix: `wp_enqueue_scripts` con prioridad 100+
- Checklist de auditoría por criticidad + positivos habituales + rutas de configuración Divi/Yoast

---

### CMS — WordPress + Elementor

**File:** `skills/wordpress-elementor/SKILL.md`

Covers WordPress sites built with Elementor (free y Pro), incluyendo stacks con WP Rocket y WooCommerce.

- **LCP hero lazy-loaded** — Elementor y WP Rocket reemplazan `src` con SVG placeholder. `fetchpriority="high"` queda inútil aunque esté presente. Fix: `e-no-lazyload`, excluir en WP Rocket > Media > LazyLoad
- **fetchpriority en elemento incorrecto** — asignado a imágenes decorativas (separadores, dividers) en lugar de la imagen LCP real
- **CSS/JS excesivos** — 40-90+ recursos. Fix: Improved Asset Loading (Elementor > Settings > Performance)
- **HTML payload masivo** — WP Rocket inyecta `RocketLazyLoadScripts` y `elementorFrontendConfig` inline. Observado hasta 1.4 MB
- **Elementor lazy load en backgrounds** — `.e-con.e-parent:nth-of-type(n+4)` oculta backgrounds de secciones 4+ hasta que JS las marca. Causa CLS
- **Security headers ausentes** — patrón consistente. Snippets para Nginx y Apache
- **Exposición de versiones** — Elementor en meta generator. PHP snippet para eliminarlo
- **REST Link header** — expone IDs internos de WordPress. Fix: `remove_action('template_redirect', 'rest_output_link_header', 11)`
- **DOM size** — Section/Column (4 divs) vs Containers Flexbox (2 divs). Fix: Elementor > Tools > Converter
- **WooCommerce** — BreadcrumbList duplicado (Yoast + Schema Pro), FAQPage sin rich results en e-commerce desde 2023, Product schema ausente, `/mi-cuenta/` en sitemap
- **PHP EOL** — 7.4 EOL desde nov 2022. Fix: actualizar en hPanel/cPanel/Plesk
- **Canibalización en páginas de localización** — Elementor facilita duplicar templates por ciudad
- Checklist de auditoría por criticidad + positivos habituales + rutas de configuración

---

### CMS — PrestaShop

**File:** `skills/prestashop-seo/SKILL.md`

Covers PrestaShop 1.7.x / 8.x, incluyendo stacks con CreativeElements y Nginx/Plesk.

- **sitemap.xml 404** — PrestaShop genera el sitemap en `/1_index_sitemap.xml`. La ruta estándar no existe por defecto. Fix: redirect 301 en Nginx o .htaccess
- **Cache-Control: no-store** — desactivado por defecto en todas las páginas HTML. Fix: CCC en Advanced Parameters > Performance (Smart cache CSS/JS, Minify HTML, Move JS to end)
- **URLs con ID numérico** — `/217-slug` es estándar de PrestaShop. No es un error si el canonical apunta a la URL con ID. Migración requiere plan de redirects
- **Controllers en sitemap** — CreativeElements y módulos de sitemap incluyen endpoints AJAX internos. Fix: excluir desde el módulo o bloquear en robots.txt
- **PHPSESSID con expiración de décadas** — RGPD/ePrivacy. Fix: `session.cookie_lifetime = 0` en php.ini
- **OG tags ausentes** — PrestaShop no los genera por defecto. Snippets Smarty para head.tpl
- **Hero como background-image** — sliders nativos y CreativeElements. Fix: hook `displayHeader` para inyectar preload
- **Seguridad** — headers Nginx, CSP en report-only mode, `expose_php = Off`
- **Schema Product + Offer** — generado nativamente en PS8 si está habilitado. AggregateRating requiere módulo de valoraciones
- **IndexNow** — implementación via hook `actionObjectProductUpdateAfter`
- Tabla de rutas del backoffice + checklist por criticidad + positivos habituales

---

### Tracking — Google Tag Manager

**File:** `skills/google-tag-manager/SKILL.md`

Debugging y configuración de GTM, con foco en el caso "evento que no llega a GA4".

- **Árbol de diagnóstico** — 7 pasos ordenados: tag pausado → trigger restrictivo → Preview Mode → Consent Mode → firing order → Measurement ID → DebugView
- **Preview vs Producción** — Preview bypasa ad blockers y Consent Mode. Testear siempre en incógnito. `?gtm_debug=x` para debug en entorno real
- **dataLayer** — estructura, naming rules, eventos reservados de GA4, cómo leer el dataLayer en consola y en la pestaña Preview
- **Consent Mode v2** — obligatorio EEE desde marzo 2024. `analytics_storage: denied` bloquea GA4 tags. Diferencia Basic vs Advanced Consent Mode. Snippets de default + update
- **Firing order** — GA4 Configuration Tag debe disparar en "Initialization - All Pages" antes que los Event Tags. Tag Sequencing para garantizarlo. Jerarquía completa de triggers
- **DebugView** — cómo activarlo vía GTM, Chrome Extension o URL param
- **Casos frecuentes** — formularios AJAX vs submit tradicional, Contact Form 7 (`wpcf7mailsent`), Elementor Forms, clicks en `tel:` y `mailto:`
- Verificación de instalación del container vía consola y Network tab

---

### Tracking — GA4 Analysis

**File:** `skills/ga4-analysis/SKILL.md`

Análisis de datos GA4 para auditorías SEO, con foco en adquisición orgánica vs pagada.

- **Diferencias UA → GA4** — sesiones vs eventos, bounce rate vs engagement rate, goals vs conversions, sampling vs BigQuery
- **Orgánico vs pagado** — channel groups, cómo aislar Organic Search, por qué UTMs mal configurados inflan el orgánico
- **Modelos de atribución** — Data-driven (default), Last click, First click, Linear, Time decay. Lookback windows. Por qué GA4 y Google Ads muestran cifras distintas
- **Engagement** — definición de engaged session (≥10s o ≥2 páginas o conversión), diferencia con bounce rate de UA
- **Integración GSC** — Reports > Acquisition > Search Console. Limitación: solo sesiones donde GA4 registró la visita
- **Integración Google Ads** — remarketing audiences, importación de conversiones, análisis orgánico vs pagado side-by-side
- **DebugView** — activación, latencia, validación de parámetros
- **Informes útiles para SEO** — organic landing pages, organic queries, páginas con alta tasa de rebote orgánico
- **Errores comunes** — tráfico de pago en Organic, self-referral, sesiones infladas, conversiones duplicadas, tráfico directo excesivo
- Exportación a BigQuery, dimensiones y métricas clave

---

### Herramienta — SE Ranking

**File:** `skills/se-ranking/SKILL.md`

Interpretación de datos de SE Ranking en el contexto de auditorías SEO.

- **Rank tracking** — volatilidad normal (±3) vs caída real (>5 posiciones sostenida 7+ días) vs caída brusca (posible update). Árbol de diagnóstico antes de actuar
- **SERP Features** — posición 4 con Featured Snippet puede superar a posición 1 sin feature en CTR real
- **Site Audit** — es un crawler estático (sin JS rendering). Issues = señales, no conclusiones. Tabla de priorización: alta/media/baja prioridad según impacto real
- **Falsos positivos documentados** — H1 missing en Divi/Elementor, duplicate content por paginación, broken links en JS, meta description dinámica
- **Estimación de tráfico** — margen de error ±40-60%. Usar como tendencia, no como cifra absoluta. Comparativa con GA4 y GSC
- **Keyword research** — flujo recomendado desde seed keywords hasta asignación por intent. Diferencias de volumen entre SE Ranking, Semrush y Google Ads
- **Competitor analysis** — Share of Voice, Keyword Gap, cuándo usar Semrush para discovery y SE Ranking para seguimiento preciso
- Integración con GSC, Screaming Frog y Semrush

---

### Herramienta — Screaming Frog

**File:** `skills/screaming-frog/SKILL.md`

Uso técnico de Screaming Frog SEO Spider en auditorías.

- **Spider vs JS Rendering** — Spider: rápido, no ejecuta JS. JS Rendering: usa Chromium, 5-10x más lento, obligatorio en Divi/Elementor. Crawl selectivo por lista de URLs para sitios grandes
- **Configuración por CMS** — WordPress (exclusiones wp-admin, feeds, búsquedas; timeout JS 10s) y PrestaShop (parámetros de sesión/moneda/idioma a excluir; header Accept-Language)
- **Reports clave** — Response Codes (redirects 302→301, 404 enlazados, 500), Page Titles (missing, duplicate, longitud), Meta Description, H1 (missing, multiple), Canonicals (apuntando a 404, sin canonical), Directives (noindex no intencional), Images (alt text, peso)
- **Páginas huérfanas** — Bulk Export > All Inlinks. Páginas sin enlaces internos que rankean en SE Ranking = oportunidad de mejora de PageRank interno
- **Integración** — GSC (columnas de impresiones/clics en crawl), GA4 (sesiones por URL), PSI (solo en crawl selectivo)
- **Falsos positivos** — H1 missing en Divi/Elementor, duplicate content en paginación sin canonical, broken links en modales JS, slow page sin caché CDN, images missing alt en CSS backgrounds
- **Performance** — tabla de tiempo estimado por tamaño de sitio y modo de crawl. RAM mínima 8GB para JS rendering

---

### Herramienta — Semrush

**File:** `skills/semrush/SKILL.md`

Uso e interpretación de Semrush como herramienta complementaria en el stack de auditoría.

- **Organic Research** — distribución de posiciones (top 3 / 4-10 / 11-100), top páginas, tendencia histórica, branded vs non-branded. Precisión: ±40%, usar como tendencia
- **Keyword Gap** — Missing (mayor oportunidad), Weak (mejorar posición), Untapped (validar demanda). Intents: Informational, Navigational, Commercial, Transactional
- **Backlink Gap** — dominios que enlazan a competidores pero no al cliente. Filtrar por Authority Score >30
- **Site Audit** — crawler básico. En el flujo de auditor�a, Screaming Frog es el crawler principal. Semrush Site Audit como check secundario
- **Traffic Analytics** — estimación de tráfico total (no solo orgánico). Útil para comparativa de canales con competidores. No usar como cifra real
- **Authority Score** — métrica propia, no PageRank. Tabla de rangos. Usar como referencia comparativa, no como objetivo
- **SE Ranking vs Semrush** — SE Ranking para seguimiento preciso de keywords definidas, Semrush para discovery del dominio completo. Flujo: Semrush descubre → SE Ranking rastrea
- **Por qué las posiciones difieren** — fecha de medición, datacenter, localización de la solicitud
- Exports útiles, limitaciones a comunicar al cliente

---

### Técnico — robots.txt

**File:** `skills/robots-txt/SKILL.md`

Especificación técnica completa y plantillas por tipo de sitio, con foco en Google Merchant Center.

- **Especificación Google** — precedencia Allow/Disallow (gana la regla más larga), matching de user-agent (específico no hereda de `*`), wildcards `*` y `$`, AdsBot fuera del wildcard `*`
- **Merchant Center** — tabla de errores de MC y su causa en robots.txt, solución oficial (Googlebot + Googlebot-image con `Disallow:` vacío), directivas del bloque `*` que causan desaprobaciones
- **Plantillas** — sitio informativo/blog, e-commerce sin MC, e-commerce con MC (con sección "qué NO incluir")
- **Governance de IA** — tabla de bots de entrenamiento (bloquear) vs bots de búsqueda IA (permitir). Diferencia entre GPTBot y ChatGPT-User
- **Errores comunes** — `Disallow: /*?` sin bloque Googlebot, `*.php` bloqueando admin-ajax, sitemap con dominio incorrecto, AdsBot no gestionado, wildcard al inicio de path
- **WordPress** — cómo editar: plugin SEO, archivo físico, hook PHP
- Checklist de evaluación por criticidad (crítico / alto / medio / bajo)

---

## Instalación

Copia cualquier carpeta de skill a `~/.claude/skills/[nombre]/SKILL.md`.
Claude Code las carga automáticamente desde ese directorio.

## Privacidad

Todo el conocimiento está anonimizado. Sin nombres de clientes, dominios ni
datos identificables. Conforme con RGPD.

## Contribuir

Enriquecer las skills con patrones reales a medida que aparecen nuevos issues.
Regla: el conocimiento entra anonimizado — el patrón importa, no la fuente.
