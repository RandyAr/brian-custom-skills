# Component Library

Reusable components to mix and match in any template.

---

## Bulletproof Button

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

---

## Responsive Image

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

---

## Table-Based Spacer

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

---

## Divider / Horizontal Rule

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

---

## Two-Column Layout (Hybrid/Spongy)

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

---

## Preheader Text (Hidden)

```html
<div style="display:none;font-size:1px;color:#F9FAFB;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;">
  Your preheader text here — shows in inbox preview.
  <!-- Fill remaining preview space with invisible characters -->
  &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847;
  &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847; &#847;
</div>
```

The `&#847;` characters are zero-width non-joiners that prevent email clients from pulling in body text after the preheader.
