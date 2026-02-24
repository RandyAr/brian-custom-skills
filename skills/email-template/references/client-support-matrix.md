# Email Client CSS Support Matrix

A comprehensive reference for CSS and HTML feature support across major email clients. Use this matrix when making design decisions to ensure maximum compatibility.

> **Last updated:** February 2026
> **Sources:** [Can I Email](https://www.caniemail.com), [Campaign Monitor CSS Guide](https://www.campaignmonitor.com/css/), community testing

---

## CSS Property Support

| CSS Property | Gmail (Web) | Gmail (Android) | Gmail (iOS) | Outlook 2016-2023 | Outlook 365 | Outlook.com | Apple Mail (macOS) | Apple Mail (iOS) | Yahoo Mail | Thunderbird |
|---|---|---|---|---|---|---|---|---|---|---|
| `background-color` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `background-image` | No | No | No | Partial (VML) | Partial (VML) | Yes | Yes | Yes | Yes | Yes |
| `background-position` | No | No | No | No | No | Yes | Yes | Yes | Yes | Yes |
| `background-repeat` | No | No | No | No | No | Yes | Yes | Yes | Yes | Yes |
| `background-size` | No | No | No | No | No | Yes | Yes | Yes | Partial | Yes |
| `border` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `border-radius` | Yes | Yes | Yes | No | Partial | Yes | Yes | Yes | Yes | Yes |
| `border-collapse` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `border-spacing` | Yes | Yes | Yes | No | No | Yes | Yes | Yes | Yes | Yes |
| `box-shadow` | No | No | No | No | No | Yes | Yes | Yes | No | Yes |
| `color` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `display` | Partial | Partial | Partial | Partial | Partial | Partial | Yes | Yes | Partial | Yes |
| `float` | No | No | No | No | No | No | Yes | Yes | No | Yes |
| `font-family` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `font-size` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `font-style` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `font-weight` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `height` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `letter-spacing` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `line-height` | Yes | Yes | Yes | Partial | Partial | Yes | Yes | Yes | Yes | Yes |
| `margin` | Yes | Yes | Yes | Partial | Partial | Yes | Yes | Yes | Yes | Yes |
| `max-width` | Yes | Yes | Yes | No | No | Yes | Yes | Yes | Yes | Yes |
| `min-width` | Yes | Yes | Yes | No | No | Yes | Yes | Yes | Yes | Yes |
| `opacity` | Yes | Yes | Yes | No | No | Yes | Yes | Yes | Yes | Yes |
| `overflow` | Yes | Yes | Yes | No | No | Yes | Yes | Yes | Yes | Yes |
| `padding` | Yes | Yes | Yes | Partial | Partial | Yes | Yes | Yes | Yes | Yes |
| `text-align` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `text-decoration` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `text-transform` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `vertical-align` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `width` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `word-spacing` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `white-space` | Yes | Yes | Yes | Partial | Partial | Yes | Yes | Yes | Yes | Yes |

### Layout CSS Properties

| CSS Property | Gmail (Web) | Gmail (Android) | Gmail (iOS) | Outlook 2016-2023 | Outlook 365 | Outlook.com | Apple Mail (macOS) | Apple Mail (iOS) | Yahoo Mail | Thunderbird |
|---|---|---|---|---|---|---|---|---|---|---|
| `flexbox` | No | No | No | No | No | No | Yes | Yes | No | Yes |
| `grid` | No | No | No | No | No | No | Yes | Yes | No | Yes |
| `position` | No | No | No | No | No | No | Yes | Yes | No | Yes |
| `transform` | No | No | No | No | No | No | Yes | Yes | No | Yes |
| `transition` | No | No | No | No | No | No | Yes | Yes | No | Partial |
| `animation` | No | No | No | No | No | No | Yes | Yes | No | Partial |
| `object-fit` | No | No | No | No | No | No | Yes | Yes | No | Yes |

---

## Media Query Support

| Feature | Gmail (Web) | Gmail (Android) | Gmail (iOS) | Outlook 2016-2023 | Outlook 365 | Outlook.com | Apple Mail (macOS) | Apple Mail (iOS) | Yahoo Mail | Thunderbird |
|---|---|---|---|---|---|---|---|---|---|---|
| `@media` queries | No | No | Yes | No | No | Yes | Yes | Yes | No | Yes |
| `max-width` query | No | No | Yes | No | No | Yes | Yes | Yes | No | Yes |
| `min-width` query | No | No | Yes | No | No | Yes | Yes | Yes | No | Yes |
| `prefers-color-scheme` | No | No | Yes | No | No | Partial | Yes | Yes | No | Yes |
| `prefers-reduced-motion` | No | No | No | No | No | No | Yes | Yes | No | Yes |

**Key takeaway:** Gmail (web and Android) strips `<style>` blocks entirely, so all critical styles must be inlined. Gmail on iOS (via Apple's WebKit) supports embedded styles and media queries.

---

## HTML Element Support

| HTML Element | Gmail (Web) | Gmail (Android) | Gmail (iOS) | Outlook 2016-2023 | Outlook 365 | Outlook.com | Apple Mail (macOS) | Apple Mail (iOS) | Yahoo Mail | Thunderbird |
|---|---|---|---|---|---|---|---|---|---|---|
| `<table>` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `<div>` | Yes | Yes | Yes | Partial | Partial | Yes | Yes | Yes | Yes | Yes |
| `<span>` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `<p>` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `<a>` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `<img>` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `<section>` | Yes | Yes | Yes | No | No | Yes | Yes | Yes | Yes | Yes |
| `<article>` | Yes | Yes | Yes | No | No | Yes | Yes | Yes | Yes | Yes |
| `<header>` | Yes | Yes | Yes | No | No | Yes | Yes | Yes | Yes | Yes |
| `<footer>` | Yes | Yes | Yes | No | No | Yes | Yes | Yes | Yes | Yes |
| `<figure>` | Yes | Yes | Yes | No | No | Yes | Yes | Yes | Yes | Yes |
| `<video>` | No | No | No | No | No | No | Yes | Yes | No | No |
| `<audio>` | No | No | No | No | No | No | Yes | Yes | No | No |
| `<svg>` (inline) | No | No | No | No | No | No | Yes | Yes | No | Yes |
| `<form>` | No | No | No | No | No | Partial | Yes | Yes | No | Yes |
| `<input>` | No | No | No | No | No | No | Yes | Yes | No | Yes |
| `<button>` | No | No | No | No | No | No | Yes | Yes | No | Yes |

---

## Other Features

| Feature | Gmail (Web) | Gmail (Android) | Gmail (iOS) | Outlook 2016-2023 | Outlook 365 | Outlook.com | Apple Mail (macOS) | Apple Mail (iOS) | Yahoo Mail | Thunderbird |
|---|---|---|---|---|---|---|---|---|---|---|
| Web fonts (`@font-face`) | No | No | Yes | No | No | No | Yes | Yes | No | Yes |
| Embedded CSS (`<style>`) | Yes | No | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| External CSS (`<link>`) | No | No | No | No | No | No | No | No | No | No |
| CSS variables (`--custom`) | No | No | No | No | No | No | Yes | Yes | No | Yes |
| `calc()` | No | No | No | No | No | No | Yes | Yes | No | Yes |
| `:hover` pseudo-class | No | No | No | No | No | Yes | Yes | Yes | No | Yes |
| `:active` pseudo-class | No | No | No | No | No | No | Yes | Yes | No | Yes |
| `:nth-child` | No | No | No | No | No | Yes | Yes | Yes | No | Yes |
| `!important` | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `data-*` attributes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| `role` attribute | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Conditional comments | No | No | No | Yes | Yes | No | No | No | No | No |
| VML | No | No | No | Yes | Yes | No | No | No | No | No |

---

## Rendering Engine Reference

| Email Client | Rendering Engine | Notes |
|---|---|---|
| Gmail (Web) | Custom (strips `<style>` on non-GANGA) | Inlines CSS, strips classes in some contexts, prefixes class names |
| Gmail (Android) | Custom WebView | Strips `<style>` blocks entirely |
| Gmail (iOS) | WebKit (Apple) | Best Gmail rendering; supports `<style>` and media queries |
| Outlook 2007-2023 | **Microsoft Word** | Worst CSS support; no `border-radius`, no `max-width`, limited `padding` |
| Outlook 365 (Desktop) | **Microsoft Word** | Same as Outlook 2007-2023 |
| Outlook 365 (Mac) | WebKit | Much better than Windows Outlook |
| Outlook.com (Web) | Custom | Decent support; strips some styles |
| Outlook (iOS/Android) | Native WebView | Good support; similar to Outlook.com |
| Apple Mail (macOS) | WebKit | Best-in-class rendering; supports nearly everything |
| Apple Mail (iOS) | WebKit | Same excellent rendering as macOS |
| Yahoo Mail | Custom | Strips some CSS; no media queries |
| Thunderbird | Gecko | Good modern CSS support |

---

## Practical Recommendations

### Safe to Use Everywhere
- `background-color`
- `border` (solid only)
- `color`
- `font-family` (web-safe stacks only)
- `font-size` (px units)
- `font-weight`
- `height` / `width` (on tables and cells)
- `line-height` (px units)
- `margin` (on block elements; use padding on `<td>` for Outlook)
- `padding` (on `<td>` elements; NOT on `<p>`, `<div>`, or `<a>` for Outlook)
- `text-align`
- `text-decoration`
- `vertical-align`
- Inline styles

### Use with Caution (Progressive Enhancement)
- `border-radius` — degrades to square corners in Outlook desktop
- `box-shadow` — not supported in Gmail or Outlook; use as enhancement only
- `max-width` — not supported in Outlook desktop; use MSO ghost tables as fallback
- `background-image` — use VML for Outlook; not supported in Gmail
- Web fonts — fallback font-stack required; only Apple Mail and a few others support them

### Avoid Entirely
- `flexbox` / `grid` — no support in Gmail, Outlook, or Yahoo
- `position` — stripped by most clients
- `float` — unreliable; use table cells or inline-block with MSO fallback
- `<form>` / `<input>` / `<button>` — stripped by most clients
- `<video>` / `<audio>` — only Apple Mail supports; provide fallback image
- JavaScript — universally stripped
- External CSS — universally stripped
- CSS variables — only Apple Mail and Thunderbird
