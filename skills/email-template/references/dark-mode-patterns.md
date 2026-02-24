# Dark Mode Email Patterns Reference

Dark mode in email is one of the most challenging aspects of modern email development. Different email clients handle dark mode in completely different ways, and some override your carefully designed colors without giving you any control. This reference covers every known pattern and workaround.

---

## Table of Contents

1. [Which Clients Support Dark Mode](#which-clients-support-dark-mode)
2. [Three Dark Mode Behaviors](#three-dark-mode-behaviors)
3. [The prefers-color-scheme Media Query](#the-prefers-color-scheme-media-query)
4. [Outlook Dark Mode Selectors](#outlook-dark-mode-selectors)
5. [The .dark-mode Class Approach](#the-dark-mode-class-approach)
6. [Logo Strategies](#logo-strategies)
7. [Color Swapping Technique](#color-swapping-technique)
8. [Image Handling in Dark Mode](#image-handling-in-dark-mode)
9. [Testing Dark Mode Rendering](#testing-dark-mode-rendering)

---

## Which Clients Support Dark Mode

| Email Client | Dark Mode Support | Behavior Type | Override Method |
|---|---|---|---|
| Apple Mail (macOS) | Yes | Respects `prefers-color-scheme` | Full control via media query |
| Apple Mail (iOS) | Yes | Respects `prefers-color-scheme` | Full control via media query |
| Outlook.com (Web) | Yes | Partial color inversion | `[data-ogsc]`, `[data-ogsb]` |
| Outlook (iOS) | Yes | Partial color inversion | `[data-ogsc]`, `[data-ogsb]` |
| Outlook (Android) | Yes | Partial color inversion | `[data-ogsc]`, `[data-ogsb]` |
| Outlook 2019-2023 (Windows) | Yes | Full color inversion (forced) | Limited: `[data-ogsc]`, `[data-ogsb]` |
| Outlook 365 (Windows) | Yes | Full color inversion (forced) | Limited: `[data-ogsc]`, `[data-ogsb]` |
| Gmail (iOS) | Yes | Partial inversion | No override available |
| Gmail (Android) | Yes | Partial inversion | No override available |
| Gmail (Web) | Yes | Full inversion (forced) | No override available |
| Yahoo Mail | Partial | Varies by platform | No reliable override |
| Thunderbird | Yes | Respects `prefers-color-scheme` | Full control via media query |

---

## Three Dark Mode Behaviors

Email clients handle dark mode in one of three ways:

### 1. No Change

The client does not alter the email at all in dark mode. The email appears exactly as designed.

**Clients:** Some older Yahoo Mail versions, some web clients.

**Strategy:** No action needed, but ensure your design is readable if the surrounding UI goes dark (avoid very light outer backgrounds that might not contrast with a dark app chrome).

### 2. Partial Color Inversion

The client selectively changes some colors. Typically:
- Light backgrounds become dark
- Dark text becomes light
- Images and brand colors may or may not be altered
- The client tries to maintain readability

**Clients:** Gmail (Android, iOS), Outlook.com, Outlook mobile apps.

**Key characteristics:**
- The client analyzes your color values and inverts those it deems "light" or "dark"
- You cannot fully control this behavior
- Light background colors (close to white) are typically darkened
- Dark text colors (close to black) are typically lightened
- Medium-tone colors may or may not be changed
- Brand accent colors are often left alone

**Strategy:**
- Avoid pure white (`#FFFFFF`) backgrounds — use a very light gray like `#F9FAFB` so the client is less aggressive about inversion
- Avoid pure black (`#000000`) text — use `#1F2937` or similar dark gray
- Test with actual dark mode to see what gets inverted

### 3. Full Color Inversion

The client forcefully inverts all colors regardless of your CSS. Both backgrounds and text are inverted.

**Clients:** Outlook desktop (2019-2023, 365) in dark mode, Gmail (web) in dark theme.

**Key characteristics:**
- Almost all colors are inverted
- Images may get a white or colored background added
- Your carefully chosen dark-mode colors may be overridden
- You have limited control via `[data-ogsc]`/`[data-ogsb]` in Outlook

**Strategy:**
- Use `[data-ogsc]` and `[data-ogsb]` selectors for Outlook
- Accept that Gmail web dark mode cannot be controlled
- Use `color-scheme: light dark` meta tag to signal dark mode awareness
- Test extensively to ensure readability after inversion

---

## The prefers-color-scheme Media Query

This is the standard approach and works in clients that respect CSS media queries.

### Basic Implementation

```css
/* Light mode (default) styles are in your inline CSS */

/* Dark mode overrides in <style> block */
@media (prefers-color-scheme: dark) {
  /* Outer wrapper / body background */
  body,
  .email-bg {
    background-color: #1a1a2e !important;
  }

  /* Main email container */
  .email-container,
  .dark-bg {
    background-color: #16213e !important;
  }

  /* Secondary backgrounds (footer, callout boxes) */
  .dark-bg-secondary {
    background-color: #1a1a2e !important;
  }

  /* Primary text */
  .dark-text {
    color: #e4e4e7 !important;
  }

  /* Secondary/muted text */
  .dark-text-secondary {
    color: #a1a1aa !important;
  }

  /* Links */
  a.dark-link {
    color: #818cf8 !important;
  }

  /* Borders/dividers */
  .dark-border {
    border-color: #2d3748 !important;
  }

  /* Images that need inversion (e.g., dark logos on transparent bg) */
  .dark-img-invert {
    filter: brightness(0) invert(1) !important;
  }
}
```

### HTML Usage

Apply the dark mode classes alongside your inline styles:

```html
<!-- Text element -->
<p style="color:#1F2937; font-family:Arial, sans-serif; font-size:16px;" class="dark-text">
  This text is dark on light, and light on dark.
</p>

<!-- Background element -->
<td style="background-color:#FFFFFF; padding:20px;" class="dark-bg">
  Content
</td>

<!-- Link -->
<a href="https://example.com" style="color:#4F46E5;" class="dark-link">Click here</a>

<!-- Border/divider -->
<td style="border-top:1px solid #E5E7EB;" class="dark-border">&nbsp;</td>
```

### Required Meta Tags

Always include these in `<head>` to signal dark mode support:

```html
<meta name="color-scheme" content="light dark">
<meta name="supported-color-schemes" content="light dark">
```

Without these, some clients may not activate their dark mode rendering for your email.

### Supported Clients

The `prefers-color-scheme` media query works in:
- Apple Mail (macOS and iOS) — full support
- Thunderbird — full support
- Gmail (iOS via WebKit) — partial support
- Outlook.com — partial support

It does NOT work in:
- Gmail (Web) — strips `<style>` blocks in many contexts
- Gmail (Android) — strips `<style>` blocks
- Outlook desktop (Windows) — uses its own dark mode engine
- Yahoo Mail — no media query support

---

## Outlook Dark Mode Selectors

Outlook's apps and web client use proprietary data attributes for dark mode. These are your best tools for controlling Outlook dark mode rendering.

### [data-ogsc] — Foreground/Text Color Override

`[data-ogsc]` targets text and foreground colors in Outlook dark mode:

```css
[data-ogsc] .dark-text {
  color: #e4e4e7 !important;
}

[data-ogsc] .dark-text-secondary {
  color: #a1a1aa !important;
}

[data-ogsc] a.dark-link {
  color: #818cf8 !important;
}

[data-ogsc] .dark-text-on-dark {
  color: #ffffff !important;
}
```

### [data-ogsb] — Background Color Override

`[data-ogsb]` targets background colors in Outlook dark mode:

```css
[data-ogsb] .email-bg {
  background-color: #1a1a2e !important;
}

[data-ogsb] .dark-bg {
  background-color: #16213e !important;
}

[data-ogsb] .dark-bg-secondary {
  background-color: #1a1a2e !important;
}

[data-ogsb] .dark-bg-accent {
  background-color: #312e81 !important;
}
```

### Combined Usage

Place these in your `<style>` block alongside the `prefers-color-scheme` query:

```css
/* Standard dark mode */
@media (prefers-color-scheme: dark) {
  .dark-text { color: #e4e4e7 !important; }
  .dark-bg { background-color: #16213e !important; }
}

/* Outlook dark mode (outside media query — these are always present) */
[data-ogsc] .dark-text { color: #e4e4e7 !important; }
[data-ogsb] .dark-bg { background-color: #16213e !important; }
```

### Important Notes

- `[data-ogsc]` and `[data-ogsb]` selectors go **outside** the `@media` query — they are standalone rules
- They require `!important` to override Outlook's forced inversions
- They work in Outlook.com, Outlook iOS, Outlook Android, and partially in Outlook desktop
- Outlook desktop (Windows) dark mode is the most aggressive and may still override some of your choices
- These selectors do NOT work in non-Outlook clients (they are simply ignored)

---

## The .dark-mode Class Approach

Some ESPs and email systems inject a `.dark-mode` class on the body or a wrapper element when dark mode is active. This is not a standard approach but can be used as an additional layer.

### Implementation

```css
/* Body-level dark mode class (if injected by ESP) */
.dark-mode .dm-text { color: #e4e4e7 !important; }
.dark-mode .dm-bg { background-color: #16213e !important; }
```

### When to Use

- When your ESP specifically supports this pattern
- As a fallback alongside `prefers-color-scheme`
- When building for a controlled environment where you inject the class via JavaScript (web previews only — JavaScript is stripped in actual emails)

### Limitations

- Not supported by email clients natively
- Requires ESP or infrastructure support
- Cannot be relied upon as the primary dark mode method

---

## Logo Strategies

Logos are one of the trickiest elements in dark mode emails because a dark logo on a transparent background becomes invisible on a dark background.

### Strategy 1: Transparent PNG with CSS Filter (Simplest)

Use a dark logo as default and invert it in dark mode:

```html
<img src="https://example.com/logo-dark.png" alt="Company" width="150" style="width:150px; height:auto; display:block;" class="dark-img-invert">
```

```css
@media (prefers-color-scheme: dark) {
  .dark-img-invert {
    filter: brightness(0) invert(1) !important;
  }
}
```

**Pros:** Simple, single image asset
**Cons:** Only works in clients that support CSS `filter` in dark mode media queries (Apple Mail, some others). Does not work in Outlook or Gmail.

### Strategy 2: Two Logos with Show/Hide (Most Reliable)

Include both light and dark versions, showing/hiding as needed:

```html
<!-- Light mode logo (default visible) -->
<img src="https://example.com/logo-dark-on-light.png" alt="Company" width="150" style="width:150px; height:auto; display:block;" class="dark-mode-hide">

<!-- Dark mode logo (default hidden) -->
<div style="display:none; mso-hide:all;" class="dark-mode-show">
  <img src="https://example.com/logo-light-on-dark.png" alt="Company" width="150" style="width:150px; height:auto; display:block;">
</div>
```

```css
@media (prefers-color-scheme: dark) {
  .dark-mode-hide {
    display: none !important;
    mso-hide: all !important;
  }
  .dark-mode-show {
    display: block !important;
  }
}
```

**Pros:** Full control over each mode's appearance
**Cons:** Two image assets, extra HTML, only works where `<style>` blocks are supported

### Strategy 3: Logo on Colored Background (Safest)

Place the logo on a solid background that ensures contrast in both modes:

```html
<td style="background-color:#4F46E5; padding:20px; text-align:center; border-radius:8px;">
  <img src="https://example.com/logo-white.png" alt="Company" width="150" style="width:150px; height:auto; display:block; margin:0 auto;">
</td>
```

**Pros:** Works everywhere, no dark mode CSS needed, consistent branding
**Cons:** Less elegant, takes up more visual space

### Strategy 4: Logo with Built-In Padding

Export the logo as a PNG with a light or branded background baked into the image file (not transparent):

```html
<img src="https://example.com/logo-with-bg.png" alt="Company" width="150" style="width:150px; height:auto; display:block; border-radius:4px;">
```

**Pros:** Works everywhere without any CSS dark mode handling
**Cons:** Looks like a "sticker" on dark backgrounds, not seamless

### Recommendation

Use **Strategy 2** (two logos with show/hide) for maximum control in supporting clients, combined with **Strategy 3** (colored background) as the fallback experience in clients that strip `<style>` blocks.

---

## Color Swapping Technique

This technique uses CSS classes to swap colors between light and dark mode without changing the inline styles.

### Setup

Define your color pairs in the `<style>` block:

```css
/* Light mode defaults are in inline styles */

/* Dark mode swaps */
@media (prefers-color-scheme: dark) {
  /* Background swaps */
  .swap-bg-white    { background-color: #16213e !important; }  /* white -> dark blue */
  .swap-bg-light    { background-color: #1a1a2e !important; }  /* light gray -> darker blue */
  .swap-bg-primary  { background-color: #6366f1 !important; }  /* primary -> lighter primary */

  /* Text swaps */
  .swap-text-dark   { color: #e4e4e7 !important; }  /* dark -> light */
  .swap-text-medium { color: #a1a1aa !important; }  /* medium -> light medium */
  .swap-text-light  { color: #71717a !important; }  /* light -> medium (on dark bg) */

  /* Border swaps */
  .swap-border      { border-color: #2d3748 !important; }
}

/* Outlook swaps */
[data-ogsb] .swap-bg-white    { background-color: #16213e !important; }
[data-ogsb] .swap-bg-light    { background-color: #1a1a2e !important; }
[data-ogsc] .swap-text-dark   { color: #e4e4e7 !important; }
[data-ogsc] .swap-text-medium { color: #a1a1aa !important; }
```

### Usage in HTML

```html
<td style="background-color:#FFFFFF; padding:20px;" class="swap-bg-white">
  <h1 style="color:#1F2937; font-size:24px;" class="swap-text-dark">Heading</h1>
  <p style="color:#4B5563; font-size:16px;" class="swap-text-medium">Body text</p>
  <table role="presentation" width="100%">
    <tr>
      <td style="border-top:1px solid #E5E7EB;" class="swap-border">&nbsp;</td>
    </tr>
  </table>
</td>
```

### Color Pairing Guidelines

| Light Mode | Dark Mode | Use For |
|---|---|---|
| `#FFFFFF` (white) | `#16213e` (dark navy) | Main content background |
| `#F9FAFB` (light gray) | `#1a1a2e` (darker navy) | Outer/secondary background |
| `#F3F4F6` (medium gray bg) | `#1e293b` (slate) | Footer, callout boxes |
| `#1F2937` (near-black) | `#e4e4e7` (light gray) | Primary text |
| `#4B5563` (dark gray) | `#a1a1aa` (medium gray) | Secondary text |
| `#9CA3AF` (medium gray) | `#71717a` (dim gray) | Tertiary/muted text |
| `#E5E7EB` (border gray) | `#2d3748` (dark border) | Borders, dividers |
| `#4F46E5` (indigo) | `#818cf8` (light indigo) | Links (lighten for dark bg) |
| `#4F46E5` (indigo) | `#4F46E5` (indigo) | Buttons (keep same if sufficient contrast) |

---

## Image Handling in Dark Mode

### Preventing Unwanted Inversion

Some email clients (especially Outlook desktop dark mode and Gmail) will try to invert or alter images. Here are strategies to control this:

#### 1. Add a Thin Border to Prevent Background Blending

```html
<img src="image.jpg" alt="Photo" width="300" style="width:300px; height:auto; display:block; border:1px solid #E5E7EB;" class="dark-border">
```

The border ensures the image has a visible boundary against the dark background.

#### 2. Use Background Color Behind Transparent Images

If you have a PNG with transparency, add a background color to the containing cell:

```html
<td style="background-color:#FFFFFF; padding:10px; text-align:center;" class="swap-bg-white">
  <img src="https://example.com/chart.png" alt="Chart" width="400" style="width:400px; height:auto; display:block;">
</td>
```

#### 3. Avoid Transparent PNGs When Possible

For photos and illustrations that should not be inverted, use JPEG or PNG with an opaque (white or colored) background baked in.

#### 4. Use data-ogsc / data-ogsb for Outlook Image Containers

Ensure the container around images maintains an appropriate background in Outlook dark mode:

```css
[data-ogsb] .img-container {
  background-color: #ffffff !important;
}
```

### Icons in Dark Mode

Small icons (checkmarks, arrows, social icons) are especially problematic:

**Option A: Use colored icons** that have sufficient contrast on both light and dark backgrounds:
```html
<img src="https://example.com/icon-blue.png" alt="Check" width="24" height="24" style="width:24px; height:24px;">
```

**Option B: Use CSS filter for inversion** (limited client support):
```html
<img src="https://example.com/icon-dark.png" alt="Check" width="24" height="24" class="dark-img-invert">
```

**Option C: Use icons on colored backgrounds:**
```html
<td style="background-color:#EEF2FF; border-radius:50%; width:40px; height:40px; text-align:center; vertical-align:middle;" class="swap-bg-accent">
  <img src="https://example.com/icon.png" alt="" width="20" height="20" style="width:20px; height:20px;">
</td>
```

### Social Media Icons

Social icons are typically dark or branded colored on transparent backgrounds. Best approaches:

1. **White icons on colored circles** — works in both modes:
   ```html
   <td style="background-color:#1DA1F2; border-radius:50%; width:32px; height:32px; text-align:center; vertical-align:middle;">
     <a href="https://twitter.com"><img src="icon-twitter-white.png" alt="Twitter" width="18" height="18"></a>
   </td>
   ```

2. **Branded colored icons** with sufficient contrast for both modes

3. **Two sets of icons** with show/hide (most work, but most reliable)

---

## Testing Dark Mode Rendering

### Manual Testing Checklist

1. **Apple Mail (macOS)**
   - System Preferences > Appearance > Dark
   - Send test email to iCloud/Gmail account configured in Apple Mail
   - Verify `prefers-color-scheme` styles apply

2. **Apple Mail (iOS)**
   - Settings > Display & Brightness > Dark
   - Check the email in Mail app

3. **Outlook Desktop (Windows)**
   - File > Office Account > Office Theme > Dark Gray or Black
   - Note: Outlook uses its own dark mode engine, not `prefers-color-scheme`

4. **Outlook.com (Web)**
   - Settings > General > Appearance > Dark mode
   - Test `[data-ogsc]` and `[data-ogsb]` selectors

5. **Outlook Mobile (iOS/Android)**
   - App Settings > Appearance > Dark
   - Test `[data-ogsc]` and `[data-ogsb]` selectors

6. **Gmail (Web)**
   - Settings > Themes > Dark
   - Note: No developer control over dark mode rendering

7. **Gmail (Android/iOS)**
   - System dark mode setting
   - Note: Limited control; Gmail applies its own inversion

### Automated Testing Tools

| Tool | Dark Mode Testing | Notes |
|---|---|---|
| **Litmus** | Yes | Preview dark mode renders across many clients |
| **Email on Acid** | Yes | Dark mode previews and comparison views |
| **Testi@** | Yes | Outlook-focused testing |
| **PutsMail** | No | Sends test emails but no render previews |
| **Mail-Tester** | No | Spam scoring only |

### Key Things to Verify in Dark Mode

- [ ] Body/wrapper background changes appropriately
- [ ] Email container background changes appropriately
- [ ] All text remains readable (sufficient contrast)
- [ ] Links are visible and distinguishable from body text
- [ ] Buttons maintain readability and visual prominence
- [ ] Logo is visible (not disappearing into the background)
- [ ] Images do not look broken or inverted unexpectedly
- [ ] Borders/dividers are visible
- [ ] Footer text is readable
- [ ] Social icons are visible
- [ ] No elements have "reverse contrast" (light text on light dark-mode background)

### Dark Mode Contrast Requirements

For accessibility, maintain WCAG AA contrast ratios in both modes:

| Element | Minimum Contrast Ratio |
|---|---|
| Body text | 4.5:1 |
| Large text (18px+ or 14px+ bold) | 3:1 |
| UI components (buttons, links) | 3:1 |
| Placeholder/muted text | 4.5:1 (ideally; 3:1 minimum) |

### Recommended Dark Mode Color Palette

```
Background (primary):    #16213e  — Deep navy, easy on eyes
Background (secondary):  #1a1a2e  — Slightly darker, for depth
Text (primary):          #e4e4e7  — Off-white, reduces glare vs pure white
Text (secondary):        #a1a1aa  — Muted gray, for supporting text
Text (muted):            #71717a  — Dimmer gray, for timestamps etc.
Accent/links:            #818cf8  — Lightened indigo, visible on dark
Borders:                 #2d3748  — Subtle dark border
Success:                 #34d399  — Lightened green
Warning:                 #fbbf24  — Amber (visible on dark)
Error:                   #f87171  — Lightened red
```

These colors maintain AA-level contrast against the `#16213e` background.
