---
name: ssl-https
description: >
  HTTPS implementation and SSL/TLS auditing: certificate types, mixed content
  detection and fixing, HTTPS redirect chains, HSTS configuration, and
  security headers. Use when a site has mixed content warnings, HTTP URLs,
  certificate issues, or when migrating from HTTP to HTTPS.
---

# SSL/HTTPS — Technical SEO

> HTTPS is a confirmed Google ranking signal since 2014. More importantly,
> mixed content blocks resource loading and can cause LCP failures.

---

## Certificate types

| Type | Validation | Issuance time | When to use |
|------|-----------|--------------|-------------|
| DV (Domain Validation) | Domain control only | Minutes | Blogs, informational sites |
| OV (Organization Validation) | Domain + organization | 1-3 days | Business sites |
| EV (Extended Validation) | Full legal verification | 1-7 days | Banks, e-commerce (less relevant today) |
| Wildcard (`*.domain.com`) | Covers all subdomains | Minutes–days | Sites with multiple subdomains |
| SAN (Subject Alternative Names) | Multiple domains in one cert | Minutes–days | Multi-domain hosting |

**Let's Encrypt:** Free DV certificate, auto-renewing, supported by most hosting
panels (cPanel, Plesk, Hostinger hPanel). Sufficient for most SEO client sites.

### Certificate expiration

An expired certificate causes:
- Browser security warnings that block all users
- Googlebot may stop crawling the site
- All Google rankings at risk of rapid drop due to inaccessibility

**Prevention:** Enable auto-renewal in the hosting panel. Most hosts renew
Let's Encrypt automatically. Verify auto-renewal is active, not just installed.

**Monitoring:** Set a calendar reminder 30 days before expiry, or use
uptime monitoring tools that alert on certificate expiry (UptimeRobot,
Better Uptime).

---

## HTTPS redirect — correct configuration

A site migrated to HTTPS must redirect all HTTP traffic to HTTPS with 301s.

### Correct redirect chain

```
http://domain.com/page/      → 301 → https://domain.com/page/   ✓
http://www.domain.com/page/  → 301 → https://domain.com/page/   ✓ (if non-www is canonical)
https://www.domain.com/page/ → 301 → https://domain.com/page/   ✓
```

### Redirect chain problems

**Too many redirects:**
```
http://domain.com/ → 301 → https://domain.com/ → 301 → https://www.domain.com/
```
Every redirect in the chain adds latency and dilutes link equity (historically).
Reduce to a single redirect hop.

**Redirect loop:**
```
http://domain.com/ → 301 → https://domain.com/ → 301 → http://domain.com/
```
Often caused by a server that redirects to HTTPS but an application that
redirects back to HTTP. Check WordPress `siteurl` setting and `.htaccess`.

### WordPress — enforce HTTPS

```apache
# .htaccess — redirect all HTTP to HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
```

Also verify in WordPress > Settings > General:
- WordPress Address (URL): `https://domain.com`
- Site Address (URL): `https://domain.com`

After changing to HTTPS in WordPress settings, regenerate the sitemap and
flush all caches.

### Nginx — enforce HTTPS

```nginx
server {
    listen 80;
    server_name domain.com www.domain.com;
    return 301 https://domain.com$request_uri;
}
```

---

## Mixed content

Mixed content occurs when an HTTPS page loads resources (images, scripts, CSS,
fonts, iframes) over HTTP. This is one of the most common post-migration issues.

### Types of mixed content

**Active mixed content (blocked by browsers):**
- HTTP scripts (`<script src="http://...">`)
- HTTP stylesheets (`<link href="http://...">`)
- HTTP iframes (`<iframe src="http://...">`)

Active mixed content is blocked by all modern browsers. The resource simply
does not load, which can break page functionality or cause LCP failures.

**Passive mixed content (warning in browser):**
- HTTP images (`<img src="http://...">`)
- HTTP video/audio

Passive mixed content loads but triggers a security warning in the browser address bar.
Google may treat HTTPS pages with mixed content as partially insecure.

### How to detect mixed content

**Browser DevTools:**
- Open the page in Chrome > F12 > Console tab
- Mixed content errors appear as "Mixed Content: The page ... was loaded over HTTPS
  but requested an insecure resource..."

**Screaming Frog:**
- Reports > Security Issues > Mixed Content
- Lists all URLs requested over HTTP from HTTPS pages

**curl check (useful for automated monitoring):**
```bash
# Check if a specific resource is served over HTTP
curl -si https://domain.com/ | grep -i "http://"
```

### Common mixed content sources

**WordPress database with old HTTP URLs:**
After migrating to HTTPS, the database still contains `http://` URLs in post content,
widget settings, theme options, and custom fields.

Fix: Search & Replace plugin (Better Search Replace) to update all `http://domain.com`
to `https://domain.com` in the WordPress database.

**Hard-coded HTTP in theme files:**
Some themes hard-code `http://` in PHP template files.
Fix: Search theme files for `http://` and replace with `https://` or `//` (protocol-relative).

**Third-party embeds:**
YouTube, Google Maps, and other embeds often auto-detect protocol.
If they do not, update the embed code manually.

**Plugins storing HTTP URLs in options table:**
Some plugins store their CDN or asset URLs as HTTP in the `wp_options` table.
Fix: update via Better Search Replace or WP-CLI:
```bash
wp search-replace 'http://domain.com' 'https://domain.com' --all-tables
```

**PrestaShop after HTTPS migration:**
PrestaShop stores domain and HTTP/HTTPS preference in `ps_configuration` table:
```sql
UPDATE ps_configuration
SET value = 'https://domain.com'
WHERE name IN ('PS_SHOP_DOMAIN', 'PS_SHOP_DOMAIN_SSL');

UPDATE ps_configuration
SET value = '1'
WHERE name = 'PS_SSL_ENABLED';
```

---

## HSTS — HTTP Strict Transport Security

HSTS instructs browsers to always connect to the domain over HTTPS, even if the
user types `http://` or follows an HTTP link. This eliminates the HTTP→HTTPS
redirect for returning users.

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

| Parameter | Meaning |
|-----------|---------|
| `max-age=31536000` | 1 year — browser remembers HTTPS-only for 1 year |
| `includeSubDomains` | Applies to all subdomains |
| `preload` | Required to be included in browser preload lists |

**HSTS preload list:** Browsers ship with a list of domains that are always HTTPS.
To be included: https://hstspreload.org
Requirements: 1-year max-age, includeSubDomains, preload directive, HTTPS-only site.

**Warning:** HSTS with `includeSubDomains` breaks any subdomain that does not
have a valid SSL certificate. Verify all subdomains are on HTTPS before enabling.

---

## Security headers

Security headers are not direct ranking signals but they affect user trust, prevent
specific attack classes that can compromise SEO (XSS injecting spam links), and are
increasingly checked by security-conscious clients.

### Minimum recommended headers

```nginx
# Nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
```

```apache
# Apache / .htaccess
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
```

### Header reference

| Header | Purpose | Recommended value |
|--------|---------|------------------|
| `Strict-Transport-Security` | Enforce HTTPS | `max-age=31536000; includeSubDomains` |
| `X-Frame-Options` | Prevent clickjacking | `SAMEORIGIN` |
| `X-Content-Type-Options` | Prevent MIME sniffing | `nosniff` |
| `Referrer-Policy` | Control referrer data | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | Restrict browser features | Deny unused: `geolocation=(), microphone=()` |
| `Content-Security-Policy` | Prevent XSS | Complex — start in `report-only` mode |

### X-Powered-By exposure

`X-Powered-By: PHP/8.1` reveals the PHP version and can be used to target
known vulnerabilities.

Fix:
```ini
; php.ini
expose_php = Off
```
```nginx
; nginx.conf
fastcgi_hide_header X-Powered-By;
```

---

## HTTPS migration checklist

For sites migrating from HTTP to HTTPS (or post-migration audit):

```
PRE-MIGRATION
[ ] SSL certificate installed and valid
[ ] Auto-renewal configured
[ ] All subdomains have certificates (if using includeSubDomains)

REDIRECT CONFIGURATION
[ ] HTTP → HTTPS 301 redirect configured
[ ] www → non-www (or vice versa) redirect in same hop
[ ] No redirect chains longer than 1 hop to final HTTPS URL
[ ] Verify in browser and with curl -L http://domain.com/

MIXED CONTENT
[ ] WordPress database updated (http:// → https://) via Better Search Replace
[ ] Hard-coded HTTP in theme PHP files updated
[ ] Third-party embed codes updated
[ ] No mixed content errors in browser DevTools Console
[ ] Screaming Frog: Security Issues > Mixed Content = empty

CONFIGURATION
[ ] WordPress siteurl and home updated to https://
[ ] Sitemap regenerated (all URLs now https://)
[ ] robots.txt Sitemap directive uses https://
[ ] Canonical tags on all pages use https://

HSTS
[ ] HSTS header configured (after confirming HTTPS is stable)
[ ] Security headers configured

GSC AND INDEXATION
[ ] New https:// property added in Google Search Console
[ ] Sitemap submitted in https:// property
[ ] GSC coverage report monitored for errors post-migration
[ ] Internal links updated from http:// to https:// (or relative URLs)
[ ] Backlinks from external sites will follow 301 to HTTPS — acceptable

MONITORING
[ ] Certificate expiry alert set (30 days before expiry)
[ ] Uptime monitoring active for HTTPS URLs
```

---

## Audit checklist (ongoing)

```
CRITICAL
[ ] Valid SSL certificate (not expired)
[ ] HTTP redirects to HTTPS (301)
[ ] No active mixed content (blocked scripts/CSS/iframes over HTTP)
[ ] No redirect loops

HIGH
[ ] No redirect chain longer than 1 hop to final URL
[ ] HSTS header present
[ ] X-Powered-By header removed
[ ] Siteurl/home in WordPress uses https://

MEDIUM
[ ] Passive mixed content (HTTP images) resolved
[ ] Security headers: X-Frame-Options, X-Content-Type-Options, Referrer-Policy
[ ] HTTPS consistent in sitemap URLs
[ ] HTTPS consistent in canonical tags
[ ] Certificate auto-renewal active

LOW
[ ] HSTS preload list submission (optional but good for high-traffic sites)
[ ] Content-Security-Policy in report-only mode
[ ] Permissions-Policy header configured
[ ] SSL rating A or A+ on Qualys SSL Labs (ssllabs.com/ssltest/)
```
