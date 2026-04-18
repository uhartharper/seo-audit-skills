# SEO Skills for Claude Code

Custom knowledge base for technical SEO audits. Each skill is a Markdown file
that Claude Code loads automatically when the relevant topic is invoked.

Built from real audit patterns across:
- **CMS**: WordPress (Divi, Elementor), PrestaShop
- **Analytics & tracking**: GA4, Google Tag Manager
- **SEO tools**: Screaming Frog, SE Ranking, Semrush
- **Technical**: robots.txt, Core Web Vitals, schema, crawl budget

All knowledge is anonymized and GDPR compliant — no client data, no domains,
no identifying information. The pattern matters, not the source.

---

## Skills

### CMS — WordPress + Divi

**File:** `skills/wordpress-divi/SKILL.md`

Covers WordPress sites built with Divi Theme (Elegant Themes) 4.27.x.

- **Missing H1** — Divi does not generate H1 automatically. Fix: module > Design > Heading Tag
- **Massive inline CSS** — Divi Dynamic CSS injects hundreds of KB per page. Fix: Critical CSS + Improved Asset Loading
- **Render-blocking JS** — 10-20 scripts without `async`/`defer`. PHP snippets with `script_loader_tag` hook (WP 4.1+) to defer by handle, with jQuery exclusion
- **Hero as CSS background-image** — invisible to the preload scanner. Fix: `<link rel="preload">` or convert to real `<img>`
- **Security** — `<meta generator>`, `X-Powered-By`, open REST API, user enumeration, pingback. PHP snippets with `wp_robots` (WP 5.7+) and `rest_authentication_errors` (WP 4.4+) hooks
- **Virtual robots.txt** — WordPress generates robots.txt without a physical file. `robots_txt` hook (WP 3.0+) to add AI crawler rules
- **Conditional loading** — Ninja Forms, Dashicons and GDPR plugins load on all pages. Fix: `wp_enqueue_scripts` with priority 100+
- Audit checklist by criticality + common positives + Divi/Yoast configuration paths

---

### CMS — WordPress + Elementor

**File:** `skills/wordpress-elementor/SKILL.md`

Covers WordPress sites built with Elementor (free and Pro), including stacks with WP Rocket and WooCommerce.

- **Lazy-loaded LCP hero** — Elementor and WP Rocket replace `src` with SVG placeholder. `fetchpriority="high"` becomes useless even when present. Fix: `e-no-lazyload`, exclude in WP Rocket > Media > LazyLoad
- **fetchpriority on wrong element** — assigned to decorative images (separators, dividers) instead of the real LCP image
- **Excessive CSS/JS** — 40-90+ resources. Fix: Improved Asset Loading (Elementor > Settings > Performance)
- **Massive HTML payload** — WP Rocket injects `RocketLazyLoadScripts` and `elementorFrontendConfig` inline. Observed up to 1.4 MB
- **Elementor lazy load on backgrounds** — `.e-con.e-parent:nth-of-type(n+4)` hides backgrounds of sections 4+ until JS marks them. Causes CLS
- **Missing security headers** — consistent pattern. Snippets for Nginx and Apache
- **Version exposure** — Elementor in meta generator. PHP snippet to remove it
- **REST Link header** — exposes internal WordPress IDs. Fix: `remove_action('template_redirect', 'rest_output_link_header', 11)`
- **DOM size** — Section/Column (4 divs) vs Flexbox Containers (2 divs). Fix: Elementor > Tools > Converter
- **WooCommerce** — duplicate BreadcrumbList (Yoast + Schema Pro), FAQPage without rich results in e-commerce since 2023, missing Product schema, `/my-account/` in sitemap
- **PHP EOL** — 7.4 EOL since Nov 2022. Fix: update in hPanel/cPanel/Plesk
- **Keyword cannibalization on location pages** — Elementor makes it easy to duplicate templates by city
- Audit checklist by criticality + common positives + configuration paths

---

### CMS — PrestaShop

**File:** `skills/prestashop-seo/SKILL.md`

Covers PrestaShop 1.7.x / 8.x, including stacks with CreativeElements and Nginx/Plesk.

- **sitemap.xml 404** — PrestaShop generates the sitemap at `/1_index_sitemap.xml`. The standard path does not exist by default. Fix: 301 redirect in Nginx or .htaccess
- **Cache-Control: no-store** — disabled by default on all HTML pages. Fix: CCC in Advanced Parameters > Performance (Smart cache CSS/JS, Minify HTML, Move JS to end)
- **URLs with numeric ID** — `/217-slug` is PrestaShop standard. Not an error if the canonical points to the URL with ID. Migration requires a redirect plan
- **Controllers in sitemap** — CreativeElements and sitemap modules include internal AJAX endpoints. Fix: exclude from the module or block in robots.txt
- **PHPSESSID with decade-long expiry** — GDPR/ePrivacy. Fix: `session.cookie_lifetime = 0` in php.ini
- **Missing OG tags** — PrestaShop does not generate them by default. Smarty snippets for head.tpl
- **Hero as background-image** — native sliders and CreativeElements. Fix: `displayHeader` hook to inject preload
- **Security** — Nginx headers, CSP in report-only mode, `expose_php = Off`
- **Schema Product + Offer** — generated natively in PS8 if enabled. AggregateRating requires a reviews module
- **IndexNow** — implementation via `actionObjectProductUpdateAfter` hook
- Backoffice route table + checklist by criticality + common positives

---

### Tracking — Google Tag Manager

**File:** `skills/google-tag-manager/SKILL.md`

GTM debugging and configuration, focused on the "event not reaching GA4" scenario.

- **Diagnostic tree** — 7 ordered steps: paused tag → restrictive trigger → Preview Mode → Consent Mode → firing order → Measurement ID → DebugView
- **Preview vs Production** — Preview bypasses ad blockers and Consent Mode. Always test in incognito. `?gtm_debug=x` for debugging in the real environment
- **dataLayer** — structure, naming rules, GA4 reserved events, how to read the dataLayer in console and in the Preview tab
- **Consent Mode v2** — mandatory in EEA since March 2024. `analytics_storage: denied` blocks GA4 tags. Difference between Basic and Advanced Consent Mode. Default + update snippets
- **Firing order** — GA4 Configuration Tag must fire on "Initialization - All Pages" before Event Tags. Tag Sequencing to guarantee it. Full trigger hierarchy
- **DebugView** — how to activate via GTM, Chrome Extension or URL param
- **Common cases** — AJAX forms vs traditional submit, Contact Form 7 (`wpcf7mailsent`), Elementor Forms, clicks on `tel:` and `mailto:`
- Container installation verification via console and Network tab

---

### Tracking — GA4 Analysis

**File:** `skills/ga4-analysis/SKILL.md`

GA4 data analysis for SEO audits, focused on organic vs paid acquisition.

- **UA to GA4 differences** — sessions vs events, bounce rate vs engagement rate, goals vs conversions, sampling vs BigQuery
- **Organic vs paid** — channel groups, how to isolate Organic Search, why misconfigured UTMs inflate organic
- **Attribution models** — Data-driven (default), Last click, First click, Linear, Time decay. Lookback windows. Why GA4 and Google Ads show different numbers
- **Engagement** — definition of engaged session (>=10s or >=2 pages or conversion), difference from UA bounce rate
- **GSC integration** — Reports > Acquisition > Search Console. Limitation: only sessions where GA4 recorded the visit
- **Google Ads integration** — remarketing audiences, conversion import, organic vs paid side-by-side analysis
- **DebugView** — activation, latency, parameter validation
- **Useful SEO reports** — organic landing pages, organic queries, pages with high organic bounce rate
- **Common errors** — paid traffic in Organic, self-referral, inflated sessions, duplicate conversions, excessive direct traffic
- BigQuery export, key dimensions and metrics

---

### Tool — SE Ranking

**File:** `skills/se-ranking/SKILL.md`

SE Ranking data interpretation in the context of SEO audits.

- **Rank tracking** — normal volatility (+-3) vs real drop (>5 positions sustained 7+ days) vs sudden drop (possible update). Diagnostic tree before acting
- **SERP Features** — position 4 with Featured Snippet can outperform position 1 without feature in real CTR
- **Site Audit** — static crawler (no JS rendering). Issues = signals, not conclusions. Prioritization table: high/medium/low priority by real impact
- **Documented false positives** — H1 missing in Divi/Elementor, duplicate content from pagination, broken links in JS, dynamic meta description
- **Traffic estimation** — error margin +-40-60%. Use as trend, not absolute figure. Comparison with GA4 and GSC
- **Keyword research** — recommended flow from seed keywords to intent assignment. Volume differences between SE Ranking, Semrush and Google Ads
- **Competitor analysis** — Share of Voice, Keyword Gap, when to use Semrush for discovery and SE Ranking for precise tracking
- Integration with GSC, Screaming Frog and Semrush

---

### Tool — Screaming Frog

**File:** `skills/screaming-frog/SKILL.md`

Technical use of Screaming Frog SEO Spider in audits.

- **Spider vs JS Rendering** — Spider: fast, does not execute JS. JS Rendering: uses Chromium, 5-10x slower, mandatory for Divi/Elementor. Selective crawl by URL list for large sites
- **CMS configuration** — WordPress (exclusions for wp-admin, feeds, searches; JS timeout 10s) and PrestaShop (session/currency/language parameters to exclude; Accept-Language header)
- **Key reports** — Response Codes (302->301 redirects, linked 404s, 500s), Page Titles (missing, duplicate, length), Meta Description, H1 (missing, multiple), Canonicals (pointing to 404, missing canonical), Directives (unintentional noindex), Images (alt text, size)
- **Orphan pages** — Bulk Export > All Inlinks. Pages without internal links that rank in SE Ranking = opportunity to improve internal PageRank
- **Integration** — GSC (impressions/clicks columns in crawl), GA4 (sessions per URL), PSI (selective crawl only)
- **False positives** — H1 missing in Divi/Elementor, duplicate content in pagination without canonical, broken links in JS modals, slow page without CDN cache, images missing alt in CSS backgrounds
- **Performance** — estimated time table by site size and crawl mode. Minimum 8GB RAM for JS rendering

---

### Tool — Semrush

**File:** `skills/semrush/SKILL.md`

Semrush use and interpretation as a complementary tool in the audit stack.

- **Organic Research** — position distribution (top 3 / 4-10 / 11-100), top pages, historical trend, branded vs non-branded. Precision: +-40%, use as trend
- **Keyword Gap** — Missing (biggest opportunity), Weak (improve position), Untapped (validate demand). Intents: Informational, Navigational, Commercial, Transactional
- **Backlink Gap** — domains linking to competitors but not the client. Filter by Authority Score >30
- **Site Audit** — basic crawler. In the audit flow, Screaming Frog is the main crawler. Semrush Site Audit as secondary check
- **Traffic Analytics** — total traffic estimation (not just organic). Useful for channel comparison with competitors. Do not use as real figures
- **Authority Score** — proprietary metric, not PageRank. Range table. Use as comparative reference, not as a target
- **SE Ranking vs Semrush** — SE Ranking for precise tracking of defined keywords, Semrush for full domain discovery. Flow: Semrush discovers, SE Ranking tracks
- **Why positions differ** — measurement date, datacenter, request location
- Useful exports, limitations to communicate to the client

---

### Technical — robots.txt

**File:** `skills/robots-txt/SKILL.md`

Full technical specification and templates by site type, with focus on Google Merchant Center.

- **Google specification** — Allow/Disallow precedence (longest rule wins), user-agent matching (specific does not inherit from `*`), `*` and `$` wildcards, AdsBot outside the `*` wildcard
- **Merchant Center** — MC error table and its cause in robots.txt, official solution (Googlebot + Googlebot-image with empty `Disallow:`), `*` block directives that cause disapprovals
- **Templates** — informational site/blog, e-commerce without MC, e-commerce with MC (with "what NOT to include" section)
- **AI governance** — table of training bots (block) vs AI search bots (allow). Difference between GPTBot and ChatGPT-User
- **Common errors** — `Disallow: /*?` without Googlebot block, `*.php` blocking admin-ajax, sitemap with wrong domain, unmanaged AdsBot, wildcard at the start of path
- **WordPress** — how to edit: SEO plugin, physical file, PHP hook
- Evaluation checklist by criticality (critical / high / medium / low)

---

### Technical — Hreflang

**File:** `skills/hreflang/SKILL.md`

Hreflang implementation and auditing for multilingual or multi-regional WordPress sites.

- **Fundamentals** — when to implement, when not to, mandatory syntax, reciprocity rule and self-reference
- **WPML** — configuration, indexable test page issue, conflict with page builders
- **TranslatePress** — duplicate hreflang conflict with Yoast. Solution: disable in one of the two
- **Yoast + independent installations** — incorrect WebSite schema @id in subdirectory. PHP snippet fix
- **HFCM (manual implementation)** — when to use instead of a global plugin. Per-page setup
- **Hreflang Manager Lite** — global mode risk with partial translation: generates massive broken reciprocity
- **Common errors** — broken reciprocity, URLs with 404/redirect, incorrect language code, missing x-default, duplicate hreflang
- **Validation** — Screaming Frog Hreflang tab (noreturn, incorrect code, non-canonical), GSC > International, manual JS verification snippet
- Checklist by criticality (critical / high / medium / low)

---

## Installation

### Plugin install (Claude Code 1.0.33+)

```
/plugin install seo-audit-skills@uhartharper-seo-audit-skills
```

### Manual install — Unix / macOS / Linux

```bash
git clone --depth 1 https://github.com/uhartharper/seo-audit-skills.git
bash seo-audit-skills/install.sh
```

### Manual install — Windows (PowerShell)

```powershell
git clone --depth 1 https://github.com/uhartharper/seo-audit-skills.git
powershell -ExecutionPolicy Bypass -File seo-audit-skills\install.ps1
```

All scripts copy each `skills/*/SKILL.md` to `~/.claude/skills/[name]/SKILL.md`.
Running them again updates existing skills.

## Works well with

Works standalone. For broader SEO coverage (AI search optimization, local SEO, programmatic SEO), combine with [claude-seo](https://github.com/AgriciDaniel/claude-seo).

## Privacy

All knowledge is anonymized. No client names, domains, or identifying data.
GDPR compliant.

## Contributing

Enrich the skills with real patterns as new issues appear.
Rule: knowledge is added anonymized — the pattern matters, not the source.
