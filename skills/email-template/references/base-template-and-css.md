# Base Template and CSS Reference

This file contains the foundational boilerplate, customization variables, CSS resets, responsive design techniques, and dark mode CSS for email templates.

---

## Customization Variables

When generating any template, accept and apply these variables:

| Variable | Default | Description |
|---|---|---|
| `brand_primary_color` | `#4F46E5` | Primary buttons, links, accents |
| `brand_secondary_color` | `#7C3AED` | Secondary accents, gradients |
| `brand_text_color` | `#1F2937` | Body text color |
| `brand_bg_color` | `#F9FAFB` | Outer background color |
| `logo_url` | *(placeholder)* | Absolute URL to logo image |
| `company_name` | `Company` | Used in footer and alt text |
| `font_family` | `Arial, Helvetica, sans-serif` | Web-safe font stack |

---

## Base Template Structure

Every email MUST use this boilerplate as its foundation:

```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="color-scheme" content="light dark">
  <meta name="supported-color-schemes" content="light dark">
  <!--[if mso]>
  <noscript>
    <xml>
      <o:OfficeDocumentSettings>
        <o:PixelsPerInch>96</o:PixelsPerInch>
      </o:OfficeDocumentSettings>
    </xml>
  </noscript>
  <![endif]-->
  <title>Email Title</title>
  <style>
    /* === CSS RESETS === */
    body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
    img { -ms-interpolation-mode: bicubic; border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }
    body { height: 100% !important; margin: 0 !important; padding: 0 !important; width: 100% !important; }
    a[x-apple-data-detectors] { color: inherit !important; text-decoration: none !important; font-size: inherit !important; font-family: inherit !important; font-weight: inherit !important; line-height: inherit !important; }
    /* Gmail margin fix */
    u + #body a { color: inherit; text-decoration: none; font-size: inherit; font-family: inherit; font-weight: inherit; line-height: inherit; }
    /* Yahoo/AOL fix */
    #outlook a { padding: 0; }
    .yshortcuts a { border-bottom: none !important; }

    /* === RESPONSIVE === */
    @media only screen and (max-width: 620px) {
      .email-container { width: 100% !important; max-width: 100% !important; }
      .fluid { max-width: 100% !important; height: auto !important; margin-left: auto !important; margin-right: auto !important; }
      .stack-column, .stack-column-center { display: block !important; width: 100% !important; max-width: 100% !important; direction: ltr !important; }
      .stack-column-center { text-align: center !important; }
      .center-on-narrow { text-align: center !important; display: block !important; margin-left: auto !important; margin-right: auto !important; float: none !important; }
      table.center-on-narrow { display: inline-block !important; }
      .mobile-padding { padding-left: 20px !important; padding-right: 20px !important; }
      .mobile-font-large { font-size: 22px !important; line-height: 28px !important; }
      .mobile-font-normal { font-size: 16px !important; line-height: 24px !important; }
      .mobile-hide { display: none !important; }
      .mobile-full-width { width: 100% !important; }
    }

    /* === DARK MODE === */
    @media (prefers-color-scheme: dark) {
      body, .email-bg { background-color: #1a1a2e !important; }
      .email-container { background-color: #16213e !important; }
      .dark-text { color: #e4e4e7 !important; }
      .dark-text-secondary { color: #a1a1aa !important; }
      .dark-bg { background-color: #16213e !important; }
      .dark-bg-secondary { background-color: #1a1a2e !important; }
      a.dark-link { color: #818cf8 !important; }
      .dark-img-invert { filter: brightness(0) invert(1) !important; }
      .dark-border { border-color: #2d3748 !important; }
    }
    /* Outlook dark mode */
    [data-ogsc] .dark-text { color: #e4e4e7 !important; }
    [data-ogsc] .dark-text-secondary { color: #a1a1aa !important; }
    [data-ogsc] a.dark-link { color: #818cf8 !important; }
    [data-ogsb] .email-bg { background-color: #1a1a2e !important; }
    [data-ogsb] .email-container { background-color: #16213e !important; }
    [data-ogsb] .dark-bg { background-color: #16213e !important; }
    [data-ogsb] .dark-bg-secondary { background-color: #1a1a2e !important; }
  </style>
</head>
<body id="body" style="margin:0; padding:0; word-spacing:normal; background-color:#F9FAFB;" class="email-bg">
  <!-- Preheader text (hidden) -->
  <div style="display:none;font-size:1px;color:#F9FAFB;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;">
    Preheader text goes here — this shows in inbox previews.
    &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847;
  </div>

  <!-- Email wrapper table -->
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin:auto;" class="email-bg">
    <tr>
      <td style="padding:20px 0; text-align:center;">

        <!-- Visually hidden preheader spacer -->
        <div style="display:none;font-size:1px;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;mso-hide:all;">
          &zwnj;&nbsp;
        </div>

        <!-- Email body container: 600px max -->
        <!--[if mso]>
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" align="center">
        <tr>
        <td>
        <![endif]-->
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width:600px; margin:auto;" class="email-container">

          <!-- CONTENT ROWS GO HERE -->

        </table>
        <!--[if mso]>
        </td>
        </tr>
        </table>
        <![endif]-->

      </td>
    </tr>
  </table>
</body>
</html>
```

---

## CSS Reset Reference (Inline-Ready)

Apply these resets inline on every email. The `<style>` block version is in the boilerplate above; when inlining, use these on the relevant elements:

| Element | Inline Style |
|---|---|
| `<body>` | `margin:0; padding:0; background-color:#F9FAFB; -webkit-text-size-adjust:100%; -ms-text-size-adjust:100%;` |
| `<table>` | `border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;` |
| `<td>` | `mso-table-lspace:0pt; mso-table-rspace:0pt;` |
| `<img>` | `border:0; height:auto; line-height:100%; outline:none; text-decoration:none; -ms-interpolation-mode:bicubic;` |
| `<a>` | `-webkit-text-size-adjust:100%; -ms-text-size-adjust:100%;` |

### Outlook DPI Scaling Fix

Always include in `<head>` inside MSO conditionals:

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

### Gmail Margin Fix

Use `u + #body a` selector to prevent Gmail from overriding link styles:

```css
u + #body a { color: inherit; text-decoration: none; font-size: inherit; font-family: inherit; font-weight: inherit; line-height: inherit; }
```

### Yahoo/AOL Fix

```css
#outlook a { padding: 0; }
.yshortcuts a { border-bottom: none !important; }
```

---

## Responsive Design

### Fluid Tables

All content tables use `width:100%; max-width:600px` with `margin:auto` for centering. Outlook ignores `max-width`, so wrap in MSO conditional ghost tables:

```html
<!--[if mso]>
<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" align="center">
<tr><td>
<![endif]-->
<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width:600px; margin:auto;">
  <!-- content -->
</table>
<!--[if mso]>
</td></tr>
</table>
<![endif]-->
```

### Media Queries for Mobile

Place inside `<style>` in `<head>`:

```css
@media only screen and (max-width: 620px) {
  .email-container { width: 100% !important; max-width: 100% !important; }
  .stack-column, .stack-column-center {
    display: block !important;
    width: 100% !important;
    max-width: 100% !important;
    direction: ltr !important;
  }
  .stack-column-center { text-align: center !important; }
  .mobile-padding { padding-left: 20px !important; padding-right: 20px !important; }
  .mobile-font-large { font-size: 22px !important; line-height: 28px !important; }
  .mobile-font-normal { font-size: 16px !important; line-height: 24px !important; }
  .mobile-hide { display: none !important; }
  .mobile-full-width { width: 100% !important; }
}
```

### Ghost Table Pattern for Outlook

Outlook desktop (2007-2023) uses the Word rendering engine and ignores `max-width`, `display:block` on table cells, and most modern CSS. Use MSO conditional ghost tables to enforce fixed widths:

```html
<!--[if mso]>
<table role="presentation" width="600" cellspacing="0" cellpadding="0" border="0" align="center">
<tr>
<td width="290">
<![endif]-->
<div style="display:inline-block; width:100%; max-width:290px; vertical-align:top;" class="stack-column">
  <!-- Column content -->
</div>
<!--[if mso]>
</td>
<td width="20"></td>
<td width="290">
<![endif]-->
<div style="display:inline-block; width:100%; max-width:290px; vertical-align:top;" class="stack-column">
  <!-- Column content -->
</div>
<!--[if mso]>
</td>
</tr>
</table>
<![endif]-->
```

### Hybrid/Spongy Method

For bulletproof multi-column layouts without media queries:

```html
<!--[if mso]>
<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
<tr>
<td valign="top" width="300">
<![endif]-->
<div style="display:inline-block; margin:0 -1px; width:100%; min-width:200px; max-width:300px; vertical-align:top;" class="stack-column">
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
    <tr>
      <td style="padding:10px;">
        <!-- Column 1 content -->
      </td>
    </tr>
  </table>
</div>
<!--[if mso]>
</td>
<td valign="top" width="300">
<![endif]-->
<div style="display:inline-block; margin:0 -1px; width:100%; min-width:200px; max-width:300px; vertical-align:top;" class="stack-column">
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
    <tr>
      <td style="padding:10px;">
        <!-- Column 2 content -->
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

---

## Dark Mode Support

### Media Query Approach

```css
@media (prefers-color-scheme: dark) {
  body, .email-bg { background-color: #1a1a2e !important; }
  .email-container { background-color: #16213e !important; }
  .dark-text { color: #e4e4e7 !important; }
  .dark-text-secondary { color: #a1a1aa !important; }
  a.dark-link { color: #818cf8 !important; }
}
```

### Outlook Dark Mode

Outlook apps use proprietary `[data-ogsc]` (text/foreground color) and `[data-ogsb]` (background color) attribute selectors:

```css
[data-ogsc] .dark-text { color: #e4e4e7 !important; }
[data-ogsb] .dark-bg { background-color: #16213e !important; }
```

### Color Inversion Strategy

- **Invert**: Background colors, text colors, border colors
- **Keep**: Brand accent colors (buttons, links), images, logos
- **Logos**: Use transparent PNGs; add a class for optional inversion or provide a light-on-dark variant
- **Images**: Add `class="dark-img-invert"` only on images that need inversion (e.g., dark logos on transparent backgrounds). Most photos should NOT be inverted.
