---
name: sitemap
description: >
  Technical audit knowledge for XML sitemaps: discovery, structural checks,
  URL quality validation, lastmod integrity, CMS-specific patterns, and sampling.
  Use when evaluating, diagnosing, or fixing a sitemap — including sitemap index
  structures, sub-sitemap issues, and robots.txt conflicts.
---

# XML Sitemap — Technical SEO Audit

> Based on Google's sitemap specification (sitemaps.org protocol) and observed
> patterns across WordPress, PrestaShop, Shopify, and Magento sites.

---

## Discovery — How to find the sitemap

### Priority order

1. **robots.txt `Sitemap:` directive** — authoritative. `Sitemap: https://domain.com/sitemap_index.xml`
2. **Standard paths** — HEAD request to confirm existence:
   - `/sitemap_index.xml` (WordPress with Yoast / Rank Math)
   - `/sitemap.xml` (generic)
   - `/1_index_sitemap.xml` (PrestaShop default — the standard path does not exist)
   - `/sitemap/` (some custom implementations)
3. **Not found** — critical issue. Google cannot discover it automatically.

### If not declared in robots.txt

Not declaring the sitemap in robots.txt is a **low-severity** issue, not critical.
Google can still find sitemaps via Google Search Console submission or standard paths.
Best practice: always declare it with `Sitemap: https://domain.com/sitemap_index.xml`.

---

## Sitemap types

| Type | Root element | Contains |
|------|-------------|----------|
| Sitemap index | `<sitemapindex>` | References to sub-sitemaps (`<sitemap><loc>`) |
| URL set | `<urlset>` | Individual URLs (`<url><loc>`) |
| News sitemap | `<urlset>` + news namespace | `<news:publication>`, `<news:publication_date>` |
| Image sitemap | `<urlset>` + image namespace | `<image:image>`, `<image:loc>` |

Most CMS plugins generate a sitemap index pointing to type-specific sub-sitemaps
(pages, posts, products, categories). This is the recommended structure for sites
with more than a few hundred URLs.

---

## Critical checks — Sitemap not processable by Google

### HTTP status

- **200** — required. Any other status means Google cannot process the sitemap.
- Common non-200 cases: 404 (wrong path), 301/302 (plugin reconfigured), 500 (server error).
- PrestaShop: default sitemap is `/1_index_sitemap.xml`. Without a 301 redirect from
  `/sitemap.xml`, the standard path returns 404.

### X-Robots-Tag: noindex on the sitemap itself

**Most impactful and frequently missed sitemap error.** The sitemap file returns HTTP 200
but has `X-Robots-Tag: noindex` in its response headers. Google reads the header, treats
the sitemap as noindexable, and stops processing it — even though the status is 200.

**How to detect:** check response headers of the sitemap URL directly, not just the HTTP status.

**Causes:**
- LiteSpeed Cache applying noindex headers to all cached files including XML
- Apache/Nginx misconfiguration applying a global noindex header
- Server-level configuration at the hosting provider

**Fixes by environment:**

```
LiteSpeed Cache:
  Advanced > Excludes > Do Not Cache > add /sitemap*.xml

Apache (.htaccess):
  <FilesMatch "sitemap.*\.xml$">
    Header unset X-Robots-Tag
  </FilesMatch>

Nginx:
  location ~* sitemap.*\.xml$ {
    more_clear_headers "X-Robots-Tag";
  }

If it persists: server-level configuration — contact hosting support.
```

### XML invalid

A parse error in the XML makes the sitemap unreadable. Causes:
- Special characters not properly escaped (`&` instead of `&amp;`, `<` in URLs)
- Encoding mismatch (declared UTF-8 but contains Latin-1 characters)
- Truncated file (server timeout during sitemap generation)
- Extra whitespace before the XML declaration

**Validation:** https://www.xml-sitemaps.com/validate-xml-sitemap.html

---

## Structural checks

### File size

Google's hard limit is **50 MB uncompressed**. Practical warning threshold: 30 MB.

If approaching the limit: switch to a sitemap index structure and split by content type
(pages, posts, products, categories). Each sub-sitemap can contain up to 50,000 URLs.

### URL count

- **Limit per sitemap file:** 50,000 URLs
- **Warning threshold:** 40,000 URLs
- If using a sitemap index, each sub-sitemap has its own 50,000 URL limit

### Content-Type header

The sitemap should be served with `Content-Type: application/xml` or `text/xml`.
Serving it as `text/html` or `application/octet-stream` can cause parsing issues
in some crawlers.

### Response time

A slow sitemap reduces how frequently Googlebot re-fetches it.
- Above 3s: medium issue
- Above 5s: high issue

Fix: enable sitemap caching in the SEO plugin, or serve the XML file from static cache.

---

## Sitemap index — Sub-sitemap checks

### Failed sub-sitemaps

A sub-sitemap referenced in the index that returns 404 or error causes Google to lose
all URLs from that sub-sitemap. The index references it but it does not exist.

**Fix:** regenerate the sitemap from the SEO plugin, or remove the broken reference.

### Empty sub-sitemaps

Sub-sitemaps with 0 URLs generate unnecessary Googlebot requests and waste crawl budget.

**Fix in WordPress:** Yoast SEO > XML Sitemaps > disable the post type or taxonomy
that generates the empty sub-sitemap.

### Authors sub-sitemap

Author archive pages are typically thin content (a list of posts by one author, with
no unique content of its own). Having them in the sitemap signals them as indexable
and wastes crawl budget.

**Fix:**
- Yoast: SEO > Search Appearance > Archives > Author archives > No index
- Rank Math: Titles & Meta > Users > No index
- Remove from sitemap after setting to noindex

---

## URL quality checks (no requests needed)

### HTTP vs HTTPS mixed content

URLs in the sitemap starting with `http://` on an HTTPS site are incorrect.
Google may not index them correctly as it treats them as different URLs from
the canonical HTTPS versions.

**Fix:** check WordPress > Settings > General > Site Address (URL) — must be `https://`.
Regenerate sitemap after correcting.

### www vs non-www inconsistency

A sitemap mixing `https://domain.com/` and `https://www.domain.com/` URLs indicates
an incorrect canonical configuration or a sitemap generated before/after a migration.

**Fix:** define the canonical version in WordPress > Settings > General, or in the SEO
plugin. Regenerate sitemap.

### Trailing slash inconsistency

If more than 10% of URLs disagree on trailing slash (some end with `/`, others do not),
it signals incorrect canonical configuration. Google treats these as distinct URLs.

**Fix:** enforce consistent trailing slash in permalink settings. Yoast applies the
WordPress permalink configuration automatically.

### Uppercase in URL paths

`/Pagina/` and `/pagina/` are treated as different URLs by Google. URLs in sitemaps
should always use lowercase paths.

**Fix:** normalize to lowercase. In WordPress, use a redirect plugin (Redirection)
to force lowercase. Update slugs directly in the CMS.

### UTM / tracking parameters

URLs with `utm_source`, `utm_medium`, `utm_campaign`, `fbclid`, `gclid`, etc. in the
sitemap are indexed as independent URLs with the same content as the canonical version
— creating duplicate content.

**Fix:** configure the SEO plugin to exclude URLs with tracking parameters from the sitemap.

### Staging / development URLs

Staging domain signals: `staging.`, `dev.`, `.local`, `test.`, `preprod.`, `qa.`, `sandbox.`

If staging URLs appear in the production sitemap, the sitemap was generated or copied
from a staging environment. **Regenerate the sitemap in production.**

### Cross-domain URLs

URLs pointing to a different domain than the audited site. Typical causes:
- WordPress multisite misconfiguration
- Post-migration sitemap not regenerated
- Sitemap copied from another client (manual error)

### Very long URLs

URLs exceeding 2,000 characters can cause issues in some crawlers.
Shorten slugs or remove unnecessary URL parameters.

### Disallow conflict with robots.txt

A URL present in the sitemap but blocked by a `Disallow` rule in robots.txt creates
a contradiction: the sitemap says "please index this URL" but robots.txt says
"do not crawl it." Google will see the URL but not be able to crawl it.

**Fix:** either remove the Disallow rule for URLs that should be indexed, or remove
those URLs from the sitemap.

---

## lastmod — Integrity checks

`lastmod` tells Googlebot when a page was last modified, helping it prioritize
re-crawls of recently updated content.

### lastmod presence

At least 50% of URLs should have a `lastmod` value. Sites without `lastmod` give
Googlebot no signal for prioritizing re-crawls.

**Enable in WordPress:**
- Yoast: included automatically
- Rank Math: SEO > Sitemap > Advanced > Include Last Modified

### lastmod 1970-01-01 — Rank Math bug

**Documented bug:** Rank Math generates `1970-01-01T00:00:00+00:00` for posts
that do not have a saved modified date in the database (typically posts published
before Rank Math was installed, or posts that were never re-saved).

This is not a minor cosmetic issue — Google sees it as a last-modified date in 1970
and de-prioritizes those URLs for re-crawl.

**Fix:**
- Rank Math: Titles & Meta > Posts > Advanced > Use Modified Date
- Or: bulk re-save affected posts to write a real modified date to the database

### lastmod format

Valid formats (W3C datetime / ISO 8601):
- `YYYY-MM-DD` — date only, acceptable
- `YYYY-MM-DDThh:mm:ss+TZ` — full datetime with timezone, preferred

Invalid examples: `DD/MM/YYYY`, `Month DD, YYYY`, timestamps without year.

### lastmod in the future

Google ignores future modification dates. Cause: incorrect server timezone
configuration. Fix: verify server time and timezone, then regenerate sitemap.

### All lastmod dates very old (>2 years)

If more than 90% of URLs have a lastmod older than 2 years, the sitemap is not
reflecting the real state of the content. Either:
- The plugin is not updating lastmod when pages are saved
- The site has a genuine content freshness problem (content audit needed)

### All lastmod dates identical

If all URLs share the exact same lastmod date, the sitemap is statically generated
with a single timestamp — not reflecting actual page modification dates.

**Fix:** enable dynamic lastmod generation in the SEO plugin.

---

## priority field

The `priority` field (0.0–1.0) is **largely ignored by Google** and has been
de-prioritized in the sitemaps.org specification. Google's own guidance states
it does not use `priority` for ranking.

**Common misuse:** all URLs set to `priority=1.0`. When everything has maximum
priority, the signal is noise.

**Recommendation:** if the SEO plugin sets it automatically, leave it. If it is
forcing `1.0` everywhere, either configure differentiated values or remove it entirely.

Suggested values (if used):
| Page type | priority |
|-----------|---------|
| Homepage | 1.0 |
| Main service / product pages | 0.8 |
| Blog / listing pages | 0.6 |
| Archive / tag pages | 0.4 |
| Paginated pages | 0.2–0.4 |

---

## URL sampling — Live checks

Sampling 10 random URLs from the sitemap reveals live issues that static analysis misses.

### Broken URLs (404, 410, connection error)

Even a small % of broken URLs in the sitemap wastes crawl budget and signals to Google
that the sitemap is not maintained.

**For comprehensive broken URL detection:** use Screaming Frog in list mode with all
sitemap URLs. Sampling only catches a statistical signal.

### Redirects (3xx)

The sitemap should contain the canonical final URL — not a URL that redirects to it.
If more than 20% of sampled URLs return a 3xx, the sitemap was not regenerated after
a permalink change or migration.

**Note:** a single redirect is acceptable and Google follows it. The issue is having
the redirected URL in the sitemap rather than the destination.

### noindex in sitemap URLs

Pages with `<meta name="robots" content="noindex">` or `X-Robots-Tag: noindex`
should not be in the sitemap. Including them creates a contradiction between
the sitemap signal (index this) and the page directive (do not index this).

**Google's behavior:** Google respects `noindex` over the sitemap. The URL will
not be indexed, but it will still be crawled — wasting crawl budget.

**Common causes:**
- Paginated pages set to noindex but not excluded from the sitemap
- Draft / private pages accidentally included
- Tag or category archives set to noindex globally but still in sitemap

### Canonical mismatch

The URL in the sitemap should match the canonical URL declared on the page.
A mismatch means the sitemap is pointing to a non-canonical URL.

**Example:**
- Sitemap URL: `https://domain.com/product-name`
- Page canonical: `https://domain.com/products/product-name/`

**Fix:** align permalink structure, canonical configuration in the SEO plugin,
and regenerate the sitemap.

### Slow page response times

Pages consistently taking more than 2 seconds to respond will be crawled less
frequently. Googlebot has a crawl budget and allocates less time to slow sites.

**Diagnose:** check TTFB in PageSpeed Insights. Activate page caching and CDN.

---

## Internal / transactional URLs to exclude

These URL patterns should never appear in a sitemap:

| Pattern | Why |
|---------|-----|
| `/wp-admin/`, `/wp-login.php` | Admin — should never be crawled |
| `/feed/`, `/*/feed/` | RSS feeds — no SEO value in sitemap |
| `/cart/`, `/checkout/`, `/my-account/` | Transactional — personalized, no indexable value |
| `/?s=`, `/search/` | Internal search results — duplicate content, no value |
| `PHPSESSID=`, `id_lang=`, `id_currency=` | Session / language parameters |
| `/wc-api/`, `route=checkout`, `route=account` | WooCommerce / OpenCart internal endpoints |
| `utm_source=`, `fbclid=`, `gclid=` | Tracking parameters |
| `?preview=true`, `?page_id=` | WordPress preview URLs |
| `/trackback/` | WordPress trackback endpoints |

---

## CMS-specific patterns

### WordPress + Yoast SEO

- Sitemap index at `/sitemap_index.xml`
- Sub-sitemaps auto-generated by post type and taxonomy
- lastmod updated automatically on save
- Disable post types / taxonomies: Yoast > SEO > XML Sitemaps

### WordPress + Rank Math

- Sitemap index at `/sitemap_index.xml`
- Documented bug: `lastmod=1970-01-01` for posts without a saved modified date
- Enable lastmod: Titles & Meta > Posts > Advanced > Use Modified Date
- Disable post types: Rank Math > Sitemap > Post Types

### WordPress + WooCommerce

WooCommerce adds post types (`product`, `product_variation`) and taxonomies
(`product_cat`, `product_tag`) that require specific sitemap decisions.

**`/my-account/` in the sitemap**

One of the most common WooCommerce sitemap errors. The My Account page is
personalized per user and has no indexable value — yet SEO plugins often include
it because it is a standard WordPress page.

- Yoast: set the My Account page to noindex via the page editor meta box, then
  regenerate the sitemap. Yoast excludes noindex pages automatically.
- Rank Math: same — noindex the page directly, then regenerate.

**Product variations**

WooCommerce creates a post for each variation (`product_variation` post type).
These are not publicly accessible URLs — they return 404 if visited directly.
Some sitemap configurations accidentally include them.

Fix: Yoast > XML Sitemaps > verify `product_variation` is disabled.
Rank Math > Sitemap > Post Types > disable Product Variation.

**Out-of-stock and discontinued products**

Products set to "Draft" or with stock status "Out of stock" may remain in the sitemap
after the product is discontinued. If the product page returns 404 or redirects,
it should be removed from the sitemap.

Pattern to detect: sampling returns 404 or redirect on product URLs.
Fix: in WooCommerce, set discontinued products to "Draft" or delete them and add a
proper 301 redirect to a relevant category page.

**Product tag archives**

`product_tag` archives are typically thin content (a filtered list of products by tag,
with no editorial content). Equivalent to the author archive problem.

Fix: Yoast > Search Appearance > Taxonomies > Product Tags > No index.
Rank Math > Titles & Meta > Product Tags > No index.
Exclude from sitemap after setting to noindex.

**WooCommerce endpoint pages**

WooCommerce generates virtual endpoint URLs appended to the My Account page:
`/my-account/orders/`, `/my-account/downloads/`, `/my-account/edit-account/`, etc.
These should never be in the sitemap — they require user authentication.

These endpoints are not standard WordPress pages so they are less likely to appear
in the sitemap, but verify if the site uses a custom page structure.

**`/shop/` page**

The main shop page (`/shop/` or localized equivalent) is generally worth indexing.
However, paginated versions (`/shop/page/2/`, `/shop/page/3/`) are low-value and
should be excluded from the sitemap (set to noindex via SEO plugin).

**WooCommerce REST API and AJAX endpoints**

`/wc-api/`, `/wp-json/wc/` endpoints should never appear in a sitemap.
If detected, the sitemap is likely including URLs from a crawl-based generator
rather than from the WooCommerce post type registry. Switch to the native
Yoast or Rank Math sitemap generator.

### PrestaShop

- Default sitemap path: `/1_index_sitemap.xml` — the path `/sitemap.xml` does not exist
- Fix: add a 301 redirect in Nginx or `.htaccess` from `/sitemap.xml` to `/1_index_sitemap.xml`
- Some sitemap modules include internal AJAX controller URLs (`?controller=...`)
  These must be excluded from the sitemap module config or blocked in robots.txt
- Sitemap generation can include paginated URLs (`&p=2`) — configure the module to exclude them

### Shopify

- Sitemap at `/sitemap.xml` (platform-generated, not editable directly)
- Automatically includes products, collections, blog posts, pages
- No way to exclude individual URLs from the sitemap — use `<meta name="robots" content="noindex">`
  on the page, which causes Shopify to remove it from the sitemap on the next regeneration

### Magento

- Sitemap generated via catalog > Google Sitemap in the backoffice
- Common issue: sitemap URL in robots.txt not updated after domain change
- Staging URLs in production sitemap after a migration or cloned environment

---

## Diagnostic commands — sitemap live

### Verificar accesibilidad y status HTTP

```bash
curl -s -I https://example.com/sitemap.xml | head -5
```

Resultado esperado: `HTTP/2 200` y `Content-Type: application/xml` o `text/xml`.
Si devuelve 301 → hay redirect innecesario (Yoast genera esto a veces hacia el índice).
Si devuelve 404 → el sitemap no existe en esa ruta — verificar robots.txt para la ruta real.

### Contar URLs en un sitemap

```bash
# Total de <loc> en un sitemap o sitemap index
curl -s https://example.com/sitemap.xml | grep -c "<loc>https"

# Por sub-sitemap
curl -s https://example.com/post-sitemap.xml | grep -c "<loc>https"
curl -s https://example.com/page-sitemap.xml | grep -c "<loc>https"
```

### Verificar si una URL específica está en el sitemap

```bash
# Buscar si una slug o URL concreta aparece en el sitemap
curl -s https://example.com/page-sitemap.xml | grep -i "nombre-del-slug"
```

Útil para confirmar si una página noindex fue eliminada correctamente del sitemap,
o para verificar que una URL nueva ya aparece después de un ping/regeneración.

### Verificar que el sitemap está declarado en robots.txt

```bash
curl -s https://example.com/robots.txt | grep -i "sitemap"
```

---

## Audit checklist

```
CRITICAL (Google cannot process the sitemap)
[ ] Sitemap exists and is accessible (HTTP 200)
[ ] No X-Robots-Tag: noindex on the sitemap response headers
[ ] XML is valid and parseable
[ ] No staging / development URLs in production sitemap
[ ] No URLs pointing to a different domain

HIGH (crawl budget waste or indexation loss)
[ ] No sub-sitemaps returning 404 or error
[ ] URL count within the 50,000 limit per file
[ ] No URLs blocked by robots.txt Disallow rules
[ ] No HTTP URLs on an HTTPS site
[ ] No www / non-www inconsistency
[ ] No UTM or tracking parameters in sitemap URLs
[ ] No internal / transactional URLs (cart, checkout, admin, search)
[ ] WooCommerce: /my-account/ not in sitemap
[ ] WooCommerce: product_variation post type excluded from sitemap
[ ] WooCommerce: product_tag archives noindex and excluded from sitemap
[ ] No lastmod 1970-01-01 (Rank Math bug)
[ ] Sampling: no broken URLs (404, error)
[ ] Sampling: no noindex URLs in sitemap
[ ] Sampling: no canonical mismatch

MEDIUM (reduced crawl efficiency)
[ ] File size under 30 MB
[ ] Response time under 3 seconds
[ ] No trailing slash inconsistency
[ ] No uppercase in URL paths
[ ] No empty sub-sitemaps
[ ] Author archives not in sitemap
[ ] lastmod format valid (W3C / ISO 8601)
[ ] No future lastmod dates
[ ] lastmod not all identical (not statically generated)
[ ] lastmod not all older than 2 years (>90% threshold)
[ ] Content-Type is application/xml or text/xml
[ ] Sampling: redirect rate under 20%
[ ] Sampling: average response time under 2 seconds

LOW (maintenance and best practices)
[ ] Sitemap declared in robots.txt
[ ] No duplicate URLs in sitemap
[ ] No URLs longer than 2,000 characters
[ ] priority field not set to 1.0 for all URLs
[ ] No empty sub-sitemaps
```

---

## Common positives to validate

- Sitemap declared in robots.txt
- All URLs use HTTPS
- No mixed www/non-www
- lastmod present in 100% of URLs
- No duplicate URLs
- No internal or transactional URLs
- No staging URLs
- No robots.txt Disallow conflicts
- Sampling: all URLs return HTTP 200
- Sampling: no noindex, no canonical mismatch
