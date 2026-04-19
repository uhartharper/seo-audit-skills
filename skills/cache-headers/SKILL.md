---
name: cache-headers
description: >
  Cache architecture for SEO: Cache-Control directives, CDN vs browser cache,
  ETag and Last-Modified, caching strategies by content type, and CMS-specific
  configuration for WordPress (WP Rocket, LiteSpeed), PrestaShop, and Nginx/Apache.
  Use when diagnosing TTFB issues, configuring caching layers, or auditing
  cache-related headers in HTTP responses.
---

# Cache Headers & Caching Strategy — Technical SEO

> Correct caching is the single highest-ROI performance optimization for most
> sites. A cold origin TTFB of 800ms becomes < 50ms with a CDN cache hit.

---

## Cache-Control directives reference

| Directive | Meaning | Use case |
|-----------|---------|----------|
| `max-age=N` | Browser can cache for N seconds | Static assets |
| `s-maxage=N` | CDN/shared cache can cache for N seconds | CDN-specific TTL |
| `no-cache` | Must revalidate with server before using cache | HTML pages |
| `no-store` | Do not cache at all | Authenticated/transactional pages |
| `must-revalidate` | Once stale, must revalidate (do not serve stale) | HTML pages |
| `public` | Shared caches (CDN) can store this response | Static assets, HTML |
| `private` | Only browser cache, not CDN | Logged-in user pages |
| `immutable` | Content will not change — no revalidation needed | Versioned static assets |
| `stale-while-revalidate=N` | Serve stale while fetching fresh in background | HTML for fast TTFB |

### Combinations by content type

```
Static assets (CSS, JS, images) — versioned with hash in filename:
Cache-Control: public, max-age=31536000, immutable

HTML pages (anonymous visitors):
Cache-Control: public, max-age=0, must-revalidate
  or with CDN:
Cache-Control: public, s-maxage=3600, stale-while-revalidate=86400

HTML pages (logged-in users):
Cache-Control: private, no-cache

Checkout / cart / account:
Cache-Control: no-store

API responses (public):
Cache-Control: public, max-age=300, s-maxage=600

Sitemaps and robots.txt:
Cache-Control: public, max-age=3600
```

---

## Cache layers architecture

```
User browser
    ↓
Browser cache (private, per user)
    ↓
CDN edge (shared, per PoP — Cloudflare, Fastly, CloudFront, etc.)
    ↓
Reverse proxy / load balancer (Nginx, Varnish)
    ↓
Application cache (WP Rocket page cache, LiteSpeed Cache, PrestaShop CCC)
    ↓
Object cache (Redis, Memcached — DB query results)
    ↓
PHP runtime (OPcache — compiled PHP bytecode)
    ↓
Database (MySQL / MariaDB)
```

Each layer reduces load on the next. A CDN hit eliminates all layers below it.
A page cache hit eliminates the PHP and database layers.

---

## ETag and Last-Modified

Both are validation mechanisms — they allow a client with a cached response to
ask "has this changed?" without downloading the full response again.

**Last-Modified:**
```
Response: Last-Modified: Wed, 16 Apr 2026 10:00:00 GMT
Next request: If-Modified-Since: Wed, 16 Apr 2026 10:00:00 GMT
Server: 304 Not Modified (if unchanged) or 200 + new content
```

**ETag:**
```
Response: ETag: "abc123"
Next request: If-None-Match: "abc123"
Server: 304 Not Modified (if same) or 200 + new content
```

**SEO relevance:** ETags and Last-Modified enable Googlebot to efficiently
re-crawl pages — if the content has not changed, Googlebot receives 304 and
skips re-processing. This conserves crawl budget on large sites.

**When ETags are a problem:** Nginx and Apache can generate ETags that include
inode numbers. On multi-server setups, different servers generate different
ETags for the same file → cache validation fails → unnecessary full responses.

Fix for Nginx:
```nginx
etag off;  # or use FileETag MTime Size in Apache
```

---

## WordPress caching

### Page cache — plugin options

| Plugin | Mechanism | Recommended stack |
|--------|-----------|------------------|
| WP Rocket | File-based page cache | Nginx or Apache + LiteSpeed |
| LiteSpeed Cache | LiteSpeed server-native | Hostinger, LiteSpeed servers |
| W3 Total Cache | Multiple backends | VPS with Redis/Memcached |
| WP Super Cache | File-based | Basic shared hosting |

### WP Rocket configuration

**Page Cache:**
- Settings > Cache > Enable caching for mobile devices: on
- Separate cache for mobile: on (if theme is responsive, keep off)
- Cache lifespan: 10 hours (adjust to content update frequency)

**Browser cache:**
- Settings > Browser Caching > on
- WP Rocket handles Cache-Control headers for static assets

**CDN integration:**
- Settings > CDN > CDN hostname: your CDN URL
- This rewrites asset URLs to the CDN hostname

**Exclusions (important for e-commerce):**
```
URLs to never cache:
/cart/
/checkout/
/my-account/
/order-received/

Cookies that bypass cache:
woocommerce_cart_hash
woocommerce_items_in_cart
wp_woocommerce_session_
```

### LiteSpeed Cache

**Common misconfiguration — X-Robots-Tag on XML files:**
LiteSpeed may apply `X-Robots-Tag: noindex` to all XML responses including sitemaps.
Fix: LiteSpeed Cache > Advanced > Excludes > Do Not Cache URIs > `/sitemap*.xml`

**Cache purge on publish:**
LiteSpeed Cache automatically purges page cache when a post is published or updated.
Verify this is working: publish a post and check the response headers for the page —
`X-LiteSpeed-Cache: miss` confirms a fresh request was served.

### Redis object cache

Object cache stores database query results in memory. Eliminates repeated identical
queries to MySQL.

```php
// wp-config.php
define('WP_CACHE_KEY_SALT', 'unique-site-key');
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);
```

Object cache reduces TTFB on pages with complex WP_Query calls (WooCommerce shop,
custom post type archives, widgets pulling recent posts).

---

## PrestaShop caching

### CCC (Combine, Compress, Cache)

Path: Advanced Parameters > Performance > CCC

| Option | Effect | Recommended |
|--------|--------|-------------|
| Smart cache for CSS | Combines and compresses CSS | On |
| Smart cache for JavaScript | Combines and compresses JS | On |
| Minify HTML | Removes whitespace from HTML | On |
| Compress inline JavaScript | Minifies inline JS | On |
| Move JavaScript to end | Defers JS to before `</body>` | On |

**Warning:** CCC can break custom themes. Test on staging first.

### Smarty cache

Path: Advanced Parameters > Performance > Smarty

| Setting | Production value |
|---------|-----------------|
| Cache compilation | Never recompile template files |
| Cache | Enabled |
| Caching type | File system |

### Full-page cache for PrestaShop

PrestaShop does not include a built-in full-page cache. Options:

1. **Varnish** in front of the application server — caches full HTML responses
2. **Nginx FastCGI cache** — caches PHP-FPM responses at the web server level
3. **Third-party module** — available on PrestaShop Addons marketplace

Configure cache bypass for:
- `/order/` (checkout)
- `/cart/` 
- Any URL with `PHPSESSID` cookie set

---

## Nginx caching configuration

### FastCGI page cache

```nginx
# In http block
fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=WORDPRESS:100m
                   inactive=60m max_size=1g;

# In server block
set $skip_cache 0;

# Bypass cache for logged-in users and WooCommerce
if ($http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|woocommerce_cart_hash|woocommerce_items_in_cart") {
    set $skip_cache 1;
}
if ($request_uri ~* "/wp-admin/|/wp-login.php|/cart/|/checkout/|/my-account/") {
    set $skip_cache 1;
}

fastcgi_cache WORDPRESS;
fastcgi_cache_valid 200 301 302 1h;
fastcgi_cache_bypass $skip_cache;
fastcgi_no_cache $skip_cache;
add_header X-FastCGI-Cache $upstream_cache_status;
```

### Static asset cache headers

```nginx
# CSS, JS, fonts — long cache with versioning assumption
location ~* \.(css|js|woff2|woff|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, max-age=31536000, immutable";
}

# Images
location ~* \.(jpg|jpeg|png|gif|webp|avif|svg|ico)$ {
    expires 1y;
    add_header Cache-Control "public, max-age=31536000";
}

# Sitemaps and feeds — shorter TTL
location ~* \.(xml|txt)$ {
    expires 1h;
    add_header Cache-Control "public, max-age=3600";
}
```

---

## CDN caching

### What CDNs cache by default

Most CDNs (Cloudflare, Fastly, CloudFront) cache:
- CSS, JS, images, fonts — yes, by default
- HTML — **no, not by default** (treated as dynamic)

To cache HTML, you must configure a cache rule:

**Cloudflare — cache HTML with short TTL:**
```
Rule: Cache Everything
Edge TTL: 1 hour
Bypass cache: Cookie contains "wordpress_logged_in" OR URI contains "/wp-admin/"
```

**Effect:** TTFB drops from 400-800ms (origin) to 10-50ms (CDN edge).

### Cache invalidation

When you publish new content, the CDN must serve the new version.
Options:
1. **Short TTL** (1h): cache expires automatically. Simple but means stale content
   for up to 1 hour after a change.
2. **Cache purge on publish**: WordPress plugins (WP Rocket, LiteSpeed) can purge
   the CDN cache for specific URLs when content is updated.
3. **Cache-Control: stale-while-revalidate**: serve stale while fetching fresh
   in background — best user experience.

---

## Diagnosing cache issues

### Check headers directly

```bash
# Check what cache headers a URL is returning
curl -I https://domain.com/page/ 2>&1 | grep -i "cache\|x-cache\|age\|etag\|last-modified"
```

Key headers to read:

| Header | Value | Meaning |
|--------|-------|---------|
| `Cache-Control: no-store` | — | Response will never be cached |
| `X-Cache: HIT` | — | CDN served from cache |
| `X-Cache: MISS` | — | CDN fetched from origin |
| `Age: 3600` | seconds | Response has been cached for 3600s |
| `CF-Cache-Status: DYNAMIC` | Cloudflare | HTML not being cached |
| `X-LiteSpeed-Cache: hit` | LiteSpeed | Served from LiteSpeed cache |

### Common issues

**`Cache-Control: no-store` on all HTML (PrestaShop default)**

PrestaShop ships with `no-store` on all HTML responses to prevent caching of
session-aware pages. Fix: enable CCC and Smarty cache (see PrestaShop section).

**`Cache-Control: private` on anonymous pages**

WordPress plugins or themes that set `private` prevent CDNs from caching pages
that could be safely cached for anonymous visitors.

**No cache headers at all**

Old PHP applications or misconfigured servers may emit no Cache-Control header.
Browsers default to heuristic caching (usually 10% of the Last-Modified age).
Explicit headers are always better.

**Cache headers correct but TTFB still high**

CDN is configured but HTML is bypassing it (`CF-Cache-Status: DYNAMIC`).
Check CDN rules — HTML may need an explicit "Cache Everything" rule.

---

## Audit checklist

```
CRITICAL
[ ] HTML pages return Cache-Control header (not absent)
[ ] Cart, checkout, and account pages return Cache-Control: no-store
[ ] No Cache-Control: no-store on anonymous HTML pages
[ ] Sitemap does not return X-Robots-Tag: noindex (LiteSpeed issue)

HIGH
[ ] TTFB < 800ms on primary pages (PSI field data or curl)
[ ] Page caching active (WP Rocket, LiteSpeed, Smarty)
[ ] Static assets (CSS, JS, images) have long max-age (>1 year)
[ ] CDN configured and serving static assets (X-Cache: HIT or CF-Cache-Status: HIT)

MEDIUM
[ ] CDN caching HTML for anonymous visitors (not just assets)
[ ] OPcache active for PHP (check php.ini or phpinfo())
[ ] Redis/Memcached for WordPress object cache (high-traffic sites)
[ ] ETag configuration on multi-server setups (no inode-based ETags)
[ ] PrestaShop: CCC active with all options enabled

LOW
[ ] Cache-Control: immutable on versioned static assets
[ ] stale-while-revalidate configured for HTML responses
[ ] Cache purge on content publish (CDN invalidation)
[ ] Age header present on CDN responses (confirms caching is active)
```
