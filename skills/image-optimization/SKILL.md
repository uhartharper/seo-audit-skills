---
name: image-optimization
description: >
  Image optimization for SEO and Core Web Vitals: format selection (WebP, AVIF),
  responsive images (srcset, sizes), lazy loading strategy, LCP image handling
  (fetchpriority, preload), compression targets, and CMS-specific implementation
  for WordPress and PrestaShop. Use when auditing images for LCP, CLS, bandwidth,
  or accessibility issues.
---

# Image Optimization — SEO & Core Web Vitals

> Images are 50-70% of page weight on most sites. They are also the most common
> LCP element. Wrong format, wrong loading strategy, or missing dimensions are
> among the top 5 CWV failure causes.

---

## Format selection

| Format | Best for | Browser support | Typical savings vs JPEG |
|--------|----------|----------------|------------------------|
| JPEG | Photos, complex images | Universal | baseline |
| PNG | Graphics with transparency | Universal | baseline |
| WebP | Photos + graphics | 95%+ (2024) | 25-35% smaller |
| AVIF | Photos + graphics | 80%+ (2024) | 40-50% smaller |
| SVG | Icons, logos, illustrations | Universal | N/A (vector) |

**Recommendation:** Serve WebP as the default for all new images. Use AVIF where
browser support is acceptable and compression gains justify the encoding time.
Always keep JPEG/PNG as fallback via `<picture>`.

```html
<!-- AVIF with WebP fallback and JPEG as final fallback -->
<picture>
  <source srcset="hero.avif" type="image/avif">
  <source srcset="hero.webp" type="image/webp">
  <img src="hero.jpg" alt="Hero image description" width="1200" height="600"
       loading="eager" fetchpriority="high">
</picture>
```

---

## File size targets

| Image type | Context | Target size |
|------------|---------|-------------|
| LCP hero | Above the fold, full-width | < 100 KB |
| Product image | E-commerce main image | < 150 KB |
| Blog featured image | Article header | < 80 KB |
| Thumbnail | Card, listing | < 30 KB |
| Icon / small graphic | < 50px | Use SVG or inline |
| Background texture | Decorative | < 50 KB |

Sizes above are for WebP. JPEG equivalents are approximately 30-40% larger.

---

## Responsive images — srcset and sizes

Without responsive images, a mobile user downloads a 2400px-wide desktop image
for a 390px-wide screen. This wastes bandwidth and delays LCP.

```html
<img
  src="product-800.jpg"
  srcset="product-400.webp 400w,
          product-800.webp 800w,
          product-1200.webp 1200w,
          product-1600.webp 1600w"
  sizes="(max-width: 600px) 100vw,
         (max-width: 1200px) 50vw,
         800px"
  alt="Product name"
  width="800"
  height="600"
  loading="lazy">
```

**`sizes` attribute explained:** Tells the browser how wide the image will be
displayed before the CSS is parsed. This allows the browser to select the right
source from `srcset` during preload, before layout is known.

- `(max-width: 600px) 100vw` → on screens < 600px, image is 100% of viewport width
- `(max-width: 1200px) 50vw` → on screens < 1200px, image is 50% of viewport width
- `800px` → on larger screens, image is always 800px wide

**Missing `sizes` attribute:** The browser defaults to `100vw` and downloads the
largest available image on all screen sizes. Equivalent to not using srcset.

---

## LCP images — do not lazy-load

The LCP image is the most important image on the page. Loading strategies that
delay its discovery or download directly increase LCP.

### Rules for LCP images

1. **Never `loading="lazy"`** — lazy loading defers the fetch until the element
   is near the viewport. For the LCP element, the element IS in the viewport.

2. **Always `fetchpriority="high"`** — signals to the browser that this image
   should be fetched at high priority, ahead of other resources.

3. **Add `<link rel="preload">` in `<head>`** — allows the browser to start
   downloading the image before the HTML is parsed far enough to discover the `<img>` tag.

4. **Only one `fetchpriority="high"` per page** — setting it on multiple images
   effectively cancels the priority signal.

```html
<!-- In <head> -->
<link rel="preload" as="image"
      href="/images/hero.webp"
      imagesrcset="/images/hero-400.webp 400w, /images/hero-800.webp 800w"
      imagesizes="(max-width: 600px) 100vw, 800px"
      fetchpriority="high">

<!-- In <body> — the actual LCP image -->
<img src="/images/hero.webp"
     srcset="/images/hero-400.webp 400w, /images/hero-800.webp 800w"
     sizes="(max-width: 600px) 100vw, 800px"
     alt="Hero description"
     width="800" height="400"
     loading="eager"
     fetchpriority="high">
```

---

## Lazy loading — when it helps vs hurts

`loading="lazy"` is correct and recommended for all images below the fold.
It is incorrect and harmful on images above the fold (especially the LCP image).

### When to use `loading="lazy"`

- All images that are not visible without scrolling on initial load
- Product images in a grid below the hero
- Blog post thumbnails in a list
- Images in footer sections

### When NOT to use `loading="lazy"`

- LCP image (hero, product main image)
- Any image visible in the initial viewport on typical screen sizes
- Images with `fetchpriority="high"`

### Lazy loading paradox with page builders

Elementor and WP Rocket apply lazy loading automatically to all images,
including the LCP hero. This is the most common LCP failure in WordPress sites.

**Elementor:** The lazy load CSS hides backgrounds of sections 4+ and swaps
`src` with a placeholder. Fix: `e-no-lazyload` class on hero section.

**WP Rocket:** Replaces `<img src>` with `data-lazy-src` even if `loading="eager"`
or `fetchpriority="high"` is set in the HTML. Fix: exclude the hero image filename
in WP Rocket > Media > LazyLoad > Excluded images.

---

## alt text — SEO and accessibility

```html
<!-- Correct: descriptive, with keyword where natural -->
<img src="limpieza-cristales-madrid.webp"
     alt="Equipo de limpieza de cristales en fachada de edificio en Madrid"
     width="800" height="533">

<!-- Wrong: keyword-stuffed -->
<img src="limpieza.webp" alt="limpieza limpieza cristales limpieza madrid limpieza profesional">

<!-- Wrong: empty alt on content image -->
<img src="team.jpg" alt="">

<!-- Correct: decorative image (pure visual) has empty alt -->
<img src="divider-wave.svg" alt="" role="presentation">
```

**Rules:**
- Content images (photos, product images, infographics): descriptive alt required
- Decorative images (separators, backgrounds converted to `<img>`): `alt=""`
- Logos: `alt="Company name logo"`
- CTA buttons with image: describe the action, not the image

**SEO impact:** Alt text is used by Google to understand image content and as a
ranking signal for image search. It is also a mandatory WCAG accessibility requirement.

---

## Image dimensions — preventing CLS

Missing `width` and `height` attributes on images cause layout shifts (CLS) when
the image loads and the browser reflows the page to accommodate the image dimensions.

```html
<!-- Causes CLS: browser does not know height before image loads -->
<img src="product.jpg" alt="Product">

<!-- No CLS: browser reserves exact space -->
<img src="product.jpg" alt="Product" width="600" height="400">
```

**CSS alternative:**
```css
img {
  aspect-ratio: 3 / 2;  /* matches 600x400 ratio */
  width: 100%;
  height: auto;
}
```

Both approaches are valid. The `aspect-ratio` CSS approach is more flexible for
responsive images where the intrinsic size varies.

---

## CSS background-image vs `<img>` tag

| | CSS background-image | `<img>` tag |
|-|---------------------|-------------|
| Discoverable by preload scanner | No | Yes |
| Lazy loadable | Via Intersection Observer JS | Native `loading="lazy"` |
| Accessible (alt text) | No | Yes |
| `fetchpriority` support | No | Yes |
| CLS prevention (dimensions) | Via aspect-ratio or min-height | `width` + `height` attributes |

**Rule:** Use `<img>` for content images. Use CSS background-image for
decorative backgrounds that have no informational value.

If a hero background-image must remain as CSS, add a manual preload:
```html
<link rel="preload" as="image" href="/images/hero-bg.webp" fetchpriority="high">
```

---

## Compression and optimization workflow

### WordPress

**ShortPixel (recommended):**
- Bulk optimization with WebP/AVIF generation
- Lossy compression with quality 82-88 (imperceptible quality loss)
- CDN delivery option

**Smush:**
- Free tier covers most small sites
- WebP conversion requires Pro plan

**Imagify:**
- Aggressive compression presets
- WebP conversion included

**WP Rocket + Imagify:** WP Rocket has native integration with Imagify for
on-the-fly WebP conversion via CDN rewriting.

### PrestaShop

PrestaShop regenerates thumbnails from original uploads. Large originals are
stored and thumbnails generated per context (product list, product page, email).

Fix for large originals: reduce upload quality before uploading, or use a module
that compresses originals on upload.

PrestaShop thumbnail configuration: Back Office > Design > Image Settings.
Regenerate thumbnails after changing sizes.

### Manual optimization tools

- **Squoosh** (squoosh.app): browser-based, side-by-side comparison, WebP/AVIF
- **ImageOptim** (Mac): lossless and lossy compression
- **Sharp** (Node.js): programmatic batch conversion
- **cwebp**: CLI tool for WebP conversion

---

## CMS-specific issues

### WordPress + Elementor — wrong element gets fetchpriority

Elementor Pro's "Image" widget has an "Attributes" field. It is common to see
`fetchpriority="high"` applied manually to a decorative divider or separator
icon instead of the hero image. Check that `fetchpriority="high"` is on the
visually largest above-the-fold element.

### WordPress — attachments page

WordPress automatically creates a public page for each uploaded image at
`/domain.com/attachment/filename-of-image/`. These pages have thin content
(just the image) and should be redirected or set to noindex.

Fix in Yoast: SEO > Search Appearance > Media > Redirect attachment URLs to
the attachment itself: Yes.

### PrestaShop — product image alt text

PrestaShop uses the product name as the alt text for product images by default.
This is often acceptable, but adding specific descriptive alt text per image
improves both SEO and accessibility.

The alt text for product images can be set per image in Catalog > Products >
Images tab.

### WooCommerce — product gallery lazy loading

WooCommerce product gallery images after the first are lazy-loaded by WooCommerce
and WP themes. This is correct behavior — they are not visible until the user
interacts with the gallery. The main product image should be `loading="eager"`.

---

## Audit checklist

```
CRITICAL (LCP impact)
[ ] LCP image: NOT lazy-loaded (no loading="lazy", no data-src placeholder)
[ ] LCP image: has fetchpriority="high"
[ ] LCP image: < 100 KB
[ ] LCP image: served as WebP or AVIF (not JPEG/PNG if avoidable)

HIGH (CLS and performance)
[ ] All content images have explicit width + height (or aspect-ratio CSS)
[ ] Images below the fold use loading="lazy"
[ ] No images > 500 KB on any page (PSI "Properly size images")
[ ] Responsive srcset present on images > 400px wide
[ ] Hero image NOT served as CSS background-image (or preload link present)

MEDIUM (SEO and accessibility)
[ ] All content images have meaningful alt text
[ ] Decorative images have alt="" (empty alt, not missing)
[ ] No keyword-stuffed alt text
[ ] WordPress attachment pages redirected or noindexed
[ ] Product images in e-commerce have descriptive alt text

LOW (optimization)
[ ] WebP/AVIF served to supported browsers
[ ] Image CDN or compression plugin active
[ ] No images loaded unnecessarily on mobile (art direction via <picture>)
[ ] Thumbnails correct size (not oversized images scaled down with CSS)
```
