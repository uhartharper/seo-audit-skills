---
name: third-party-scripts
description: >
  Third-party script management for SEO and Core Web Vitals: script loading
  strategies (async, defer, preload, module), CWV impact by vendor category,
  GTM-based deferral, auditing the third-party footprint, and eliminating
  unused scripts. Use when diagnosing INP, TBT, or LCP issues caused by
  third-party JavaScript, or when reviewing a site's script inventory.
---

# Third-Party Scripts — Performance & SEO

> Third-party scripts are the most common uncontrolled variable in CWV.
> They execute on the client's main thread, consume bandwidth, and can
> independently cause LCP, INP, and TBT failures.

---

## Script loading strategies

### async

```html
<script async src="https://example.com/script.js"></script>
```

- Downloads in parallel with HTML parsing
- Executes as soon as download completes (pauses HTML parsing)
- Order not guaranteed when multiple async scripts present
- Use for: analytics, tracking, ads — scripts that do not depend on the DOM

### defer

```html
<script defer src="https://example.com/script.js"></script>
```

- Downloads in parallel with HTML parsing
- Executes after HTML parsing is complete, before `DOMContentLoaded`
- Order guaranteed (executes in order of appearance)
- Use for: scripts that need DOM access but are not critical path

### Comparison

| | async | defer | none (blocking) |
|-|-------|-------|----------------|
| Download | Parallel | Parallel | Blocks parsing |
| Execute | On download complete | After HTML parsed | On encounter |
| Order | Not guaranteed | Guaranteed | Guaranteed |
| Blocks HTML parsing | Yes (during execution) | No | Yes |
| Best for | Analytics, ads | DOM-dependent non-critical | Critical scripts |

### module

```html
<script type="module" src="script.js"></script>
```

Module scripts are deferred by default. They also support static imports and
execute in strict mode. Use for modern ES modules.

### Dynamic import (lazy loading)

```javascript
// Load script only when needed
button.addEventListener('click', async () => {
  const { initChat } = await import('./chat-widget.js');
  initChat();
});
```

Use for scripts tied to user interaction (chat widgets, video players, complex
forms) that do not need to load on page start.

---

## CWV impact by vendor category

### Analytics (GA4, Matomo, Plausible)

| Vendor | Typical main thread cost | Notes |
|--------|------------------------|-------|
| GA4 via gtag.js | 50-150ms | Lower than UA |
| GA4 via GTM | 80-200ms | GTM container overhead added |
| Matomo | 30-80ms | Self-hosted, no third-party DNS |
| Plausible | < 5ms | Lightweight by design |

**Impact:** Primarily TBT and INP. Rarely causes LCP directly.
**Fix:** Load via GTM with DOM Ready or Window Loaded trigger instead of Page View
for non-critical event tracking.

### Advertising (Google Ads, Meta Pixel, MSCLK)

| Vendor | Main thread cost | Notes |
|--------|-----------------|-------|
| Google Ads gtag | 100-300ms | Required for conversion tracking |
| Meta Pixel | 100-400ms | Loads multiple resources |
| Microsoft Clarity | 50-200ms | Session recording, high DOM mutation cost |
| Hotjar | 150-500ms | Session recording, mousemove tracking = high INP cost |

**Impact:** INP degradation is the primary risk. Hotjar and Clarity record
mouse movements, which adds a persistent main thread cost on every user interaction.

**Fix:** Load via GTM. Configure triggers to fire after Window Loaded.
Do not use both Clarity and Hotjar simultaneously — they do the same thing.

### Chat widgets (Intercom, Drift, Tidio, Crisp)

Chat widgets are among the worst CWV offenders:
- Load 2-5 additional scripts from their own CDN
- Inject persistent DOM nodes that trigger style recalculation on scroll
- Often load immediately on Page View even if the user never opens the chat

**Fix:** Lazy-load chat widget after user interaction or after a delay:

```javascript
// Load chat after 5 seconds of inactivity
setTimeout(function() {
  window.Tidio && window.Tidio.init();
  // or dynamically inject the script tag here
}, 5000);
```

Or load only when the user scrolls to the chat widget area using Intersection Observer.

### Fonts (Google Fonts, Adobe Fonts)

External font loading delays text rendering (LCP if text is the LCP element)
and causes FOUT (Flash of Unstyled Text) if `font-display: swap` is not set.

**Google Fonts — preconnect:**
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=...&display=swap">
```

**Better fix — self-host fonts:**
```html
<style>
  @font-face {
    font-family: 'Open Sans';
    src: url('/fonts/open-sans.woff2') format('woff2');
    font-display: swap;
    font-weight: 400;
    font-style: normal;
  }
</style>
```
Self-hosted fonts eliminate the third-party DNS lookup and allow preloading:
```html
<link rel="preload" as="font" href="/fonts/open-sans.woff2"
      type="font/woff2" crossorigin>
```

### Maps (Google Maps, Mapbox)

Google Maps embeds load a large JS library (~300KB) plus map tiles.
If the map is below the fold, this is pure waste on initial load.

**Fix — facade pattern:**
```html
<!-- Show a static map image; load interactive map on click -->
<div id="map-placeholder" style="cursor:pointer">
  <img src="/images/map-preview.jpg" alt="Location map" loading="lazy"
       onclick="loadGoogleMaps()" width="600" height="400">
</div>

<script>
function loadGoogleMaps() {
  const script = document.createElement('script');
  script.src = 'https://maps.googleapis.com/maps/api/js?key=KEY&callback=initMap';
  document.head.appendChild(script);
  document.getElementById('map-placeholder').remove();
}
</script>
```

### Video embeds (YouTube, Vimeo)

Same pattern as maps: the YouTube player loads ~500KB of JS immediately.

**Fix — YouTube lite embed (facade pattern):**
```html
<!-- lite-youtube-embed or youtube-nocookie.com -->
<lite-youtube videoid="VIDEO_ID"></lite-youtube>
```
Or use `youtube-nocookie.com` embed and load iframe only on click.

---

## Auditing the third-party footprint

### Via Chrome DevTools

1. Open page in incognito (eliminates browser extensions)
2. DevTools > Network tab > reload
3. Filter by domain: click "All" then sort by Domain column
4. Third-party = any domain that is not the site's own domain

Look for:
- Scripts from unknown domains
- Large JS files from marketing vendors
- Multiple scripts from the same vendor (often misconfiguration)

### Via Screaming Frog

SF > Reports > Source Code > Custom Search for `src="https://` — exports
all external script URLs, which can be grouped by domain.

### Via PageSpeed Insights

PSI > "Reduce the impact of third-party code" diagnostic.
Shows: vendor, blocking time, and main thread usage per third-party.

### Identifying unused scripts

1. Chrome DevTools > Coverage tab (Ctrl+Shift+P > "Coverage")
2. Reload the page
3. Scripts with >70% unused bytes are candidates for removal or conditional loading

---

## GTM-based deferral strategies

GTM is a double-edged tool: it makes it easy to add scripts, and easy to accumulate
scripts that no one remembers adding.

### GTM tag audit

1. GTM container > Tags tab
2. Check "Last Edited" column for tags not touched in 6+ months
3. Check firing frequency in Preview Mode — tags that never fire can be paused

**Common tag bloat:**
- Old A/B testing scripts (Optimize is deprecated — remove)
- Duplicate GA4 tags (one configured via GTM, another via gtag snippet in theme)
- Pixel for a campaign that ended months ago

### Deferral via trigger optimization

| Script type | Recommended trigger |
|-------------|-------------------|
| GA4 page view | Initialization - All Pages |
| GA4 events | DOM Ready (for scroll, click) |
| Facebook Pixel | DOM Ready |
| Remarketing tags | Window Loaded |
| Chat widget | Custom timer (5000ms) or scroll depth |
| Heatmap tools | Window Loaded |

Scripts on "Window Loaded" execute after the page is visually complete → 
zero impact on LCP or FCP.

### Tag sequencing in GTM

For scripts that must load in order (e.g., a custom dataLayer push before a GA4 event):
GTM > Tag > Advanced Settings > Tag Sequencing > "Fire a tag before [tag name] fires"

This guarantees execution order without relying on trigger timing assumptions.

---

## Removing unused scripts

1. Identify unused scripts via Coverage tab or GTM audit
2. Verify with the client/team that the script is truly unused (check business requirements)
3. Remove from GTM container or theme (do not just pause — paused tags still add container size)
4. Test in GTM Preview that no events break
5. Publish container
6. Verify PSI improvement

---

## Audit checklist

```
CRITICAL (direct CWV impact)
[ ] No render-blocking scripts in <head> without async or defer
[ ] LCP element not delayed by third-party script execution
[ ] No duplicate analytics tags (GTM + inline gtag.js simultaneously)

HIGH (INP and TBT)
[ ] Chat widget not loading on Page View (should load after interaction or delay)
[ ] Hotjar/Clarity not running simultaneously
[ ] Total third-party blocking time < 200ms (PSI "Reduce third-party code")
[ ] No scripts loading > 300KB uncompressed from third-party domains

MEDIUM (optimization)
[ ] GTM tag audit: no tags unused for 6+ months
[ ] Remarketing and ad tags on Window Loaded trigger (not Page View)
[ ] Google Fonts self-hosted or with preconnect + display=swap
[ ] Maps and video embeds use facade pattern (no immediate load)
[ ] PSI "Reduce the impact of third-party code": < 500ms total

LOW (maintenance)
[ ] GTM container size < 200KB (minified)
[ ] No deprecated scripts (Google Optimize, UA analytics)
[ ] Script inventory documented (what runs and why)
[ ] Coverage tab: no scripts with > 80% unused bytes on initial load
```
