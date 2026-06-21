---
name: geo-ai-discoverability
description: >
  GEO (Generative Engine Optimization): optimize content and site signals so that
  AI tools (Google AI Overviews, Google AI Mode, ChatGPT, Perplexity, Bing Copilot)
  cite, reference, and surface the site. Covers llms.txt, AI crawler access, Wikidata
  entity hygiene, passage-level citability, brand mention signals, and platform-specific
  patterns including AI Mode vs AI Overviews distinction. Use when auditing AI visibility,
  implementing llms.txt, or analyzing why a site is not cited by AI assistants.
---

# GEO — Generative Engine Optimization

> GEO is not a replacement for SEO — it is a layer on top of it. A site that ranks
> poorly in organic search will also perform poorly in AI-generated responses.
> Fix technical SEO and content quality first; then apply GEO signals.

---

## What AI tools need to cite a source

AI citation requires four conditions, in order of priority:

1. **Crawlability** — the AI crawler can access the page
2. **Passage-level answer density** — the page contains a clear, extractable answer
3. **Entity clarity** — the site/brand/author is a known, unambiguous entity
4. **Freshness signals** — the content has a visible, accurate publication date

Missing any of these blocks citation even if the content is excellent.

---

## AI crawler access — robots.txt

### Known AI crawlers (2025–2026)

| Crawler | Platform | User-Agent |
|---------|----------|------------|
| GPTBot | OpenAI / ChatGPT | `GPTBot` |
| OAI-SearchBot | OpenAI SearchGPT | `OAI-SearchBot` |
| PerplexityBot | Perplexity | `PerplexityBot` |
| Googlebot-Extended | Google AI training | `Google-Extended` |
| Anthropic-AI | Claude | `anthropic-ai` |
| Claude-Web | Claude.ai web | `Claude-Web` |
| Cohere-AI | Cohere | `cohere-ai` |
| YouBot | You.com | `YouBot` |

### Recommended robots.txt posture

```
# Allow all AI crawlers for indexing/citation (not training)
User-agent: GPTBot
Disallow:

User-agent: OAI-SearchBot
Disallow:

User-agent: PerplexityBot
Disallow:

User-agent: Google-Extended
Disallow:

User-agent: anthropic-ai
Disallow:

User-agent: Claude-Web
Disallow:
```

**Decision rules:**
- Block `Google-Extended` only if you want to opt out of Google AI training but keep AI Overviews — currently these are separate controls. Blocking Google-Extended does NOT prevent AI Overviews.
- Blocking a citation-mode crawler (GPTBot, PerplexityBot) means the platform cannot index the page for retrieval — it will not cite it.
- Do not block `Googlebot` — this affects organic and AI Overviews simultaneously.

---

## llms.txt — structured site summary for AI

llms.txt is a plain-text or Markdown file at `domain.com/llms.txt` that gives AI
systems a curated, structured overview of the site's content without requiring
a full crawl. It is voluntary and not a standard, but adopted by a growing number
of AI tools.

### Minimal llms.txt structure

```markdown
# Site Name

> One-sentence description of what this site does/covers.

## About

Brief paragraph: who runs the site, editorial standards, date coverage.

## Key topics

- [Section or category name](https://domain.com/section/)
- [Section or category name](https://domain.com/section/)

## Notable content

- [Article title](https://domain.com/article-slug/) — one-line description
- [Article title](https://domain.com/article-slug/) — one-line description

## Contact / Editorial

- Contact: contact@domain.com
- Editorial policy: https://domain.com/editorial-policy/

## Licensing

Content licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Attribution required when reproducing or citing.
```

### Implementation

1. Create the file as static text — do not generate dynamically if it can be avoided
2. Serve at `https://domain.com/llms.txt` (root, not subdirectory)
3. Add to robots.txt as a sitemap-style hint (optional but recommended):
   ```
   # llms.txt
   Sitemap: https://domain.com/llms.txt
   ```
4. For WordPress: add as a static file via FTP, or use a plugin that serves `/llms.txt`

**What to include:** The highest-value pages for your target audience. Not everything —
AI tools read this to build a mental model of the site. Quality over quantity.

---

## Wikidata entity — brand authority signal

Wikidata is the structured data backbone used by Google Knowledge Graph, Wikipedia,
and many AI tools to resolve entity identity. A Wikidata entity for your brand/publication
anchors the organization as a known, citable entity.

### Creating a Wikidata entity

1. Go to https://www.wikidata.org/wiki/Special:NewItem
2. Add label (site name) and description (one line) in at least EN and ES
3. Add aliases (common alternative names, abbreviations)
4. Required statements for a publication/media entity:
   - `instance of` (P31): `online newspaper` / `digital media` / `magazine`
   - `official website` (P856): full URL with HTTPS
   - `country` (P17): España (Q29)
   - `language of work or name` (P407): Spanish (Q1321)
   - `topic's main category` (P910): if applicable
   - `ISSN` (P236): if the publication has an ISSN
5. After creation, note the Q-number and add it to the Organization/NewsMediaOrganization schema via `sameAs`

### Linking schema to Wikidata

```json
"sameAs": [
  "https://www.wikidata.org/wiki/Q[number]",
  "https://www.facebook.com/...",
  "https://www.instagram.com/..."
]
```

### Minimum viable Wikidata presence

- Label + description in EN and ES
- `instance of` (P31) statement
- `official website` (P856) — must match the canonical domain exactly
- At least one external identifier (ISSN, social profile, etc.)

Without `official website` matching the domain exactly, Google may not connect the
Wikidata entity to the site in the Knowledge Graph.

---

## NewsMediaOrganization schema — for publications

For blogs, news sites, and media brands, `NewsMediaOrganization` provides stronger
AI attribution signals than plain `Organization`.

```json
{
  "@context": "https://schema.org",
  "@type": "NewsMediaOrganization",
  "@id": "https://domain.com/#organization",
  "name": "Publication Name",
  "url": "https://domain.com",
  "logo": {
    "@type": "ImageObject",
    "url": "https://domain.com/logo.png",
    "width": 300,
    "height": 300
  },
  "description": "One-sentence editorial mission statement",
  "foundingDate": "2020",
  "inLanguage": "es",
  "publishingPrinciples": "https://domain.com/editorial-policy/",
  "masthead": "https://domain.com/about/",
  "sameAs": [
    "https://www.wikidata.org/wiki/Q[number]",
    "https://www.facebook.com/publication",
    "https://www.instagram.com/publication"
  ]
}
```

**Key fields for AI citation:**
- `publishingPrinciples` — URL to editorial policy page. Google and AI tools use this to assess credibility.
- `masthead` — URL to the about/team page. Required for News eligibility signals.
- `description` — becomes part of how AI tools describe the source when citing it.

**ISSN:** If the publication has an ISSN, add it:
```json
"issn": "XXXX-XXXX"
```
An ISSN is a strong entity authority signal. Apply at https://www.issn.org (free for Spain via BNE).

---

## Passage-level citability — content structure

AI tools extract answers at the passage level, not the page level. A page can rank #1
organically and still not be cited by AI if no individual passage directly answers
the query.

### Citability patterns

**Answer-first structure (most citable pattern):**
```
H2: What is [topic]?
First sentence: [Topic] is [direct definition/answer in one sentence].
Second sentence: [Most important supporting detail].
Rest of paragraph: context, caveats, examples.
```

**Named statistics (most extractable format):**
```
According to [Source] ([Year]), [X%] of [population] [action].
```
Always include: year, source name, and the specific claim. Vague claims ("studies show")
are not extractable.

**List answers (for How/What/When queries):**
```
H2: How to [do X]?
[Answer in one sentence]
1. Step one — brief explanation
2. Step two — brief explanation
```

### Anti-patterns (reduce citability)

- Long introductory paragraphs before the actual answer (AI may stop extracting)
- Answers buried in the middle of long paragraphs
- Claims without a year or source ("experts say", "recently")
- Answers that require reading multiple sections to assemble

---

## E-E-A-T signals for AI citation

AI tools weight sources by authority signals. For content to be cited by ChatGPT,
Perplexity, or AI Overviews, the page/site needs to demonstrate Experience,
Expertise, Authoritativeness, and Trustworthiness in a machine-readable way.

### Minimum E-E-A-T signals

| Signal | Implementation |
|--------|---------------|
| Author name + credentials | Byline visible on page + Person schema with `jobTitle` |
| Author bio page | Dedicated URL with `Person` schema, sameAs LinkedIn |
| About/masthead page | Lists editorial team, contact, mission |
| Editorial policy | Separate page linked from footer/about |
| Sources cited inline | Named sources with links, not "according to experts" |
| Content dates visible | `datePublished` and `dateModified` visible to users |

### Author schema for AI citation

The author `Person` schema `jobTitle` and `description` fields are the primary
signals AI tools use to assess author authority. See `schema-markup` skill for
full implementation patterns.

---

## Brand mention and citation monitoring

### Checking AI citation status

Manual spot-check method (no tool required):

1. Open ChatGPT, Perplexity, Bing Copilot, and Google AI Overviews
2. Ask a question the site should answer (exact match to a key article topic)
3. Check if the site is cited in the sources panel
4. Note which platforms cite and which don't

**Establish a baseline:** Run this check for 5-10 key topics and record results
with date. This is the baseline to compare against after implementing GEO changes.
Allow 4-8 weeks for changes to propagate.

### DataForSEO — LLM mentions tracking

DataForSEO has an LLM mentions API endpoint that tracks brand/domain mentions
across AI responses. Use via `mcp__dfs-mcp__ai_opt_llm_ment_search` for monitoring.

---

## Wikipedia presence

Wikipedia is used as a training source and entity authority signal by most AI systems.
A Wikipedia article about the brand/publication provides the strongest possible entity
signal — stronger than Wikidata alone.

### Notability threshold

Wikipedia requires "notability" — the subject must have significant coverage in
independent, reliable sources. For a publication this means:
- Coverage in established media outlets (not press releases)
- ISSN or institutional recognition
- At minimum 3 independent sources covering the publication (not the content it covers)

### Approach

1. Verify notability before drafting — if no independent sources exist, Wikipedia will
   delete the article quickly regardless of quality
2. Draft in Wikipedia Sandbox first: https://en.wikipedia.org/wiki/Wikipedia:Sandbox
3. Focus on verifiable facts with references, not promotional language
4. After article exists, add Wikidata property `Wikipedia article` (P50) linking to it

**Do not create a Wikipedia article for a brand that lacks documented independent coverage.**
Wikipedia editors will flag and delete non-notable articles, and a deleted Wikipedia
attempt can make future creation harder.

---

## Platform-specific patterns

### Google AI Overviews

- Source: primarily Google's own index — organic ranking matters
- Structured data: FAQPage, HowTo, Article with `datePublished` increase passage extraction
- Answer-first content structure is the primary lever
- No direct submission mechanism — improve organic ranking and content structure

### Google AI Mode

AI Mode is a separate Google surface from AI Overviews, launched in 2025. They share
approximately 13.7% citation overlap — optimizing for one does not automatically
improve the other.

Key differences vs AI Overviews:

| Factor | AI Overviews | AI Mode |
|--------|-------------|---------|
| Trigger | Appended to standard SERP | Dedicated mode (separate tab) |
| Content signal | Topical authority, backlinks | Freshness weighted more heavily |
| Entity signal | Domain authority | Entity authority (Wikidata, sameAs) |
| Citation style | Inline with SERP | Multi-turn, conversational citations |
| Optimization lever | Organic ranking + passage density | Freshness + entity hygiene |

**Optimization for AI Mode:**
- Update content dates visibly and in schema `dateModified`
- Strengthen entity signals: Wikidata Q-number, sameAs with authoritative sources
- Prioritize recency on topics where AI Mode is likely triggered (news, comparisons,
  product research, "best X" queries)
- Monitor separately from AI Overviews — a page cited in one may not appear in the other

### Perplexity

- Source: independent crawler + Bing index
- Cites sources visibly — prioritizes pages with clear authorship and dates
- Verify PerplexityBot is not blocked in robots.txt
- Short, factual passages are preferred over long narrative explanations

### ChatGPT (SearchGPT / web mode)

- Source: Bing index + its own crawler (OAI-SearchBot)
- Check both GPTBot and OAI-SearchBot are allowed in robots.txt
- For knowledge base (training): GPTBot access required; opt-in at https://openai.com/policies/usage-policies

### Bing Copilot

- Source: Bing index — standard Bing SEO applies
- Verify Bing Webmaster Tools shows no crawl issues
- Submit sitemap to Bing Webmaster Tools
- FAQ schema and structured data are weighted more heavily than in Google

---

## Audit checklist

```
CRAWLABILITY
[ ] GPTBot allowed in robots.txt (or intentionally blocked with documented reason)
[ ] OAI-SearchBot allowed
[ ] PerplexityBot allowed
[ ] Google-Extended decision documented (training vs AI Overviews tradeoff understood)

llms.txt
[ ] File exists at /llms.txt
[ ] Includes site description, key sections, notable content
[ ] URLs in llms.txt are canonical and return 200
[ ] File referenced in robots.txt (optional but recommended)

ENTITY
[ ] Wikidata entity exists with correct official website URL
[ ] Wikidata Q-number in Organization/NewsMediaOrganization sameAs
[ ] Schema type matches site type (NewsMediaOrganization for publications, LocalBusiness for businesses)
[ ] publishingPrinciples and masthead fields populated (publications)

CONTENT
[ ] Key pages use answer-first structure
[ ] Statistics include year and named source
[ ] Author schema includes jobTitle and description
[ ] datePublished visible to users and in schema

E-E-A-T
[ ] About/masthead page exists
[ ] Author bio pages exist with Person schema
[ ] Editorial policy page linked from footer

MONITORING
[ ] AI citation baseline established (date + platforms checked + results)
[ ] PerplexityBot not blocked
[ ] DataForSEO LLM mentions tracked for brand name
```
