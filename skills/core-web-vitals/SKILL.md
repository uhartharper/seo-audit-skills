---
name: core-web-vitals
description: >
  Core Web Vitals diagnosis and optimization: LCP, CLS, INP, and TTFB.
  Covers field data vs lab data, CrUX interpretation, diagnostic tree per metric,
  and CMS-specific fixes for WordPress (Divi, Elementor, WP Rocket), PrestaShop,
  and Shopify. Use when analyzing CWV scores, diagnosing performance issues, or
  implementing optimizations to improve LCP, CLS, or INP.
---

# Core Web Vitals — Technical SEO

> Based on Google's CWV specification and field observations across WordPress,
> PrestaShop, and Shopify sites.
> Official reference: https://web.dev/explore/metrics

---

## Thresholds and scoring

| Metric | Good | Needs improvement | Poor |
|--------|------|------------------|------|
| LCP | ≤ 2.5s | 2.5s – 4.0s | > 4.0s |
| CLS | ≤ 0.1 | 0.1 – 0.25 | > 0.25 |
| INP | ≤ 200ms | 200ms – 500ms | > 500ms |
| TTFB | ≤ 800ms | 800ms – 1800ms | > 1800ms |

**Pass threshold for Google ranking signal:** 75% of page loads must be in
the "Good" range. Measured at the page URL level (not site average).

---

## Field data vs lab data

**Field data (CrUX):** Real user measurements from Chrome users. Used by Google
for ranking. Visible in Google Search Console > Core Web Vitals and PageSpeed
Insights > Field Data section.

**Lab data:** Synthetic test from a controlled environment. PageSpeed Insights
Lighthouse section, WebPageTest, Chrome DevTools. Useful for debugging but
does not directly represent what Google measures.

**Key conflict:** A page can pass in lab but fail in field (or vice versa).
- Lab fails, field passes: lab simulates slower device/connection than real users.
- Field fails, lab passes: users arrive at the page via a navigation that lab
  does not simulate (e.g., soft navigation in SPA, warm cache state).

**Rule:** Always check field data first. If field data is unavailable (low traffic),
lab data is the proxy — but state that explicitly.

**CrUX minimum traffic threshold:** A URL needs approximately 500+ visits/month
in Chrome for Google to collect field data. Below this, the URL may show "No data"
in GSC CWV report — this is not a pass, it is an absence of data.

---

## LCP — Largest Contentful Paint

### What it measures

The time from navigation start until the largest visible content element
(image, video poster, or block-level text) is rendered in the viewport.

### Common LCP elements

- Hero image (`<img>` tag or `<picture>`)
- CSS background-image on a section/container (invisible to preload scanner)
- H1 text block (if no image above the fold)
- Video poster image

### Diagnostic tree

```
1. What is the LCP element?
   PSI > Lab > "LCP element" in Diagnostics section.
   Or: Chrome DevTools > Performance tab > LCP marker > hover to see element.

2. Is it an image or text?
   Image → go to step 3.
   Text → LCP is dominated by font loading or render-blocking CSS. See TTFB + CSS.

3. Is the image loaded with <img src> or CSS background-image?
   CSS background → preload scanner cannot discover it. Add <link rel="preload">.
   <img src> → go to step 4.

4. Is the image lazy-loaded?
   Check for class="lazyload", data-src, or loading="lazy" on the element.
   Lazy load on LCP image = critical error. Remove it.

5. Does the image have fetchpriority="high"?
   No → add it to the <img> tag of the LCP element.
   Yes + still slow → TTFB or server response time is the bottleneck.

6. Is there a preload hint in <head>?
   <link rel="preload" as="image" href="..." fetchpriority="high">
   Adding this for the LCP image reduces discovery time by 200-500ms.

7. Is the image served from CDN?
   No CDN → first byte comes from origin server. Focus on TTFB.
   CDN present → check if the LCP image specifically is on CDN path.

8. What is the image format and file size?
   JPEG/PNG > 200KB → compress. Target: < 100KB for hero images above the fold.
   Already WebP/AVIF < 100KB → focus shifts to connection and server.
```

### Top LCP killers and fixes

**Lazy-loaded LCP image**

```html
<!-- Wrong -->
<img data-src="hero.jpg" class="lazyload" loading="lazy">

<!-- Correct -->
<img src="hero.jpg" loading="eager" fetchpriority="high">
```

**CSS background-image as LCP element**

```html
<!-- In <head>, add: -->
<link rel="preload" as="image" href="/images/hero.jpg" fetchpriority="high">
```

**fetchpriority on wrong element**

Only one element should have `fetchpriority="high"` — the LCP element.
If it is set on a decorative icon or separator, move it to the hero image.

**Unoptimized image format**

Target for LCP hero images: WebP or AVIF, < 100KB, with correct `width` and `height`
attributes to prevent CLS.

**Render-blocking CSS delaying image render**

Every stylesheet in `<head>` without `media` attribute delays first paint.
Minimize render-blocking CSS by inlining critical CSS and deferring non-critical.

---

## CLS — Cumulative Layout Shift

### What it measures

The sum of all unexpected layout shift scores during the page lifecycle.
A layout shift occurs when a visible element changes its start position.

### CLS score calculation

`layout shift score = impact fraction × distance fraction`

Elements that shift 50% of the viewport by 25% of the viewport height
= 0.5 × 0.25 = 0.125 (already above the 0.1 threshold).

### Common CLS causes

**Images without dimensions**

```html
<!-- CLS: browser does not know the space to reserve -->
<img src="product.jpg" alt="Product">

<!-- No CLS: browser reserves correct space before image loads -->
<img src="product.jpg" alt="Product" width="800" height="600">
```

**CSS aspect-ratio alternative:**
```css
img {
  aspect-ratio: 4 / 3;
  width: 100%;
  height: auto;
}
```

**Web fonts causing FOUT / FOIT**

Font swap causes text reflow when the web font loads.
Fix: `font-display: swap` in `@font-face` declaration.
Better fix for CLS: `font-display: optional` (uses fallback if font not cached).

**Dynamic content injected above existing content**

Ad slots, cookie banners, and dynamic widgets that push content down cause CLS.
Fix: reserve space with `min-height` on the container before content loads.

**Elementor lazy-loaded backgrounds**

Elementor injects CSS that hides section backgrounds until JavaScript marks them:
```css
.e-con.e-parent:nth-of-type(n+4):not(.e-lazyloaded):not(.e-no-lazyload) {
  background-image: none !important;
}
```
When JS fires, the background appears → layout shift.
Fix: add `e-no-lazyload` class to sections visible above the fold.

**Cookie consent banners**

Banners that insert themselves above page content shift all content down.
Fix: reserve space for the banner with a fixed-height placeholder, or use
a cookie banner that overlays content without shifting the document flow.

---

## INP — Interaction to Next Paint

### What it measures

The worst interaction latency (click, tap, keyboard input) recorded during
the full page visit, at the 98th percentile.

Replaced FID (First Input Delay) as a Core Web Vitals metric in March 2024.
FID only measured the delay before the event handler ran; INP measures the
full time until the next frame is painted after the interaction.

### Common INP causes

**Long tasks on the main thread**

Any JavaScript task running > 50ms blocks the main thread and delays
the response to user interactions.

Detect: Chrome DevTools > Performance > record an interaction > look for
long tasks (red triangles) in the Main thread lane.

**Third-party scripts**

GTM, Facebook Pixel, chat widgets, and analytics scripts that execute on
the main thread compete with interaction handlers. A Pixel script that takes
200ms to run during a click adds directly to INP.

**Large DOM size**

DOM > 1,400 nodes increases rendering time per interaction. Browsers must
recalculate styles and layout for a larger subtree.

**Inefficient event handlers**

Event handlers that trigger synchronous layout reads (`getBoundingClientRect`,
`offsetWidth`, `scrollTop`) followed by DOM writes cause forced reflows.

### Fixes

- Break long tasks with `setTimeout(fn, 0)` or `scheduler.yield()`
- Defer non-critical third-party scripts to after `window.load`
- Use `content-visibility: auto` to skip rendering of off-screen content
- Reduce DOM size (Elementor: migrate Sections → Containers)
- Move third-party scripts to a web worker (Partytown — experimental)

---

## TTFB — Time to First Byte

TTFB is not a Core Web Vital but it is the foundation. LCP cannot be ≤ 2.5s
if TTFB is > 1s, because LCP starts counting from navigation start.

`LCP = TTFB + connection setup + resource load + rendering`

### TTFB diagnostic tree

```
1. Is TTFB > 800ms in field data?
   Use: GSC > Core Web Vitals > group by URL, then check PSI for field TTFB.

2. Is it consistent across pages or only on specific URLs?
   All pages slow → server/hosting problem.
   Only specific pages → heavy PHP/database queries on those pages.

3. Is there server-side caching?
   WordPress: WP Rocket / LiteSpeed Cache page cache?
   PrestaShop: Smarty cache enabled? CCC active?
   No cache → first visit generates a full PHP render. Fix: enable page cache.

4. Is there a CDN?
   No CDN → all requests go to origin server.
   CDN but TTFB still high → check if HTML is being cached by CDN or only assets.

5. What is the hosting type?
   Shared hosting → TTFB variance 200ms–3s common. Upgrade is often the only fix.
   VPS/cloud → tune PHP-FPM workers, enable OPcache, add Redis/Memcached.
```

### TTFB fixes

**Enable OPcache (PHP)**
```ini
; php.ini
opcache.enable = 1
opcache.memory_consumption = 256
opcache.max_accelerated_files = 20000
opcache.validate_timestamps = 0  ; production only
```

**WordPress page cache**
- WP Rocket: enable page caching (Settings > Cache)
- LiteSpeed Cache: Page Cache > On
- W3 Total Cache: Page Cache > Disk Enhanced

**PrestaShop**
- Advanced Parameters > Performance > Smarty cache: Enabled
- Caching Type: File system
- "Never recompile template files" in production

**CDN for HTML**
Most CDNs cache only assets (CSS, JS, images) by default. Configure edge caching
for HTML responses with short TTL (1–5 minutes) for near-instant TTFB from CDN.
Careful: bypass CDN cache for logged-in users and cart/checkout pages.

---

## CWV by CMS

### WordPress + Divi

| Issue | Impact | Fix |
|-------|--------|-----|
| Massive inline CSS (>200 KB) | LCP delayed by render-blocking inline styles | Enable "Critical CSS" + "Improved Asset Loading" in Divi |
| Hero as CSS background | LCP image not discoverable | `<link rel="preload">` in child theme |
| jQuery without defer | TBT high → INP degraded | PHP `script_loader_tag` hook to defer by handle |
| Divi Builder files on every page | 15+ scripts global | Conditional enqueue by page template |

### WordPress + Elementor

| Issue | Impact | Fix |
|-------|--------|-----|
| LCP hero lazy-loaded | LCP critical | `e-no-lazyload` class or `data-no-lazyload` attribute |
| WP Rocket replaces src with SVG | fetchpriority useless | Exclude hero from WP Rocket lazy load |
| HTML payload > 500KB | TTI / INP | Improved Asset Loading + reduce widgets per page |
| `.e-con:nth-of-type(n+4)` background hidden | CLS when JS fires | `e-no-lazyload` on visible sections |
| Section/Column DOM (4 divs each) | INP (large DOM) | Migrate to Containers (2 divs each) |

### PrestaShop

| Issue | Impact | Fix |
|-------|--------|-----|
| `Cache-Control: no-store` default | TTFB on every visit | Enable CCC in Advanced Parameters > Performance |
| 30-50 CSS/JS files without CCC | LCP blocked | Enable Smart Cache CSS/JS in CCC |
| Hero slider as background-image | LCP not preloaded | `displayHeader` hook to inject `<link rel="preload">` |
| Google Fonts external | LCP delayed by font load | Self-host fonts or add `font-display: swap` |

### Shopify

| Issue | Impact | Fix |
|-------|--------|-----|
| Theme-bundled app scripts | INP degraded | Audit installed apps, remove unused |
| Large theme CSS (>300KB) | LCP delayed | Use Shopify CLI to split CSS |
| Product images not lazy-loaded below fold | Resource contention | Shopify natively lazy-loads below-fold images in recent themes |

---

## Measurement tools

| Tool | Data type | When to use |
|------|-----------|-------------|
| PageSpeed Insights | Field (CrUX) + Lab (Lighthouse) | Primary check per URL |
| Google Search Console > CWV | Field (CrUX) grouped | Site-wide status, finding failing URL groups |
| Chrome DevTools > Performance | Lab | Deep diagnosis of LCP element, long tasks |
| WebPageTest | Lab (multiple locations) | Waterfall analysis, CDN validation |
| CrUX Dashboard (Data Studio) | Field (historical) | Trend tracking |
| Chrome UX Report (BigQuery) | Field (raw data) | Programmatic analysis |

---

## Diagnostic commands — CWV live

### PageSpeed Insights API — lab + field data por URL

```bash
curl "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=https://example.com/&strategy=mobile&key=YOUR_API_KEY"
```

Parámetros clave:
- `strategy`: `mobile` (default y más relevante para Google) o `desktop`
- `key`: API key de Google Cloud Console (proyecto con PageSpeed Insights API habilitada)

El response JSON incluye:
- `lighthouseResult.categories.performance.score` — puntuación Lighthouse (lab)
- `loadingExperience.metrics` — datos de campo CrUX si hay suficiente tráfico
- `lighthouseResult.audits.largest-contentful-paint` — LCP medido en lab
- `lighthouseResult.audits.cumulative-layout-shift` — CLS
- `lighthouseResult.audits.experimental-interaction-to-next-paint` — INP

Sin API key funciona pero con rate limit muy bajo (no usar en batch).

### Comparar móvil vs desktop

```bash
# Móvil
curl -s "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=https://example.com/&strategy=mobile" | python3 -c "import sys,json; d=json.load(sys.stdin); print('LCP:', d['lighthouseResult']['audits']['largest-contentful-paint']['displayValue'])"

# Desktop
curl -s "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=https://example.com/&strategy=desktop" | python3 -c "import sys,json; d=json.load(sys.stdin); print('LCP:', d['lighthouseResult']['audits']['largest-contentful-paint']['displayValue'])"
```

---

## Audit checklist

```
LCP
[ ] LCP element identified (PSI Diagnostics)
[ ] LCP image loaded with <img src>, not CSS background-image
[ ] LCP image NOT lazy-loaded (no loading="lazy", no data-src, no class="lazyload")
[ ] fetchpriority="high" on LCP element
[ ] <link rel="preload"> for LCP image in <head>
[ ] LCP image < 100KB (WebP or AVIF preferred)
[ ] No render-blocking resources delaying LCP (PSI "Eliminate render-blocking resources")
[ ] TTFB < 800ms (PSI Field Data)

CLS
[ ] All images have explicit width + height attributes (or aspect-ratio CSS)
[ ] Web fonts use font-display: swap or optional
[ ] No dynamic content injected above existing content without reserved space
[ ] Cookie banner reserves space or overlays without shifting content
[ ] Elementor: above-fold sections have e-no-lazyload class (no background shift)

INP
[ ] No long tasks > 200ms on main thread during interaction (DevTools Performance)
[ ] Third-party scripts deferred or loaded after window.load where possible
[ ] DOM size < 1,400 nodes (Lighthouse "Avoid an excessive DOM size")
[ ] Event handlers do not cause forced reflows

FIELD DATA
[ ] PSI field data available (sufficient traffic to CrUX)
[ ] GSC CWV report checked for failing URL groups
[ ] Field LCP "Good" (≤ 2.5s) for 75% of visits
[ ] Field CLS "Good" (≤ 0.1) for 75% of visits
[ ] Field INP "Good" (≤ 200ms) for 75% of visits
```
