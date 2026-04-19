---
name: schema-markup
description: >
  Schema.org structured data (JSON-LD) for SEO: type selection, implementation
  by CMS (WordPress/Yoast/Rank Math, WooCommerce, PrestaShop), documented bugs,
  validation workflow, E-E-A-T signals, and rich result eligibility. Use when
  auditing schema markup, implementing structured data, or diagnosing rich result
  issues in Google Search Console.
---

# Schema Markup (JSON-LD) — Technical SEO

> All schema referenced here uses JSON-LD format — the only format Google
> recommends for new implementations.
> Validator: https://validator.schema.org
> Rich Results Test: https://search.google.com/test/rich-results

---

## Validator.schema.org vs Rich Results Test — not the same

| Tool | What it validates | When to use |
|------|------------------|-------------|
| validator.schema.org | Schema.org specification compliance — correct types, required properties, enum values | Always — primary validation |
| Rich Results Test | Whether Google can generate a rich result from this page's schema | After schema is spec-valid, to check Google eligibility |
| GSC > Enhancements | Errors Google encounters on crawled pages at scale | Production monitoring |

**Rule:** A schema that passes the Rich Results Test does not mean it is
spec-correct. A schema that passes validator.schema.org does not mean it
will generate a rich result. Both tools serve different purposes.

---

## Schema type selection

### For WordPress/blog sites

| Page type | Recommended schema |
|-----------|------------------|
| Homepage (company) | `Organization` or `LocalBusiness` |
| Homepage (personal brand) | `Person` |
| Blog post | `Article` (or `BlogPosting` for informal blogs) |
| Service page | `Service` within a `WebPage` |
| About page | `AboutPage` + `Person` or `Organization` |
| Contact page | `ContactPage` |
| FAQ section | `FAQPage` |
| Breadcrumbs | `BreadcrumbList` |

### For e-commerce (WooCommerce, PrestaShop)

| Page type | Recommended schema |
|-----------|------------------|
| Product page | `Product` + `Offer` + optionally `AggregateRating` |
| Category page | `ItemList` (optional, no rich result) |
| Checkout / cart | No schema needed |
| Homepage (shop) | `Organization` |

### For medical / health sites

| Page type | Recommended schema |
|-----------|------------------|
| Medical condition article | `MedicalWebPage` + `MedicalCondition` |
| Treatment page | `MedicalWebPage` with `specialty` |
| Doctor profile | `Physician` (subtype of `MedicalBusiness`) |
| Clinic homepage | `MedicalBusiness` |

---

## Core schema types — implementation reference

### Organization / LocalBusiness

```json
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "@id": "https://domain.com/#organization",
  "name": "Business Name",
  "url": "https://domain.com",
  "logo": {
    "@type": "ImageObject",
    "url": "https://domain.com/logo.png",
    "width": 300,
    "height": 150
  },
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "Street Name 123",
    "addressLocality": "City",
    "postalCode": "28001",
    "addressCountry": "ES"
  },
  "telephone": "+34 900 000 000",
  "sameAs": [
    "https://www.facebook.com/businessname",
    "https://www.instagram.com/businessname",
    "https://www.linkedin.com/company/businessname"
  ]
}
```

**Logo requirements for rich results:**
- Minimum: 112×112px (Google requirement for Knowledge Panel eligibility)
- 60×60px is invalid for rich result eligibility — do not use
- Recommended: square or near-square, transparent background (PNG)
- Must be crawlable and publicly accessible

**`sameAs` validation:**
- Each URL must be publicly accessible (200 status)
- Remove dead services: Google+, defunct social profiles
- Do not duplicate the same URL twice
- Limit to authoritative profiles: official social media, Wikipedia, Wikidata

### Article / BlogPosting

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "@id": "https://domain.com/post-slug/#article",
  "headline": "Article Title",
  "description": "Meta description text",
  "image": "https://domain.com/featured-image.jpg",
  "datePublished": "2026-01-15T10:00:00+01:00",
  "dateModified": "2026-03-20T14:30:00+01:00",
  "author": {
    "@type": "Person",
    "@id": "https://domain.com/author/name/#person",
    "name": "Author Name",
    "url": "https://domain.com/author/name/"
  },
  "publisher": {
    "@type": "Organization",
    "@id": "https://domain.com/#organization",
    "name": "Site Name",
    "logo": {
      "@type": "ImageObject",
      "url": "https://domain.com/logo.png"
    }
  },
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "https://domain.com/post-slug/"
  }
}
```

**Article vs BlogPosting vs NewsArticle:**
- `Article` — generic, recommended for most blog/editorial content
- `BlogPosting` — informal blog post, no advantage over Article in practice
- `NewsArticle` — for news publishers registered with Google News

### FAQPage

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "Question text here?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Answer text here. Can include basic HTML."
      }
    },
    {
      "@type": "Question",
      "name": "Second question?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Second answer."
      }
    }
  ]
}
```

**FAQPage and rich results (2023 update):**
Google restricted FAQ rich results (accordion dropdowns in SERP) to
government and health/medical sites only. Commercial sites no longer
get the accordion rich result.

**However, FAQPage is still worth implementing because:**
- Google reads Q&A pairs for semantic understanding of the page
- Bing and Yandex still render FAQ rich results for all sites
- AI tools (ChatGPT, Perplexity, AI Overviews) extract Q&A pairs from FAQPage schema
- E-E-A-T signal: structured, clear answers support topical authority

**Recommendation:** Maintain existing FAQPage implementations. Do not remove them.
Do not promise FAQ accordion rich results to clients on commercial sites.

### BreadcrumbList

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    {
      "@type": "ListItem",
      "position": 1,
      "name": "Home",
      "item": "https://domain.com/"
    },
    {
      "@type": "ListItem",
      "position": 2,
      "name": "Category Name",
      "item": "https://domain.com/category/"
    },
    {
      "@type": "ListItem",
      "position": 3,
      "name": "Page Title"
    }
  ]
}
```

**Last item:** The last `ListItem` does not need an `item` property (it is the current page).

**Duplicate BreadcrumbList (Yoast + Schema Pro / Elementor):**
A common issue in WordPress sites using two schema-generating plugins simultaneously.
Google may show one or both, or neither if they conflict.
Fix: disable breadcrumb schema in one plugin. Yoast handles it well by default.

### Product + Offer (WooCommerce / PrestaShop)

```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "Product Name",
  "description": "Product description text",
  "image": [
    "https://domain.com/product-image-1.jpg",
    "https://domain.com/product-image-2.jpg"
  ],
  "sku": "SKU-123",
  "brand": {
    "@type": "Brand",
    "name": "Brand Name"
  },
  "offers": {
    "@type": "Offer",
    "url": "https://domain.com/product-slug/",
    "priceCurrency": "EUR",
    "price": "29.99",
    "priceValidUntil": "2026-12-31",
    "availability": "https://schema.org/InStock",
    "itemCondition": "https://schema.org/NewCondition",
    "seller": {
      "@type": "Organization",
      "name": "Store Name"
    }
  }
}
```

**`availability` must use full schema.org enum URL:**
- `"https://schema.org/InStock"` — correct
- `"InStock"` — accepted by Google but not spec-valid
- `"in stock"` — invalid

**`price` format:** String, not number. `"29.99"` not `29.99`.

**`priceValidUntil`:** Required for rich result eligibility when `price` is present.
Without it, Google may not show the price in the rich result.

### AggregateRating

```json
"aggregateRating": {
  "@type": "AggregateRating",
  "ratingValue": "4.7",
  "reviewCount": "124",
  "bestRating": "5",
  "worstRating": "1"
}
```

Add this inside a `Product` or `LocalBusiness` schema.

**Requirements for Google to show star ratings:**
- `ratingValue`, `reviewCount` (or `ratingCount`), `bestRating` are required
- The ratings must come from actual users — not self-assigned
- WooCommerce: requires a reviews plugin that exports to JSON-LD
- PrestaShop: requires the native reviews module with schema export enabled

**AggregateRating on pages without visible reviews:** Google can penalize sites
that show schema ratings but do not display the actual reviews on the page.
Only use AggregateRating if the reviews are visible to users.

---

## Documented bugs and common errors

### datePublished = "1970-01-01" (Rank Math bug)

**Cause:** Rank Math generates `datePublished: "1970-01-01T00:00:00+00:00"` for
posts that have no saved modified date in the WordPress database. Typically
affects posts published before Rank Math was installed.

**Impact:** Google de-prioritizes these articles for re-crawl. In Google News,
a 1970 date causes immediate exclusion. In regular search, it signals stale content.

**Fix:**
- Rank Math: Titles & Meta > Posts > Advanced > Use Modified Date
- Bulk re-save affected posts to write a real modified date to the database
- Or via WP-CLI: `wp post list --post_type=post --fields=ID | xargs -I {} wp post update {} --post_modified="$(date)"`

### `@type` capitalization (Rank Math lowercase bug)

Rank Math sometimes generates lowercase `@type` values in author objects inside Article schema:
```json
"author": {
  "@type": "person",   ← wrong
  "name": "Author Name"
}
```

Correct: `"@type": "Person"` — capitalized, matching schema.org specification.

**Detection:** validator.schema.org flags this as a type error.

### `specialty` with text value instead of enum URL (MedicalWebPage)

```json
// Wrong — text value
"specialty": "Physical Therapy"

// Correct — full enum URL
"specialty": "http://schema.org/PhysicalTherapy"
```

The `specialty` property on `MedicalWebPage` and `MedicalBusiness` requires
a full enum URL from the schema.org MedicalSpecialty enum.
Text values are invalid per validator.schema.org.

Full list: https://schema.org/MedicalSpecialty

### Logo too small for Knowledge Panel (60×60px)

Google requires a minimum 112×112px logo image for Knowledge Panel eligibility.
A 60×60px logo passes the Rich Results Test but is invalid for Knowledge Panel.

**Yoast:** SEO > Search Appearance > Knowledge Graph > Logo — upload minimum 112×112px.

### null fields in Person schema (WordPress author profile)

```json
"author": {
  "@type": "Person",
  "name": "Author Name",
  "email": null,      ← noise, not invalid but unnecessary
  "gender": null,     ← same
  "image": null       ← same
}
```

Null fields are not spec errors but signal an incomplete author profile.
They are generated when WordPress author fields exist in the schema template
but have no value. Not worth fixing as a standalone task, but should be noted
as indicator of thin author profiles for E-E-A-T purposes.

### `sameAs` with dead services or duplicates

```json
"sameAs": [
  "https://plus.google.com/...",   ← dead — Google+ shut down 2019
  "https://www.facebook.com/page",
  "https://www.facebook.com/page"  ← duplicate
]
```

**Fix:** Remove Google+ URLs. Deduplicate. Verify all URLs return 200.

### WebSite schema @id in subdirectory installations (Yoast)

Yoast in a WordPress subdirectory (`/en/`) generates:
```json
"@id": "https://domain.com/en/#website"
```
Instead of:
```json
"@id": "https://domain.com/#website"
```

This splits the Knowledge Graph entity between the main domain and the subdirectory.

**Fix in functions.php of the secondary installation:**
```php
add_filter('wpseo_schema_website', function($data) {
    $data['@id'] = 'https://domain.com/#website';
    $data['url'] = 'https://domain.com/';
    return $data;
});
```

---

## MedicalWebPage and MedicalCondition — GSC expectations

**MedicalWebPage and MedicalCondition do not generate an enhancement report in GSC.**

Google Search Console only shows enhancement reports for schema types that
generate rich results (Product, FAQ, HowTo, Review, etc.). Medical schema
types are not in this list.

**The value of medical schema is:**
- Semantic classification — helps Google understand the content is health-related
- E-E-A-T signal — structured authorship and specialty claims
- AI extraction — ChatGPT, Perplexity, and AI Overviews use medical schema
  to understand medical content and attribute it correctly
- Bing/Yandex — may use it for health-specific rich results

**Do not promise GSC enhancement reports when implementing medical schema.**

---

## E-E-A-T and schema

Schema supports E-E-A-T signals through structured authorship and entity data.

### Author schema for E-E-A-T

For sites where author expertise matters (medical, legal, financial, news):

```json
{
  "@type": "Person",
  "@id": "https://domain.com/author/name/#person",
  "name": "Author Full Name",
  "url": "https://domain.com/author/name/",
  "jobTitle": "Physiotherapist",
  "description": "Short bio establishing expertise",
  "image": {
    "@type": "ImageObject",
    "url": "https://domain.com/author-photo.jpg"
  },
  "sameAs": [
    "https://www.linkedin.com/in/authorname",
    "https://orcid.org/0000-0000-0000-0000"
  ],
  "worksFor": {
    "@type": "Organization",
    "@id": "https://domain.com/#organization"
  },
  "knowsAbout": ["Physical Therapy", "Rehabilitation", "Sports Medicine"]
}
```

**`jobTitle` and `description`** are the most important E-E-A-T fields.
They establish the author's role and expertise directly in the schema.

**`sameAs` for authors:** LinkedIn is the most impactful. ORCID for academic/medical.
Wikidata if the author has a notable profile.

### Linking Article to Person (consistent @id)

The same `@id` for the author must appear in both the Article schema and the
standalone Person schema on the author's archive page:

```json
// On article page:
"author": {
  "@type": "Person",
  "@id": "https://domain.com/author/name/#person"
}

// On author archive page — full Person entity with same @id:
{
  "@type": "Person",
  "@id": "https://domain.com/author/name/#person",
  "name": "Author Name",
  "jobTitle": "...",
  ...
}
```

Google uses the `@id` to connect the author entity across pages and build
a consolidated understanding of the author's expertise.

---

## CMS implementation

### WordPress + Yoast SEO

Yoast generates automatically:
- `WebSite` with `SearchAction`
- `Organization` or `Person` (configured in SEO > Search Appearance > Knowledge Graph)
- `Article` / `BlogPosting` on posts
- `WebPage` on pages
- `BreadcrumbList`

**Configuration paths:**
- Organization schema: SEO > Search Appearance > Knowledge Graph
- Logo: SEO > Search Appearance > Knowledge Graph > Logo (minimum 112×112px)
- Author schema: SEO > Search Appearance > Archives > Author archives
- Social profiles for `sameAs`: SEO > Search Appearance > Social

**Yoast does NOT generate automatically:**
- `Product` + `Offer` (requires Yoast WooCommerce SEO add-on)
- `FAQPage` (must be added via FAQ block in editor)
- `HowTo` (must be added via HowTo block)
- `AggregateRating`

### WordPress + Rank Math

Rank Math generates similar schema to Yoast with some differences:

- Schema builder: Rank Math > Schema > Schema Generator (per post type)
- Supports `Product`, `Course`, `Recipe`, `JobPosting` natively
- Documented bug: `datePublished = 1970-01-01` (see bugs section)
- Documented bug: lowercase `@type` in author objects (see bugs section)

**Rich Snippet type per post:** Each post can have a different schema type
set via the Rank Math sidebar > Schema > Schema Type.

### WooCommerce

WooCommerce + Yoast WooCommerce SEO add-on generates:
- `Product` + `Offer` automatically from product data
- `AggregateRating` if reviews are enabled and ratings exist

**Without the add-on:** WooCommerce generates microdata (not JSON-LD).
Google still reads microdata but JSON-LD is preferred.

**Schema Pro plugin:** Alternative to Yoast WooCommerce SEO for WooCommerce schema.
Supports more granular control but risks duplicate BreadcrumbList (see bugs section).

### PrestaShop

PrestaShop 8.x generates `Product` schema natively if enabled in the SEO module.

**Path:** Catalog > Products > SEO tab > check if schema is being generated
**Verify:** WebFetch a product page and search for `application/ld+json`

`AggregateRating` requires:
- The native reviews module (or third-party) with star ratings
- Module configured to export ratings to JSON-LD

PrestaShop does NOT generate `Article`, `BlogPosting`, or `FAQPage` natively.
These require custom Smarty template implementation.

---

## Validation workflow

```
1. Implement schema in JSON-LD
2. Validate with validator.schema.org
   → Fix all errors (invalid types, missing required fields, wrong enum values)
   → Note warnings (optional but recommended fields)
3. Test with Rich Results Test (search.google.com/test/rich-results)
   → Confirms Google can render a rich result from this specific page
   → "Eligible" does not guarantee Google will show it — Google decides
4. Monitor GSC > Enhancements
   → Available for: Product, FAQ (health/gov), Article, Sitelinks Searchbox,
     Video, Review snippet, Breadcrumb
   → NOT available for: MedicalWebPage, MedicalCondition, Service, LocalBusiness
5. After GSC shows the enhancement, check for errors/warnings in the report
```

**Common validation errors:**

| Error | Cause | Fix |
|-------|-------|-----|
| Missing required field | Required property absent | Add the property |
| Invalid enum value | Text instead of URL for enum fields | Use full schema.org URL |
| Type not found | Lowercase `@type` (Rank Math bug) | Capitalize: `"Person"` not `"person"` |
| Invalid URL format | Relative URL in `@id` or `item` | Use absolute URLs with protocol |
| No values provided | Empty array `[]` | Remove the property or populate it |

---

## Audit checklist

```
CRITICAL
[ ] No schema with invalid XML/JSON syntax (validate with validator.schema.org)
[ ] datePublished not "1970-01-01" (Rank Math bug)
[ ] @type capitalized correctly ("Person" not "person")
[ ] specialty using full enum URL (not text) on medical pages
[ ] Product schema present on all product pages (WooCommerce / PrestaShop)
[ ] Offer price, priceCurrency, availability present in Product schema

HIGH
[ ] Organization/LocalBusiness logo ≥ 112×112px
[ ] No duplicate BreadcrumbList (two plugins generating simultaneously)
[ ] sameAs contains no dead URLs (Google+, defunct profiles)
[ ] No duplicate sameAs URLs
[ ] AggregateRating only on pages with visible reviews
[ ] WebSite @id points to root domain (not subdirectory) in all installations
[ ] Article schema on blog posts (datePublished, author, publisher)

MEDIUM
[ ] Author schema with jobTitle and description for E-E-A-T
[ ] Consistent @id for author across Article and Person pages
[ ] FAQPage maintained on relevant pages (semantic value even without rich result)
[ ] priceValidUntil present on Product Offer schema
[ ] AggregateRating has reviewCount, ratingValue, bestRating, worstRating
[ ] MedicalWebPage specialty uses schema.org enum URL

LOW
[ ] No null fields in Person schema (incomplete author profile signal)
[ ] No schema types Google does not use (redundant noise)
[ ] sameAs includes LinkedIn for author profiles (E-E-A-T)
[ ] GSC Enhancements monitored for eligible schema types
```
