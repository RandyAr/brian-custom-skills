---
name: email-template
description: >
  Create responsive HTML email templates that work across all major email clients.
  Triggers on: HTML email, email template, newsletter, transactional email, email design,
  email layout, responsive email, Outlook email, Gmail email, dark mode email, email CSS,
  inline CSS, table layout email, email marketing, welcome email, password reset email,
  order confirmation email, invoice email, notification email, email client compatibility,
  MSO conditional, preheader text, email blast, ESP, Mailchimp, SendGrid, email HTML.
---

# Email Template Generator

You are an expert email developer specializing in cross-client compatible HTML email templates. You build production-ready, responsive, dark-mode-compatible email HTML using table-based layouts and inline CSS. You know the rendering quirks of every major email client and write bulletproof markup that degrades gracefully.

---

## Workflow

When a user requests an email template, follow this sequence:

### Step 1 — Clarify Requirements

Before generating, confirm:
1. **Template type**: Transactional (welcome, password reset, order confirmation, invoice), Marketing (newsletter, promotional), or Notification (alert, digest).
2. **Brand colors**: Primary, secondary, text color, background color. Defaults provided below.
3. **Logo URL**: Absolute URL to the company logo image.
4. **Content structure**: What sections are needed? (hero, CTA, feature grid, item table, footer, etc.)
5. **Company name**: For footer and alt text.
6. **Font preference**: Must be web-safe. Default: Arial, Helvetica, sans-serif.
7. **ESP target** (optional): Mailchimp, SendGrid, or generic — affects merge tag syntax.

If the user provides enough context, infer sensible defaults and proceed. Only ask when genuinely ambiguous.

### Step 2 — Generate HTML Email

Produce a complete HTML email file with:
- Table-based layout with all CSS inlined on elements
- Responsive media queries in a `<style>` block (for clients that support `<style>`)
- Dark mode support via `prefers-color-scheme` and Outlook data attributes
- MSO conditional comments for Outlook rendering
- Hidden preheader text
- Unsubscribe link placeholder in the footer
- Alt text on every image

### Step 3 — Generate Plain Text Version

Produce a plain-text fallback version of the email with:
- Clear section headings using ALL CAPS or dashes
- URLs written out in full
- Readable formatting without any HTML

### Step 4 — Compatibility Notes

After generating, list:
- Any CSS features used that lack universal support
- Client-specific rendering concerns
- Recommendations for testing (Litmus, Email on Acid, etc.)

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

---
## Template Types

### 1. Transactional — Welcome Email

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
  <title>Welcome to {{company_name}}</title>
  <style>
    body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
    img { -ms-interpolation-mode: bicubic; border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }
    body { height: 100% !important; margin: 0 !important; padding: 0 !important; width: 100% !important; }
    a[x-apple-data-detectors] { color: inherit !important; text-decoration: none !important; font-size: inherit !important; font-family: inherit !important; font-weight: inherit !important; line-height: inherit !important; }
    u + #body a { color: inherit; text-decoration: none; font-size: inherit; font-family: inherit; font-weight: inherit; line-height: inherit; }
    #outlook a { padding: 0; }
    @media only screen and (max-width: 620px) {
      .email-container { width: 100% !important; max-width: 100% !important; }
      .stack-column { display: block !important; width: 100% !important; max-width: 100% !important; }
      .mobile-padding { padding-left: 20px !important; padding-right: 20px !important; }
      .mobile-font-large { font-size: 22px !important; line-height: 28px !important; }
      .mobile-hide { display: none !important; }
    }
    @media (prefers-color-scheme: dark) {
      body, .email-bg { background-color: #1a1a2e !important; }
      .email-container, .dark-bg { background-color: #16213e !important; }
      .dark-text { color: #e4e4e7 !important; }
      .dark-text-secondary { color: #a1a1aa !important; }
      a.dark-link { color: #818cf8 !important; }
    }
    [data-ogsc] .dark-text { color: #e4e4e7 !important; }
    [data-ogsc] .dark-text-secondary { color: #a1a1aa !important; }
    [data-ogsb] .email-bg { background-color: #1a1a2e !important; }
    [data-ogsb] .dark-bg { background-color: #16213e !important; }
  </style>
</head>
<body id="body" style="margin:0; padding:0; word-spacing:normal; background-color:#F9FAFB;" class="email-bg">
  <div style="display:none;font-size:1px;color:#F9FAFB;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;">
    Welcome aboard! Here is everything you need to get started.
    &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847;
  </div>
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin:auto;" class="email-bg">
    <tr>
      <td style="padding:20px 0; text-align:center;">
        <!--[if mso]>
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" align="center"><tr><td>
        <![endif]-->
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width:600px; margin:auto; background-color:#ffffff; border-radius:8px;" class="email-container dark-bg">

          <!-- LOGO ROW -->
          <tr>
            <td style="padding:30px 40px 20px 40px; text-align:center;" class="mobile-padding">
              <img src="{{logo_url}}" alt="{{company_name}}" width="150" style="width:150px; max-width:150px; height:auto; display:block; margin:auto;">
            </td>
          </tr>

          <!-- HERO ROW -->
          <tr>
            <td style="padding:10px 40px 20px 40px; text-align:center;" class="mobile-padding">
              <h1 style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:28px; line-height:36px; font-weight:bold; color:#1F2937;" class="dark-text mobile-font-large">Welcome to {{company_name}}!</h1>
              <p style="margin:16px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:16px; line-height:24px; color:#4B5563;" class="dark-text-secondary">We are thrilled to have you on board. Your account is all set up and ready to go.</p>
            </td>
          </tr>

          <!-- CTA BUTTON ROW -->
          <tr>
            <td style="padding:10px 40px 30px 40px; text-align:center;" class="mobile-padding">
              <!--[if mso]>
              <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="https://example.com/get-started" style="height:48px;v-text-anchor:middle;width:220px;" arcsize="10%" stroke="f" fillcolor="#4F46E5">
                <w:anchorlock/>
                <center>
              <![endif]-->
              <a href="https://example.com/get-started" style="background-color:#4F46E5; border-radius:6px; color:#ffffff; display:inline-block; font-family:Arial, Helvetica, sans-serif; font-size:16px; font-weight:bold; line-height:48px; text-align:center; text-decoration:none; width:220px; -webkit-text-size-adjust:none;">Get Started</a>
              <!--[if mso]>
                </center>
              </v:roundrect>
              <![endif]-->
            </td>
          </tr>

          <!-- DIVIDER -->
          <tr>
            <td style="padding:0 40px;" class="mobile-padding">
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                <tr>
                  <td style="border-top:1px solid #E5E7EB; font-size:1px; line-height:1px;" class="dark-border">&nbsp;</td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- FEATURE HIGHLIGHTS: 3-COLUMN GRID -->
          <tr>
            <td style="padding:30px 40px 10px 40px; text-align:center;" class="mobile-padding">
              <h2 style="margin:0 0 20px 0; font-family:Arial, Helvetica, sans-serif; font-size:20px; line-height:26px; color:#1F2937;" class="dark-text">Here is what you can do</h2>
            </td>
          </tr>
          <tr>
            <td style="padding:0 20px 30px 20px;" class="mobile-padding">
              <!--[if mso]>
              <table role="presentation" width="560" cellspacing="0" cellpadding="0" border="0" align="center">
              <tr>
              <td width="173" valign="top">
              <![endif]-->
              <div style="display:inline-block; width:100%; max-width:173px; vertical-align:top;" class="stack-column">
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                  <tr>
                    <td style="padding:10px 10px; text-align:center;">
                      <img src="https://example.com/icon-feature1.png" alt="Feature 1" width="48" height="48" style="width:48px; height:48px; display:block; margin:0 auto 10px auto;">
                      <p style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px; font-weight:bold; color:#1F2937;" class="dark-text">Dashboard</p>
                      <p style="margin:6px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:13px; line-height:18px; color:#6B7280;" class="dark-text-secondary">Track your progress at a glance.</p>
                    </td>
                  </tr>
                </table>
              </div>
              <!--[if mso]>
              </td>
              <td width="173" valign="top">
              <![endif]-->
              <div style="display:inline-block; width:100%; max-width:173px; vertical-align:top;" class="stack-column">
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                  <tr>
                    <td style="padding:10px 10px; text-align:center;">
                      <img src="https://example.com/icon-feature2.png" alt="Feature 2" width="48" height="48" style="width:48px; height:48px; display:block; margin:0 auto 10px auto;">
                      <p style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px; font-weight:bold; color:#1F2937;" class="dark-text">Integrations</p>
                      <p style="margin:6px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:13px; line-height:18px; color:#6B7280;" class="dark-text-secondary">Connect your favorite tools.</p>
                    </td>
                  </tr>
                </table>
              </div>
              <!--[if mso]>
              </td>
              <td width="173" valign="top">
              <![endif]-->
              <div style="display:inline-block; width:100%; max-width:173px; vertical-align:top;" class="stack-column">
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                  <tr>
                    <td style="padding:10px 10px; text-align:center;">
                      <img src="https://example.com/icon-feature3.png" alt="Feature 3" width="48" height="48" style="width:48px; height:48px; display:block; margin:0 auto 10px auto;">
                      <p style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px; font-weight:bold; color:#1F2937;" class="dark-text">Support</p>
                      <p style="margin:6px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:13px; line-height:18px; color:#6B7280;" class="dark-text-secondary">We are here to help 24/7.</p>
                    </td>
                  </tr>
                </table>
              </div>
              <!--[if mso]>
              </td>
              </tr>
              </table>
              <![endif]-->
            </td>
          </tr>

          <!-- FOOTER -->
          <tr>
            <td style="padding:20px 40px 30px 40px; text-align:center; background-color:#F3F4F6; border-radius:0 0 8px 8px;" class="mobile-padding dark-bg-secondary">
              <p style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:12px; line-height:18px; color:#9CA3AF;" class="dark-text-secondary">&copy; 2026 {{company_name}}. All rights reserved.</p>
              <p style="margin:8px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:12px; line-height:18px; color:#9CA3AF;" class="dark-text-secondary">
                123 Main Street, City, State 12345
              </p>
              <p style="margin:8px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:12px; line-height:18px;">
                <a href="https://example.com/unsubscribe" style="color:#6B7280; text-decoration:underline;" class="dark-link">Unsubscribe</a>
                &nbsp;&bull;&nbsp;
                <a href="https://example.com/preferences" style="color:#6B7280; text-decoration:underline;" class="dark-link">Email Preferences</a>
              </p>
            </td>
          </tr>

        </table>
        <!--[if mso]>
        </td></tr></table>
        <![endif]-->
      </td>
    </tr>
  </table>
</body>
</html>
```

### 2. Transactional — Password Reset

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
  <title>Reset Your Password</title>
  <style>
    body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
    img { -ms-interpolation-mode: bicubic; border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }
    body { height: 100% !important; margin: 0 !important; padding: 0 !important; width: 100% !important; }
    a[x-apple-data-detectors] { color: inherit !important; text-decoration: none !important; font-size: inherit !important; font-family: inherit !important; font-weight: inherit !important; line-height: inherit !important; }
    u + #body a { color: inherit; text-decoration: none; font-size: inherit; font-family: inherit; font-weight: inherit; line-height: inherit; }
    #outlook a { padding: 0; }
    @media only screen and (max-width: 620px) {
      .email-container { width: 100% !important; max-width: 100% !important; }
      .mobile-padding { padding-left: 20px !important; padding-right: 20px !important; }
      .mobile-font-large { font-size: 22px !important; line-height: 28px !important; }
    }
    @media (prefers-color-scheme: dark) {
      body, .email-bg { background-color: #1a1a2e !important; }
      .email-container, .dark-bg { background-color: #16213e !important; }
      .dark-text { color: #e4e4e7 !important; }
      .dark-text-secondary { color: #a1a1aa !important; }
      a.dark-link { color: #818cf8 !important; }
    }
    [data-ogsc] .dark-text { color: #e4e4e7 !important; }
    [data-ogsb] .email-bg { background-color: #1a1a2e !important; }
    [data-ogsb] .dark-bg { background-color: #16213e !important; }
  </style>
</head>
<body id="body" style="margin:0; padding:0; word-spacing:normal; background-color:#F9FAFB;" class="email-bg">
  <div style="display:none;font-size:1px;color:#F9FAFB;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;">
    Reset your password — this link expires in 1 hour.
    &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847;
  </div>
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin:auto;" class="email-bg">
    <tr>
      <td style="padding:20px 0; text-align:center;">
        <!--[if mso]>
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" align="center"><tr><td>
        <![endif]-->
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width:600px; margin:auto; background-color:#ffffff; border-radius:8px;" class="email-container dark-bg">

          <!-- LOGO -->
          <tr>
            <td style="padding:30px 40px 20px 40px; text-align:center;" class="mobile-padding">
              <img src="{{logo_url}}" alt="{{company_name}}" width="120" style="width:120px; max-width:120px; height:auto; display:block; margin:auto;">
            </td>
          </tr>

          <!-- SECURITY ICON + HEADING -->
          <tr>
            <td style="padding:10px 40px 0 40px; text-align:center;" class="mobile-padding">
              <img src="https://example.com/icon-lock.png" alt="Security" width="48" height="48" style="width:48px; height:48px; display:block; margin:0 auto 16px auto;">
              <h1 style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:24px; line-height:32px; font-weight:bold; color:#1F2937;" class="dark-text mobile-font-large">Password Reset Request</h1>
            </td>
          </tr>

          <!-- MESSAGE -->
          <tr>
            <td style="padding:16px 40px 10px 40px; text-align:center;" class="mobile-padding">
              <p style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:16px; line-height:24px; color:#4B5563;" class="dark-text-secondary">We received a request to reset the password for your account. Click the button below to set a new password.</p>
              <p style="margin:16px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px; color:#EF4444; font-weight:bold;">This link expires in 1 hour.</p>
            </td>
          </tr>

          <!-- CTA BUTTON -->
          <tr>
            <td style="padding:20px 40px 20px 40px; text-align:center;" class="mobile-padding">
              <!--[if mso]>
              <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="https://example.com/reset-password?token=TOKEN" style="height:48px;v-text-anchor:middle;width:220px;" arcsize="10%" stroke="f" fillcolor="#4F46E5">
                <w:anchorlock/>
                <center>
              <![endif]-->
              <a href="https://example.com/reset-password?token=TOKEN" style="background-color:#4F46E5; border-radius:6px; color:#ffffff; display:inline-block; font-family:Arial, Helvetica, sans-serif; font-size:16px; font-weight:bold; line-height:48px; text-align:center; text-decoration:none; width:220px; -webkit-text-size-adjust:none;">Reset Password</a>
              <!--[if mso]>
                </center>
              </v:roundrect>
              <![endif]-->
            </td>
          </tr>

          <!-- ALTERNATIVE LINK -->
          <tr>
            <td style="padding:0 40px 20px 40px; text-align:center;" class="mobile-padding">
              <p style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:13px; line-height:18px; color:#9CA3AF;" class="dark-text-secondary">If the button does not work, copy and paste this URL into your browser:</p>
              <p style="margin:8px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:13px; line-height:18px; word-break:break-all;">
                <a href="https://example.com/reset-password?token=TOKEN" style="color:#4F46E5; text-decoration:underline;" class="dark-link">https://example.com/reset-password?token=TOKEN</a>
              </p>
            </td>
          </tr>

          <!-- DIVIDER -->
          <tr>
            <td style="padding:0 40px;" class="mobile-padding">
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                <tr><td style="border-top:1px solid #E5E7EB; font-size:1px; line-height:1px;" class="dark-border">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- DIDN'T REQUEST THIS -->
          <tr>
            <td style="padding:20px 40px 10px 40px; text-align:center;" class="mobile-padding">
              <p style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px; color:#6B7280;" class="dark-text-secondary"><strong>Did not request this?</strong></p>
              <p style="margin:8px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px; color:#6B7280;" class="dark-text-secondary">If you did not request a password reset, you can safely ignore this email. Your password will not be changed.</p>
            </td>
          </tr>

          <!-- FOOTER -->
          <tr>
            <td style="padding:20px 40px 30px 40px; text-align:center; background-color:#F3F4F6; border-radius:0 0 8px 8px;" class="mobile-padding dark-bg-secondary">
              <p style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:12px; line-height:18px; color:#9CA3AF;" class="dark-text-secondary">&copy; 2026 {{company_name}}. All rights reserved.</p>
              <p style="margin:8px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:12px; line-height:18px;">
                <a href="https://example.com/unsubscribe" style="color:#6B7280; text-decoration:underline;" class="dark-link">Unsubscribe</a>
              </p>
            </td>
          </tr>

        </table>
        <!--[if mso]>
        </td></tr></table>
        <![endif]-->
      </td>
    </tr>
  </table>
</body>
</html>
```

### 3. Transactional — Order Confirmation

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
  <title>Order Confirmation #{{order_number}}</title>
  <style>
    body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
    img { -ms-interpolation-mode: bicubic; border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }
    body { height: 100% !important; margin: 0 !important; padding: 0 !important; width: 100% !important; }
    a[x-apple-data-detectors] { color: inherit !important; text-decoration: none !important; }
    u + #body a { color: inherit; text-decoration: none; }
    #outlook a { padding: 0; }
    @media only screen and (max-width: 620px) {
      .email-container { width: 100% !important; max-width: 100% !important; }
      .mobile-padding { padding-left: 16px !important; padding-right: 16px !important; }
      .mobile-font-large { font-size: 22px !important; line-height: 28px !important; }
      .item-image { width: 60px !important; height: 60px !important; }
    }
    @media (prefers-color-scheme: dark) {
      body, .email-bg { background-color: #1a1a2e !important; }
      .email-container, .dark-bg { background-color: #16213e !important; }
      .dark-text { color: #e4e4e7 !important; }
      .dark-text-secondary { color: #a1a1aa !important; }
      a.dark-link { color: #818cf8 !important; }
      .dark-border { border-color: #2d3748 !important; }
      .dark-bg-secondary { background-color: #1a1a2e !important; }
    }
    [data-ogsc] .dark-text { color: #e4e4e7 !important; }
    [data-ogsb] .email-bg { background-color: #1a1a2e !important; }
    [data-ogsb] .dark-bg { background-color: #16213e !important; }
  </style>
</head>
<body id="body" style="margin:0; padding:0; word-spacing:normal; background-color:#F9FAFB;" class="email-bg">
  <div style="display:none;font-size:1px;color:#F9FAFB;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;">
    Your order #{{order_number}} has been confirmed!
    &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847;
  </div>
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin:auto;" class="email-bg">
    <tr>
      <td style="padding:20px 0; text-align:center;">
        <!--[if mso]>
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" align="center"><tr><td>
        <![endif]-->
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width:600px; margin:auto; background-color:#ffffff; border-radius:8px;" class="email-container dark-bg">

          <!-- LOGO -->
          <tr>
            <td style="padding:30px 40px 20px 40px; text-align:center;" class="mobile-padding">
              <img src="{{logo_url}}" alt="{{company_name}}" width="120" style="width:120px; max-width:120px; height:auto; display:block; margin:auto;">
            </td>
          </tr>

          <!-- ORDER CONFIRMED HEADER -->
          <tr>
            <td style="padding:0 40px 10px 40px; text-align:center;" class="mobile-padding">
              <img src="https://example.com/icon-checkmark.png" alt="Confirmed" width="48" height="48" style="width:48px; height:48px; display:block; margin:0 auto 12px auto;">
              <h1 style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:24px; line-height:32px; font-weight:bold; color:#059669;">Order Confirmed!</h1>
              <p style="margin:8px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px; color:#6B7280;" class="dark-text-secondary">Order #{{order_number}} &bull; {{order_date}}</p>
            </td>
          </tr>

          <!-- SPACER -->
          <tr><td style="padding:10px 0; font-size:1px; line-height:1px;">&nbsp;</td></tr>

          <!-- ITEM TABLE -->
          <tr>
            <td style="padding:0 40px;" class="mobile-padding">
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                <!-- Item Header -->
                <tr>
                  <td style="padding:8px 0; font-family:Arial, Helvetica, sans-serif; font-size:12px; font-weight:bold; color:#9CA3AF; text-transform:uppercase; border-bottom:2px solid #E5E7EB;" class="dark-text-secondary dark-border" colspan="2">Item</td>
                  <td style="padding:8px 0; font-family:Arial, Helvetica, sans-serif; font-size:12px; font-weight:bold; color:#9CA3AF; text-transform:uppercase; border-bottom:2px solid #E5E7EB; text-align:center;" class="dark-text-secondary dark-border">Qty</td>
                  <td style="padding:8px 0; font-family:Arial, Helvetica, sans-serif; font-size:12px; font-weight:bold; color:#9CA3AF; text-transform:uppercase; border-bottom:2px solid #E5E7EB; text-align:right;" class="dark-text-secondary dark-border">Price</td>
                </tr>
                <!-- Item Row 1 -->
                <tr>
                  <td style="padding:12px 8px 12px 0; border-bottom:1px solid #F3F4F6; vertical-align:top;" class="dark-border" width="80">
                    <img src="https://example.com/product1.jpg" alt="Product Name 1" width="80" height="80" style="width:80px; height:80px; object-fit:cover; border-radius:4px; display:block;" class="item-image">
                  </td>
                  <td style="padding:12px 8px; border-bottom:1px solid #F3F4F6; vertical-align:top; font-family:Arial, Helvetica, sans-serif;" class="dark-border">
                    <p style="margin:0; font-size:14px; line-height:20px; font-weight:bold; color:#1F2937;" class="dark-text">Product Name 1</p>
                    <p style="margin:4px 0 0 0; font-size:12px; line-height:16px; color:#9CA3AF;" class="dark-text-secondary">Size: M / Color: Blue</p>
                  </td>
                  <td style="padding:12px 8px; border-bottom:1px solid #F3F4F6; vertical-align:top; text-align:center; font-family:Arial, Helvetica, sans-serif; font-size:14px; color:#4B5563;" class="dark-text-secondary dark-border">1</td>
                  <td style="padding:12px 0 12px 8px; border-bottom:1px solid #F3F4F6; vertical-align:top; text-align:right; font-family:Arial, Helvetica, sans-serif; font-size:14px; font-weight:bold; color:#1F2937;" class="dark-text dark-border">$49.99</td>
                </tr>
                <!-- Item Row 2 -->
                <tr>
                  <td style="padding:12px 8px 12px 0; border-bottom:1px solid #F3F4F6; vertical-align:top;" class="dark-border" width="80">
                    <img src="https://example.com/product2.jpg" alt="Product Name 2" width="80" height="80" style="width:80px; height:80px; object-fit:cover; border-radius:4px; display:block;" class="item-image">
                  </td>
                  <td style="padding:12px 8px; border-bottom:1px solid #F3F4F6; vertical-align:top; font-family:Arial, Helvetica, sans-serif;" class="dark-border">
                    <p style="margin:0; font-size:14px; line-height:20px; font-weight:bold; color:#1F2937;" class="dark-text">Product Name 2</p>
                    <p style="margin:4px 0 0 0; font-size:12px; line-height:16px; color:#9CA3AF;" class="dark-text-secondary">Size: L / Color: Black</p>
                  </td>
                  <td style="padding:12px 8px; border-bottom:1px solid #F3F4F6; vertical-align:top; text-align:center; font-family:Arial, Helvetica, sans-serif; font-size:14px; color:#4B5563;" class="dark-text-secondary dark-border">2</td>
                  <td style="padding:12px 0 12px 8px; border-bottom:1px solid #F3F4F6; vertical-align:top; text-align:right; font-family:Arial, Helvetica, sans-serif; font-size:14px; font-weight:bold; color:#1F2937;" class="dark-text dark-border">$79.98</td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- TOTALS -->
          <tr>
            <td style="padding:16px 40px 0 40px;" class="mobile-padding">
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                <tr>
                  <td style="padding:6px 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; color:#6B7280;" class="dark-text-secondary">Subtotal</td>
                  <td style="padding:6px 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; color:#1F2937; text-align:right;" class="dark-text">$129.97</td>
                </tr>
                <tr>
                  <td style="padding:6px 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; color:#6B7280;" class="dark-text-secondary">Shipping</td>
                  <td style="padding:6px 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; color:#1F2937; text-align:right;" class="dark-text">$9.99</td>
                </tr>
                <tr>
                  <td style="padding:6px 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; color:#6B7280;" class="dark-text-secondary">Tax</td>
                  <td style="padding:6px 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; color:#1F2937; text-align:right;" class="dark-text">$11.20</td>
                </tr>
                <tr>
                  <td style="padding:10px 0 6px 0; font-family:Arial, Helvetica, sans-serif; font-size:16px; font-weight:bold; color:#1F2937; border-top:2px solid #E5E7EB;" class="dark-text dark-border">Total</td>
                  <td style="padding:10px 0 6px 0; font-family:Arial, Helvetica, sans-serif; font-size:16px; font-weight:bold; color:#1F2937; text-align:right; border-top:2px solid #E5E7EB;" class="dark-text dark-border">$151.16</td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- SHIPPING ADDRESS -->
          <tr>
            <td style="padding:20px 40px 10px 40px;" class="mobile-padding">
              <p style="margin:0 0 8px 0; font-family:Arial, Helvetica, sans-serif; font-size:14px; font-weight:bold; color:#1F2937;" class="dark-text">Shipping To:</p>
              <p style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:22px; color:#4B5563;" class="dark-text-secondary">
                John Doe<br>
                123 Main Street, Apt 4B<br>
                New York, NY 10001<br>
                United States
              </p>
            </td>
          </tr>

          <!-- TRACK ORDER CTA -->
          <tr>
            <td style="padding:20px 40px 30px 40px; text-align:center;" class="mobile-padding">
              <!--[if mso]>
              <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="https://example.com/track/{{order_number}}" style="height:48px;v-text-anchor:middle;width:220px;" arcsize="10%" stroke="f" fillcolor="#4F46E5">
                <w:anchorlock/>
                <center>
              <![endif]-->
              <a href="https://example.com/track/{{order_number}}" style="background-color:#4F46E5; border-radius:6px; color:#ffffff; display:inline-block; font-family:Arial, Helvetica, sans-serif; font-size:16px; font-weight:bold; line-height:48px; text-align:center; text-decoration:none; width:220px; -webkit-text-size-adjust:none;">Track Your Order</a>
              <!--[if mso]>
                </center>
              </v:roundrect>
              <![endif]-->
            </td>
          </tr>

          <!-- FOOTER -->
          <tr>
            <td style="padding:20px 40px 30px 40px; text-align:center; background-color:#F3F4F6; border-radius:0 0 8px 8px;" class="mobile-padding dark-bg-secondary">
              <p style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:12px; line-height:18px; color:#9CA3AF;" class="dark-text-secondary">&copy; 2026 {{company_name}}. All rights reserved.</p>
              <p style="margin:8px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:12px; line-height:18px;">
                <a href="https://example.com/help" style="color:#6B7280; text-decoration:underline;" class="dark-link">Help Center</a>
                &nbsp;&bull;&nbsp;
                <a href="https://example.com/unsubscribe" style="color:#6B7280; text-decoration:underline;" class="dark-link">Unsubscribe</a>
              </p>
            </td>
          </tr>

        </table>
        <!--[if mso]>
        </td></tr></table>
        <![endif]-->
      </td>
    </tr>
  </table>
</body>
</html>
```

### 4. Marketing — Newsletter

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
  <title>{{company_name}} Newsletter — {{issue_title}}</title>
  <style>
    body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
    img { -ms-interpolation-mode: bicubic; border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }
    body { height: 100% !important; margin: 0 !important; padding: 0 !important; width: 100% !important; }
    a[x-apple-data-detectors] { color: inherit !important; text-decoration: none !important; }
    u + #body a { color: inherit; text-decoration: none; }
    #outlook a { padding: 0; }
    @media only screen and (max-width: 620px) {
      .email-container { width: 100% !important; max-width: 100% !important; }
      .stack-column { display: block !important; width: 100% !important; max-width: 100% !important; }
      .mobile-padding { padding-left: 20px !important; padding-right: 20px !important; }
      .mobile-font-large { font-size: 22px !important; line-height: 28px !important; }
      .mobile-hide { display: none !important; }
      .mobile-full-width { width: 100% !important; }
    }
    @media (prefers-color-scheme: dark) {
      body, .email-bg { background-color: #1a1a2e !important; }
      .email-container, .dark-bg { background-color: #16213e !important; }
      .dark-text { color: #e4e4e7 !important; }
      .dark-text-secondary { color: #a1a1aa !important; }
      a.dark-link { color: #818cf8 !important; }
      .dark-border { border-color: #2d3748 !important; }
      .dark-bg-secondary { background-color: #1a1a2e !important; }
      .dark-bg-accent { background-color: #312e81 !important; }
    }
    [data-ogsc] .dark-text { color: #e4e4e7 !important; }
    [data-ogsc] .dark-text-secondary { color: #a1a1aa !important; }
    [data-ogsb] .email-bg { background-color: #1a1a2e !important; }
    [data-ogsb] .dark-bg { background-color: #16213e !important; }
    [data-ogsb] .dark-bg-accent { background-color: #312e81 !important; }
  </style>
</head>
<body id="body" style="margin:0; padding:0; word-spacing:normal; background-color:#F9FAFB;" class="email-bg">
  <div style="display:none;font-size:1px;color:#F9FAFB;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;">
    This week: {{preheader_summary}}
    &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847;
  </div>
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin:auto;" class="email-bg">
    <tr>
      <td style="padding:20px 0; text-align:center;">
        <!--[if mso]>
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" align="center"><tr><td>
        <![endif]-->
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width:600px; margin:auto; background-color:#ffffff; border-radius:8px;" class="email-container dark-bg">

          <!-- HEADER WITH NAV -->
          <tr>
            <td style="padding:20px 40px; text-align:center; background-color:#4F46E5; border-radius:8px 8px 0 0;" class="mobile-padding dark-bg-accent">
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                <tr>
                  <td style="text-align:left; vertical-align:middle;" width="150">
                    <img src="{{logo_url}}" alt="{{company_name}}" width="120" style="width:120px; max-width:120px; height:auto; display:block;">
                  </td>
                  <td style="text-align:right; vertical-align:middle; font-family:Arial, Helvetica, sans-serif; font-size:13px;" class="mobile-hide">
                    <a href="https://example.com/blog" style="color:#ffffff; text-decoration:none; padding:0 8px;">Blog</a>
                    <a href="https://example.com/products" style="color:#ffffff; text-decoration:none; padding:0 8px;">Products</a>
                    <a href="https://example.com/about" style="color:#ffffff; text-decoration:none; padding:0 8px;">About</a>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- HERO IMAGE + TEXT -->
          <tr>
            <td style="padding:0;">
              <img src="https://example.com/newsletter-hero.jpg" alt="Newsletter hero image" width="600" style="width:100%; max-width:600px; height:auto; display:block;">
            </td>
          </tr>
          <tr>
            <td style="padding:30px 40px 20px 40px;" class="mobile-padding">
              <h1 style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:26px; line-height:34px; font-weight:bold; color:#1F2937;" class="dark-text mobile-font-large">{{issue_title}}</h1>
              <p style="margin:12px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:16px; line-height:24px; color:#4B5563;" class="dark-text-secondary">{{hero_description}}</p>
            </td>
          </tr>

          <!-- CTA -->
          <tr>
            <td style="padding:0 40px 30px 40px;" class="mobile-padding">
              <!--[if mso]>
              <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="https://example.com/featured" style="height:44px;v-text-anchor:middle;width:180px;" arcsize="10%" stroke="f" fillcolor="#4F46E5">
                <w:anchorlock/><center>
              <![endif]-->
              <a href="https://example.com/featured" style="background-color:#4F46E5; border-radius:6px; color:#ffffff; display:inline-block; font-family:Arial, Helvetica, sans-serif; font-size:15px; font-weight:bold; line-height:44px; text-align:center; text-decoration:none; width:180px; -webkit-text-size-adjust:none;">Read More</a>
              <!--[if mso]>
              </center></v:roundrect>
              <![endif]-->
            </td>
          </tr>

          <!-- DIVIDER -->
          <tr>
            <td style="padding:0 40px;" class="mobile-padding">
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                <tr><td style="border-top:1px solid #E5E7EB; font-size:1px; line-height:1px;" class="dark-border">&nbsp;</td></tr>
              </table>
            </td>
          </tr>

          <!-- ARTICLE CARDS: 2 COLUMNS -->
          <tr>
            <td style="padding:30px 20px 10px 20px;" class="mobile-padding">
              <!--[if mso]>
              <table role="presentation" width="560" cellspacing="0" cellpadding="0" border="0" align="center">
              <tr>
              <td width="270" valign="top">
              <![endif]-->
              <div style="display:inline-block; width:100%; max-width:270px; vertical-align:top;" class="stack-column">
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                  <tr>
                    <td style="padding:10px;">
                      <img src="https://example.com/article1.jpg" alt="Article 1 image" width="250" style="width:100%; max-width:250px; height:auto; display:block; border-radius:6px;">
                      <h3 style="margin:12px 0 6px 0; font-family:Arial, Helvetica, sans-serif; font-size:16px; line-height:22px; color:#1F2937;" class="dark-text">Article Title One</h3>
                      <p style="margin:0 0 10px 0; font-family:Arial, Helvetica, sans-serif; font-size:13px; line-height:19px; color:#6B7280;" class="dark-text-secondary">Brief description of the first article with enough text to give readers context.</p>
                      <a href="https://example.com/article1" style="font-family:Arial, Helvetica, sans-serif; font-size:13px; color:#4F46E5; text-decoration:none; font-weight:bold;" class="dark-link">Read article &rarr;</a>
                    </td>
                  </tr>
                </table>
              </div>
              <!--[if mso]>
              </td>
              <td width="270" valign="top">
              <![endif]-->
              <div style="display:inline-block; width:100%; max-width:270px; vertical-align:top;" class="stack-column">
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                  <tr>
                    <td style="padding:10px;">
                      <img src="https://example.com/article2.jpg" alt="Article 2 image" width="250" style="width:100%; max-width:250px; height:auto; display:block; border-radius:6px;">
                      <h3 style="margin:12px 0 6px 0; font-family:Arial, Helvetica, sans-serif; font-size:16px; line-height:22px; color:#1F2937;" class="dark-text">Article Title Two</h3>
                      <p style="margin:0 0 10px 0; font-family:Arial, Helvetica, sans-serif; font-size:13px; line-height:19px; color:#6B7280;" class="dark-text-secondary">Brief description of the second article providing readers with a preview.</p>
                      <a href="https://example.com/article2" style="font-family:Arial, Helvetica, sans-serif; font-size:13px; color:#4F46E5; text-decoration:none; font-weight:bold;" class="dark-link">Read article &rarr;</a>
                    </td>
                  </tr>
                </table>
              </div>
              <!--[if mso]>
              </td>
              </tr>
              </table>
              <![endif]-->
            </td>
          </tr>

          <!-- SOCIAL MEDIA LINKS -->
          <tr>
            <td style="padding:20px 40px; text-align:center;" class="mobile-padding">
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center">
                <tr>
                  <td style="padding:0 6px;">
                    <a href="https://twitter.com/company"><img src="https://example.com/icon-twitter.png" alt="Twitter" width="32" height="32" style="width:32px; height:32px; display:block;"></a>
                  </td>
                  <td style="padding:0 6px;">
                    <a href="https://facebook.com/company"><img src="https://example.com/icon-facebook.png" alt="Facebook" width="32" height="32" style="width:32px; height:32px; display:block;"></a>
                  </td>
                  <td style="padding:0 6px;">
                    <a href="https://linkedin.com/company/company"><img src="https://example.com/icon-linkedin.png" alt="LinkedIn" width="32" height="32" style="width:32px; height:32px; display:block;"></a>
                  </td>
                  <td style="padding:0 6px;">
                    <a href="https://instagram.com/company"><img src="https://example.com/icon-instagram.png" alt="Instagram" width="32" height="32" style="width:32px; height:32px; display:block;"></a>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- FOOTER -->
          <tr>
            <td style="padding:20px 40px 30px 40px; text-align:center; background-color:#F3F4F6; border-radius:0 0 8px 8px;" class="mobile-padding dark-bg-secondary">
              <p style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:12px; line-height:18px; color:#9CA3AF;" class="dark-text-secondary">&copy; 2026 {{company_name}}. All rights reserved.</p>
              <p style="margin:8px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:12px; line-height:18px; color:#9CA3AF;" class="dark-text-secondary">123 Main Street, City, State 12345</p>
              <p style="margin:8px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:12px; line-height:18px;">
                <a href="https://example.com/unsubscribe" style="color:#6B7280; text-decoration:underline;" class="dark-link">Unsubscribe</a>
                &nbsp;&bull;&nbsp;
                <a href="https://example.com/preferences" style="color:#6B7280; text-decoration:underline;" class="dark-link">Preferences</a>
                &nbsp;&bull;&nbsp;
                <a href="https://example.com/browser-view" style="color:#6B7280; text-decoration:underline;" class="dark-link">View in browser</a>
              </p>
            </td>
          </tr>

        </table>
        <!--[if mso]>
        </td></tr></table>
        <![endif]-->
      </td>
    </tr>
  </table>
</body>
</html>
```

### 5. Notification — Alert/Digest

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
  <title>New Notification from {{company_name}}</title>
  <style>
    body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
    img { -ms-interpolation-mode: bicubic; border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }
    body { height: 100% !important; margin: 0 !important; padding: 0 !important; width: 100% !important; }
    a[x-apple-data-detectors] { color: inherit !important; text-decoration: none !important; }
    u + #body a { color: inherit; text-decoration: none; }
    #outlook a { padding: 0; }
    @media only screen and (max-width: 620px) {
      .email-container { width: 100% !important; max-width: 100% !important; }
      .mobile-padding { padding-left: 20px !important; padding-right: 20px !important; }
    }
    @media (prefers-color-scheme: dark) {
      body, .email-bg { background-color: #1a1a2e !important; }
      .email-container, .dark-bg { background-color: #16213e !important; }
      .dark-text { color: #e4e4e7 !important; }
      .dark-text-secondary { color: #a1a1aa !important; }
      a.dark-link { color: #818cf8 !important; }
      .dark-border { border-color: #2d3748 !important; }
      .dark-bg-secondary { background-color: #1a1a2e !important; }
      .dark-bg-badge { background-color: #312e81 !important; }
    }
    [data-ogsc] .dark-text { color: #e4e4e7 !important; }
    [data-ogsb] .email-bg { background-color: #1a1a2e !important; }
    [data-ogsb] .dark-bg { background-color: #16213e !important; }
  </style>
</head>
<body id="body" style="margin:0; padding:0; word-spacing:normal; background-color:#F9FAFB;" class="email-bg">
  <div style="display:none;font-size:1px;color:#F9FAFB;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;">
    You have a new notification: {{notification_preview}}
    &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847;
  </div>
  <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="margin:auto;" class="email-bg">
    <tr>
      <td style="padding:20px 0; text-align:center;">
        <!--[if mso]>
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="600" align="center"><tr><td>
        <![endif]-->
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width:600px; margin:auto; background-color:#ffffff; border-radius:8px;" class="email-container dark-bg">

          <!-- LOGO -->
          <tr>
            <td style="padding:30px 40px 20px 40px; text-align:center;" class="mobile-padding">
              <img src="{{logo_url}}" alt="{{company_name}}" width="100" style="width:100px; max-width:100px; height:auto; display:block; margin:auto;">
            </td>
          </tr>

          <!-- NOTIFICATION BADGE + ICON -->
          <tr>
            <td style="padding:0 40px 10px 40px; text-align:center;" class="mobile-padding">
              <table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center">
                <tr>
                  <td style="background-color:#EEF2FF; border-radius:50%; width:64px; height:64px; text-align:center; vertical-align:middle;" class="dark-bg-badge">
                    <img src="https://example.com/icon-bell.png" alt="Notification" width="32" height="32" style="width:32px; height:32px; display:inline-block; vertical-align:middle;">
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- NOTIFICATION CONTENT -->
          <tr>
            <td style="padding:10px 40px 10px 40px; text-align:center;" class="mobile-padding">
              <h2 style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:20px; line-height:28px; font-weight:bold; color:#1F2937;" class="dark-text">{{notification_title}}</h2>
              <p style="margin:12px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:15px; line-height:23px; color:#4B5563;" class="dark-text-secondary">{{notification_message}}</p>
              <p style="margin:8px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:12px; line-height:16px; color:#9CA3AF;" class="dark-text-secondary">{{notification_timestamp}}</p>
            </td>
          </tr>

          <!-- ACTION BUTTON -->
          <tr>
            <td style="padding:20px 40px 20px 40px; text-align:center;" class="mobile-padding">
              <!--[if mso]>
              <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="https://example.com/action" style="height:44px;v-text-anchor:middle;width:200px;" arcsize="10%" stroke="f" fillcolor="#4F46E5">
                <w:anchorlock/><center>
              <![endif]-->
              <a href="https://example.com/action" style="background-color:#4F46E5; border-radius:6px; color:#ffffff; display:inline-block; font-family:Arial, Helvetica, sans-serif; font-size:15px; font-weight:bold; line-height:44px; text-align:center; text-decoration:none; width:200px; -webkit-text-size-adjust:none;">View Details</a>
              <!--[if mso]>
              </center></v:roundrect>
              <![endif]-->
            </td>
          </tr>

          <!-- MUTE / SETTINGS -->
          <tr>
            <td style="padding:0 40px 20px 40px; text-align:center;" class="mobile-padding">
              <p style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:13px; line-height:18px; color:#9CA3AF;" class="dark-text-secondary">
                <a href="https://example.com/notifications/mute" style="color:#6B7280; text-decoration:underline;" class="dark-link">Mute this type</a>
                &nbsp;&bull;&nbsp;
                <a href="https://example.com/notifications/settings" style="color:#6B7280; text-decoration:underline;" class="dark-link">Notification settings</a>
              </p>
            </td>
          </tr>

          <!-- FOOTER -->
          <tr>
            <td style="padding:20px 40px 30px 40px; text-align:center; background-color:#F3F4F6; border-radius:0 0 8px 8px;" class="mobile-padding dark-bg-secondary">
              <p style="margin:0; font-family:Arial, Helvetica, sans-serif; font-size:12px; line-height:18px; color:#9CA3AF;" class="dark-text-secondary">&copy; 2026 {{company_name}}. All rights reserved.</p>
              <p style="margin:8px 0 0 0; font-family:Arial, Helvetica, sans-serif; font-size:12px; line-height:18px;">
                <a href="https://example.com/unsubscribe" style="color:#6B7280; text-decoration:underline;" class="dark-link">Unsubscribe</a>
              </p>
            </td>
          </tr>

        </table>
        <!--[if mso]>
        </td></tr></table>
        <![endif]-->
      </td>
    </tr>
  </table>
</body>
</html>
```

---

## Component Library

Reusable components to mix and match in any template.

### Bulletproof Button

Works in all clients including Outlook (uses VML fallback):

```html
<!--[if mso]>
<v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="URL" style="height:44px;v-text-anchor:middle;width:200px;" arcsize="10%" stroke="f" fillcolor="#4F46E5">
  <w:anchorlock/>
  <center>
<![endif]-->
<a href="URL" style="background-color:#4F46E5;border-radius:4px;color:#ffffff;display:inline-block;font-family:Arial, Helvetica, sans-serif;font-size:16px;font-weight:bold;line-height:44px;text-align:center;text-decoration:none;width:200px;-webkit-text-size-adjust:none;">Button Text</a>
<!--[if mso]>
  </center>
</v:roundrect>
<![endif]-->
```

**Customization notes:**
- Change `fillcolor` and `background-color` together to change the button color
- Change `arcsize` to control border-radius in Outlook (percentage of height)
- Change `height`/`line-height` together for button height
- Change `width` in both the VML and the `<a>` tag

### Responsive Image

```html
<img src="https://example.com/image.jpg" alt="Descriptive alt text" width="600" style="width:100%; max-width:600px; height:auto; display:block; border:0;" class="fluid">
```

**Retina support:** Use images that are 2x the display width and constrain with `width` attribute:

```html
<img src="https://example.com/image@2x.jpg" alt="Retina image" width="300" height="200" style="width:300px; max-width:100%; height:auto; display:block; border:0;" class="fluid">
```

**Alt text requirements:**
- Every `<img>` MUST have an `alt` attribute
- Decorative images: use `alt=""` (empty, not omitted)
- Content images: use descriptive, concise alt text
- Logo images: use company name as alt text

### Table-Based Spacer

Never use `<br>` or empty `<div>` for spacing. Use table rows:

```html
<!-- 20px spacer -->
<tr>
  <td style="padding:0; font-size:1px; line-height:1px; height:20px;">&nbsp;</td>
</tr>
```

Or a standalone spacer table:

```html
<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
  <tr>
    <td style="padding:0; font-size:1px; line-height:1px; height:20px;">&nbsp;</td>
  </tr>
</table>
```

### Divider / Horizontal Rule

```html
<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
  <tr>
    <td style="padding:20px 0;">
      <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
        <tr>
          <td style="border-top:1px solid #E5E7EB; font-size:1px; line-height:1px;" class="dark-border">&nbsp;</td>
        </tr>
      </table>
    </td>
  </tr>
</table>
```

### Two-Column Layout (Hybrid/Spongy)

```html
<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
  <tr>
    <td style="padding:0 20px; text-align:center; font-size:0;">
      <!--[if mso]>
      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
      <tr>
      <td width="50%" valign="top">
      <![endif]-->
      <div style="display:inline-block; width:100%; max-width:280px; vertical-align:top;" class="stack-column">
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
          <tr>
            <td style="padding:10px; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px; color:#1F2937;" class="dark-text">
              Left column content
            </td>
          </tr>
        </table>
      </div>
      <!--[if mso]>
      </td>
      <td width="50%" valign="top">
      <![endif]-->
      <div style="display:inline-block; width:100%; max-width:280px; vertical-align:top;" class="stack-column">
        <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
          <tr>
            <td style="padding:10px; font-family:Arial, Helvetica, sans-serif; font-size:14px; line-height:20px; color:#1F2937;" class="dark-text">
              Right column content
            </td>
          </tr>
        </table>
      </div>
      <!--[if mso]>
      </td>
      </tr>
      </table>
      <![endif]-->
    </td>
  </tr>
</table>
```

### Preheader Text (Hidden)

```html
<div style="display:none;font-size:1px;color:#F9FAFB;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;">
  Your preheader text here — shows in inbox preview.
  <!-- Fill remaining preview space with invisible characters -->
  &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847;
  &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847;
</div>
```

The `&#847;` characters are zero-width non-joiners that prevent email clients from pulling in body text after the preheader.

---

## Output Checklist

Before delivering any email template, verify:

- [ ] All CSS is inlined on elements (no external stylesheets)
- [ ] Table-based layout used throughout (no `<div>` for layout structure)
- [ ] MSO conditionals present for Outlook compatibility
- [ ] Responsive media queries included in `<style>` block
- [ ] Dark mode styles included (`prefers-color-scheme` + `[data-ogsc]`/`[data-ogsb]`)
- [ ] Preheader text present with spacer characters
- [ ] Unsubscribe link placeholder in footer
- [ ] Alt text on all `<img>` elements
- [ ] Plain text version provided alongside HTML
- [ ] Layout tested at widths: 320px, 480px, 600px
- [ ] No JavaScript anywhere in the email
- [ ] No `<form>` elements (poor email client support)
- [ ] All links use absolute URLs (placeholders acceptable)
- [ ] `role="presentation"` on all layout tables
- [ ] Font stacks are web-safe (Arial, Helvetica, sans-serif default)
- [ ] Images have explicit `width` and `height` attributes for Outlook
- [ ] `border="0"` on all tables and images
- [ ] Line-heights use `px` values (not unitless or `em`)
- [ ] Colors use full 6-digit hex codes (not shorthand 3-digit)

---

## Testing Recommendations

1. **Litmus** or **Email on Acid** — Render previews across 90+ email clients
2. **Mail-Tester** (mail-tester.com) — Spam score checking
3. **HTML Email Check** (htmlemailcheck.com) — Validate HTML structure
4. **Campaign Monitor CSS Guide** — Reference for CSS support
5. **Can I Email** (caniemail.com) — Check specific CSS/HTML feature support

Always send test emails to real accounts in Gmail, Outlook (desktop + web), and Apple Mail before final deployment.
