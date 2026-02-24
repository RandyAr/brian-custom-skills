# Outlook-Specific Email Development Reference

Microsoft Outlook desktop (2007-2023) uses the **Microsoft Word rendering engine** for HTML emails, making it the most challenging email client to develop for. This reference documents every major quirk and the proven workarounds.

---

## Table of Contents

1. [MSO Conditional Comments](#mso-conditional-comments)
2. [VML for Rounded Corners and Backgrounds](#vml-for-rounded-corners-and-backgrounds)
3. [Word Rendering Engine Quirks](#word-rendering-engine-quirks)
4. [DPI Scaling Issues and Fixes](#dpi-scaling-issues-and-fixes)
5. [Ghost Tables for Responsive Layouts](#ghost-tables-for-responsive-layouts)
6. [Line-Height and Padding Workarounds](#line-height-and-padding-workarounds)
7. [Image Spacing Bugs and Fixes](#image-spacing-bugs-and-fixes)
8. [Background Images in Outlook](#background-images-in-outlook)
9. [List Rendering Issues](#list-rendering-issues)

---

## MSO Conditional Comments

Outlook desktop supports Microsoft-specific conditional comments that allow you to serve Outlook-only HTML. These are ignored by all other email clients and browsers.

### Syntax

```html
<!--[if mso]>
  Outlook-only content here
<![endif]-->

<!--[if !mso]><!-->
  Non-Outlook content here
<!--<![endif]-->
```

### Targeting Specific Outlook Versions

| Conditional | Targets |
|---|---|
| `<!--[if mso]>` | All Outlook versions using Word engine |
| `<!--[if mso 12]>` | Outlook 2007 |
| `<!--[if mso 14]>` | Outlook 2010 |
| `<!--[if mso 15]>` | Outlook 2013 |
| `<!--[if mso 16]>` | Outlook 2016, 2019, 2021, 2023, and Microsoft 365 desktop |
| `<!--[if gte mso 12]>` | Outlook 2007 and later |
| `<!--[if lte mso 14]>` | Outlook 2010 and earlier |
| `<!--[if gt mso 14]>` | Greater than Outlook 2010 (2013+) |
| `<!--[if lt mso 16]>` | Less than Outlook 2016 |

### Operators

| Operator | Meaning |
|---|---|
| `mso` | Equals (any version) |
| `mso XX` | Equals specific version |
| `gte mso XX` | Greater than or equal to |
| `gt mso XX` | Greater than |
| `lte mso XX` | Less than or equal to |
| `lt mso XX` | Less than |
| `!mso` | NOT Outlook |

### Common Use Cases

**Hiding content from Outlook:**
```html
<!--[if !mso]><!-->
<div style="display:inline-block; max-width:300px;">
  <!-- Responsive content Outlook can't handle -->
</div>
<!--<![endif]-->
```

**Providing Outlook-specific fallback:**
```html
<!--[if mso]>
<table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0">
<tr><td>
<![endif]-->
  <!-- Content here -->
<!--[if mso]>
</td></tr>
</table>
<![endif]-->
```

---

## VML for Rounded Corners and Backgrounds

Since Outlook does not support `border-radius` or CSS `background-image`, VML (Vector Markup Language) is used as a replacement.

### Bulletproof Rounded Button

```html
<!--[if mso]>
<v:roundrect xmlns:v="urn:schemas-microsoft-com:vml"
             xmlns:w="urn:schemas-microsoft-com:office:word"
             href="https://example.com"
             style="height:44px;v-text-anchor:middle;width:200px;"
             arcsize="10%"
             stroke="f"
             fillcolor="#4F46E5">
  <w:anchorlock/>
  <center>
<![endif]-->
<a href="https://example.com"
   style="background-color:#4F46E5;border-radius:4px;color:#ffffff;display:inline-block;
          font-family:Arial,Helvetica,sans-serif;font-size:16px;font-weight:bold;
          line-height:44px;text-align:center;text-decoration:none;width:200px;
          -webkit-text-size-adjust:none;">
  Button Text
</a>
<!--[if mso]>
  </center>
</v:roundrect>
<![endif]-->
```

**Key VML attributes:**
- `arcsize` — Border radius as percentage of the shape height (e.g., `10%` roughly equals `4px` radius on a `44px` button)
- `fillcolor` — Background color (must match the CSS `background-color`)
- `stroke="f"` — Disables the border/stroke
- `v-text-anchor:middle` — Vertically centers text
- `w:anchorlock` — Prevents the link from being resized by Word

### VML Rectangle (No Rounded Corners)

```html
<!--[if mso]>
<v:rect xmlns:v="urn:schemas-microsoft-com:vml"
        style="width:200px;height:44px;"
        stroke="f"
        fillcolor="#4F46E5">
  <v:textbox inset="0,0,0,0" style="mso-fit-shape-to-text:true;">
    <center>
<![endif]-->
<a href="https://example.com" style="background-color:#4F46E5;color:#ffffff;display:inline-block;font-family:Arial,Helvetica,sans-serif;font-size:16px;line-height:44px;text-align:center;text-decoration:none;width:200px;">
  Button Text
</a>
<!--[if mso]>
    </center>
  </v:textbox>
</v:rect>
<![endif]-->
```

### VML Background with Rounded Corners on a Container

```html
<!--[if mso]>
<v:roundrect xmlns:v="urn:schemas-microsoft-com:vml"
             xmlns:w="urn:schemas-microsoft-com:office:word"
             style="width:600px;height:auto;"
             arcsize="2%"
             stroke="f"
             fillcolor="#F3F4F6">
  <v:textbox style="mso-fit-shape-to-text:true;" inset="20px,20px,20px,20px">
<![endif]-->
<div style="background-color:#F3F4F6; border-radius:8px; padding:20px;">
  <!-- Container content -->
</div>
<!--[if mso]>
  </v:textbox>
</v:roundrect>
<![endif]-->
```

---

## Word Rendering Engine Quirks

Outlook 2007-2023 and Microsoft 365 desktop use Microsoft Word to render HTML. This means:

### What Word Does NOT Support

| Feature | Behavior in Outlook |
|---|---|
| `max-width` | Ignored completely. Tables expand to full width or use explicit `width`. |
| `border-radius` | Ignored. All corners are square. Use VML for rounded shapes. |
| `background-image` (CSS) | Ignored. Use VML `v:fill` for background images. |
| `float` | Ignored. Use table cells for column layouts. |
| `position` | Ignored. No absolute, relative, or fixed positioning. |
| `display: flex/grid` | Ignored. Use tables. |
| `display: block` on inline elements | Unreliable. Use tables instead. |
| `box-shadow` | Ignored. |
| `opacity` | Ignored. |
| `overflow: hidden` | Ignored. |
| `margin` on `<div>` | Partially supported; unreliable. Use table cell padding. |
| `padding` on `<p>`, `<div>`, `<a>` | Ignored on many elements. Apply `padding` only to `<td>`. |
| Media queries | Ignored. Outlook uses fixed-width rendering. |
| CSS animations/transitions | Ignored. |
| Web fonts | Ignored. Falls back to system fonts. |
| SVG | Not rendered. Use PNG/GIF fallback. |
| `<video>` / `<audio>` | Not supported. Use fallback image. |

### What Word Handles Differently

| Feature | Quirk |
|---|---|
| `line-height` | Only supports exact pixel values on `<td>` and block elements. Does not work on `<a>` tags. |
| `padding` | Only reliably works on `<td>` elements. Does NOT work on `<p>`, `<div>`, `<a>`, or `<span>`. |
| `margin` | Works on `<p>` elements but adds extra spacing by default. Use `margin:0` to reset. |
| Table widths | Requires explicit `width` attribute (not just CSS). Use both `width="600"` and `style="width:600px"`. |
| Font rendering | Word renders fonts slightly larger/wider than browsers. Test with actual Outlook. |
| `mso-line-height-rule: exactly` | Required to force exact line-height values. Without it, Word may add extra space. |
| Cell spacing | Word may add 1-2px of extra space between table cells. Use `border-collapse:collapse` and `mso-table-lspace:0pt; mso-table-rspace:0pt`. |

### Outlook-Specific CSS Properties

These MSO-prefixed properties only work in Outlook:

```css
/* Force exact line-height */
mso-line-height-rule: exactly;

/* Remove table cell spacing */
mso-table-lspace: 0pt;
mso-table-rspace: 0pt;

/* Control paragraph spacing */
mso-margin-top-alt: 0;
mso-margin-bottom-alt: 0;

/* Font fallback control */
mso-font-alt: Arial;

/* Prevent text size adjustment */
mso-text-raise: 0;

/* Table-specific */
mso-table-lspace: 0;
mso-table-rspace: 0;
mso-padding-alt: 0;
```

---

## DPI Scaling Issues and Fixes

Outlook desktop applies Windows DPI scaling to emails, which can cause images and layouts to render at unexpected sizes on high-DPI displays (125%, 150%, 200% scaling).

### The Problem

On a 150% DPI display, a 600px-wide image may render at 900px, breaking the layout.

### The Fix: PixelsPerInch Declaration

Always include this in your `<head>`:

```html
<!--[if mso]>
<noscript>
  <xml>
    <o:OfficeDocumentSettings>
      <o:PixelsPerInch>96</o:PixelsPerInch>
    </o:OfficeDocumentSettings>
  </xml>
</noscript>
<![endif]-->
```

This tells Outlook to render at 96 DPI regardless of the system DPI setting.

### Additional DPI Tips

1. **Always set `width` and `height` attributes on images** — not just CSS dimensions:
   ```html
   <img src="image.jpg" width="600" height="400" style="width:600px; height:auto; display:block;">
   ```

2. **Use the `width` attribute on tables and cells** in addition to CSS:
   ```html
   <table width="600" style="width:600px;">
   ```

3. **Avoid percentage widths on images** in Outlook. Use fixed pixel values for predictable rendering.

---

## Ghost Tables for Responsive Layouts

Since Outlook ignores `max-width`, `display:inline-block`, and media queries, you need "ghost tables" — Outlook-only wrapper tables that enforce fixed-width layouts.

### Basic Ghost Table Pattern

```html
<!--[if mso]>
<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" align="center">
<tr>
<td>
<![endif]-->

<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width:600px; margin:0 auto;">
  <tr>
    <td>
      <!-- Content -->
    </td>
  </tr>
</table>

<!--[if mso]>
</td>
</tr>
</table>
<![endif]-->
```

### Two-Column Ghost Table

```html
<!--[if mso]>
<table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0" align="center">
<tr>
<td width="290" valign="top">
<![endif]-->

<div style="display:inline-block; width:100%; max-width:290px; vertical-align:top;" class="stack-column">
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
    <tr>
      <td style="padding:10px;">
        Column 1
      </td>
    </tr>
  </table>
</div>

<!--[if mso]>
</td>
<td width="20"></td>
<td width="290" valign="top">
<![endif]-->

<div style="display:inline-block; width:100%; max-width:290px; vertical-align:top;" class="stack-column">
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
    <tr>
      <td style="padding:10px;">
        Column 2
      </td>
    </tr>
  </table>
</div>

<!--[if mso]>
</td>
</tr>
</table>
<![endif]-->
```

### Three-Column Ghost Table

```html
<!--[if mso]>
<table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0" align="center">
<tr>
<td width="186" valign="top">
<![endif]-->
<div style="display:inline-block; width:100%; max-width:186px; vertical-align:top;" class="stack-column">
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
    <tr><td style="padding:10px;">Column 1</td></tr>
  </table>
</div>
<!--[if mso]>
</td>
<td width="14"></td>
<td width="186" valign="top">
<![endif]-->
<div style="display:inline-block; width:100%; max-width:186px; vertical-align:top;" class="stack-column">
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
    <tr><td style="padding:10px;">Column 2</td></tr>
  </table>
</div>
<!--[if mso]>
</td>
<td width="14"></td>
<td width="186" valign="top">
<![endif]-->
<div style="display:inline-block; width:100%; max-width:186px; vertical-align:top;" class="stack-column">
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
    <tr><td style="padding:10px;">Column 3</td></tr>
  </table>
</div>
<!--[if mso]>
</td>
</tr>
</table>
<![endif]-->
```

---

## Line-Height and Padding Workarounds

### Line-Height

Outlook's Word engine handles line-height differently from browsers.

**Problem:** Line-height on text elements may be ignored or rendered inconsistently.

**Solution:** Use `mso-line-height-rule: exactly` alongside standard `line-height`:

```html
<td style="font-family:Arial, Helvetica, sans-serif; font-size:16px; line-height:24px; mso-line-height-rule:exactly; color:#1F2937;">
  Your text content here.
</td>
```

**For spacer rows**, always include `mso-line-height-rule:exactly`:

```html
<tr>
  <td style="font-size:1px; line-height:1px; mso-line-height-rule:exactly; height:20px;">&nbsp;</td>
</tr>
```

### Padding

**Problem:** Outlook only supports `padding` on `<td>` elements. It ignores padding on `<p>`, `<div>`, `<a>`, `<span>`, and other elements.

**Solution:** Always use `<td>` for spacing:

```html
<!-- WRONG: padding on <p> — ignored in Outlook -->
<p style="padding:20px;">Text</p>

<!-- RIGHT: padding on <td> -->
<td style="padding:20px;">
  <p style="margin:0;">Text</p>
</td>
```

**For button padding**, use `line-height` instead of `padding` to create vertical space:

```html
<!-- WRONG: padding on <a> — ignored in Outlook -->
<a style="padding:12px 24px;">Button</a>

<!-- RIGHT: line-height for height, width for horizontal -->
<a style="display:inline-block; line-height:44px; width:200px; text-align:center;">Button</a>
```

### Paragraph Spacing

Outlook adds default margins to `<p>` tags (approximately 1em top and bottom).

**Fix:** Always reset paragraph margins:

```html
<p style="margin:0; mso-margin-top-alt:0; mso-margin-bottom-alt:0;">Text</p>
```

Or use `<td>` instead of `<p>` for text containers.

---

## Image Spacing Bugs and Fixes

### The Gap Below Images

**Problem:** Outlook adds a small gap (usually 1-4px) below images, even with `display:block`.

**Fix:** Apply all of these to every image:

```html
<img src="image.jpg" alt="Alt text"
     width="600"
     height="400"
     style="display:block; border:0; outline:none; text-decoration:none; -ms-interpolation-mode:bicubic; width:600px; height:auto;"
>
```

Key properties:
- `display:block` — removes inline spacing
- `border:0` — removes default image border
- `-ms-interpolation-mode:bicubic` — improves image scaling quality in IE/Outlook

### Image Scaling

**Problem:** On high-DPI displays, Outlook may scale images up, making them blurry.

**Fix:**
1. Include the `PixelsPerInch` declaration (see DPI section above)
2. Always set explicit `width` and `height` HTML attributes
3. For retina support, use 2x images with constrained dimensions:

```html
<!-- 2x image (1200px wide) displayed at 600px -->
<img src="image@2x.jpg" alt="Alt text" width="600" height="400" style="width:600px; height:auto; display:block;">
```

### Image Links Gaps

**Problem:** When wrapping images in `<a>` tags, Outlook may add a blue border or extra spacing.

**Fix:**
```html
<a href="https://example.com" style="display:block; border:0; outline:none; text-decoration:none;">
  <img src="image.jpg" alt="Alt text" width="600" style="display:block; border:0; width:600px; height:auto;">
</a>
```

### Outlook Image Size Limit

**Problem:** Outlook may not render images wider than approximately 1728px.

**Fix:** Keep source images under 1728px wide. For retina, 1200px (2x of 600px email width) is the recommended maximum.

---

## Background Images in Outlook

CSS `background-image` does not work in Outlook desktop. Use VML instead.

### Full-Width Background Image

```html
<!--[if mso]>
<v:rect xmlns:v="urn:schemas-microsoft-com:vml" fill="true" stroke="false" style="width:600px;height:300px;">
  <v:fill type="frame" src="https://example.com/background.jpg" color="#1F2937"/>
  <v:textbox style="mso-fit-shape-to-text:true;" inset="0,0,0,0">
<![endif]-->

<div style="background-image:url('https://example.com/background.jpg'); background-color:#1F2937; background-size:cover; background-position:center;">
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
    <tr>
      <td style="padding:40px; font-family:Arial, Helvetica, sans-serif; font-size:16px; line-height:24px; color:#ffffff;">
        Content over background image
      </td>
    </tr>
  </table>
</div>

<!--[if mso]>
  </v:textbox>
</v:rect>
<![endif]-->
```

### Background Image with Bulletproof Approach (backgrounds.cm)

For a more robust solution, use the pattern from backgrounds.cm:

```html
<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
  <tr>
    <td background="https://example.com/background.jpg" bgcolor="#1F2937" valign="top" style="background-image:url('https://example.com/background.jpg'); background-color:#1F2937; background-size:cover; background-position:center center;">
      <!--[if gte mso 9]>
      <v:rect xmlns:v="urn:schemas-microsoft-com:vml" fill="true" stroke="false" style="width:600px;height:300px;">
        <v:fill type="tile" src="https://example.com/background.jpg" color="#1F2937"/>
        <v:textbox inset="0,0,0,0">
      <![endif]-->
      <div>
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
          <tr>
            <td style="padding:40px;">
              <!-- Content here -->
            </td>
          </tr>
        </table>
      </div>
      <!--[if gte mso 9]>
        </v:textbox>
      </v:rect>
      <![endif]-->
    </td>
  </tr>
</table>
```

### VML Fill Types

| Type | Behavior |
|---|---|
| `frame` | Stretches image to fill the shape (like `background-size: cover`) |
| `tile` | Tiles/repeats the image |
| `pattern` | Similar to tile but with pattern options |
| `gradient` | Gradient fill (not an image) |

---

## List Rendering Issues

### The Problem

Outlook renders `<ul>` and `<ol>` with inconsistent margins, padding, and bullet styles. The bullet indent is often much larger than expected.

### Fix 1: Reset List Styles

```html
<ul style="margin:0; padding:0; mso-special-format:bullet;">
  <li style="margin:0 0 8px 20px; padding:0; mso-special-format:bullet; color:#1F2937; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px;">
    List item one
  </li>
  <li style="margin:0 0 8px 20px; padding:0; mso-special-format:bullet; color:#1F2937; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px;">
    List item two
  </li>
</ul>
```

### Fix 2: Fake Lists with Tables (Most Reliable)

For pixel-perfect control, avoid `<ul>`/`<ol>` entirely and use tables:

```html
<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
  <tr>
    <td width="20" valign="top" style="padding:0 8px 8px 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px; color:#4F46E5;">&#8226;</td>
    <td valign="top" style="padding:0 0 8px 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px; color:#1F2937;">
      First list item text
    </td>
  </tr>
  <tr>
    <td width="20" valign="top" style="padding:0 8px 8px 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px; color:#4F46E5;">&#8226;</td>
    <td valign="top" style="padding:0 0 8px 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px; color:#1F2937;">
      Second list item text
    </td>
  </tr>
</table>
```

For ordered lists, replace `&#8226;` with numbers:

```html
<td width="20" valign="top" style="...">1.</td>
<td valign="top" style="...">First item</td>
```

### Fix 3: Conditional Outlook Styles

If you must use real lists, add Outlook-specific margin overrides:

```html
<!--[if mso]>
<style>
  ul, ol { margin-left: 20px !important; }
  li { margin-bottom: 8px !important; }
</style>
<![endif]-->
```

---

## Quick Reference: Outlook Version Numbers

| Product Name | Internal Version | Rendering Engine |
|---|---|---|
| Outlook 2007 | 12 | Word 2007 |
| Outlook 2010 | 14 | Word 2010 |
| Outlook 2013 | 15 | Word 2013 |
| Outlook 2016 | 16 | Word 2016 |
| Outlook 2019 | 16 | Word 2016 |
| Outlook 2021 | 16 | Word 2016 |
| Outlook 2023 | 16 | Word 2016 |
| Microsoft 365 (Desktop) | 16 | Word 2016 |
| New Outlook for Windows | N/A | Web-based (Outlook.com engine) |
| Outlook for Mac | N/A | WebKit |
| Outlook for iOS | N/A | Native WebView |
| Outlook for Android | N/A | Native WebView |
| Outlook.com (Web) | N/A | Custom web renderer |

> **Note:** The "New Outlook for Windows" is web-based and uses the same rendering engine as Outlook.com, which has much better CSS support than the classic Word-based desktop client. However, as of early 2026, many enterprise users still use the classic Outlook desktop client.
