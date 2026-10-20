# Podium design system ("Aurora")

The look and motion language of the Podium mobile app, written so the web app
can match it. Source of truth in code:

- Colors: `assets/colors/colors.xml` (generated into `lib/gen/colors.gen.dart`)
- Theme: `lib/utils/theme.dart`
- Components and tokens: `lib/widgets/ui/app_ui.dart`
- Gradients, background and motion helpers: `lib/widgets/ui/aurora.dart`
- Call-room audio visuals: `lib/app/modules/ongoingOutpostCall/widgets/voice_level.dart`

Alpha values below are given both as Flutter `withAlpha(n)` (0–255) and as CSS
opacity, so they can be copied into either codebase.

## Personality

Dark, deep-navy night sky with slowly drifting cyan, violet and magenta
"aurora" glows. Surfaces are translucent glass with hairline gradient borders.
Accents are luminous rather than saturated blocks. Motion is small, quick and
soft: things fade and slide a few pixels, never bounce across the screen.

## Color tokens

| Token | Hex | Role |
| --- | --- | --- |
| `page-background` | `#0B0B1E` | App/page base, status bar |
| `navbar-background` | `#0E0E26` | Bottom nav, call control dock |
| `card-background` / `surface` | `#14142B` | Cards; also text on primary fills |
| `surface-raised` | `#1B1B36` | Sheets, dialogs, menus, tooltips, snackbars |
| `card-border` | `#2A2A40` | Hairlines, dividers, input borders |
| `primary` (cyan) | `#54E4EF` | Primary actions, links, focus, active state |
| `violet` | `#8B5CF6` | Aurora accent, glows |
| `magenta` | `#FF4FD8` | Aurora accent (sparingly) |
| `secondary-blue` | `#4579FD` | Legacy accent |
| `success` | `#3DDC97` | Success, "speaking", "you" in creator line |
| `danger` / `live` | `#F04141` | Errors, destructive actions, LIVE badge |
| `warning` / `accent` | `#FFC857` | Warnings, scheduled, host star, raised hand |
| `text` | `#FFFFFF` | Primary text |
| `text-muted` (grey) | `#C1C1C4` | Secondary text, captions, labels |
| `text-faint` | `#8A93B5` | Inactive nav items, tertiary text |

Derived colors:

- **Glass surface**: `#14142B` at `withAlpha(200)` = `rgba(20,20,43,0.78)`.
- **Fill** (inputs, chips, icon buttons on a surface): white at `withAlpha(12)` = `rgba(255,255,255,0.047)`. Inputs use `withAlpha(10)`.
- **On primary**: text/icons on a cyan or cyan→violet fill use `#14142B`, not white (white on cyan is illegible).
- **Tinted chips/pills**: background = color at alpha 22–28 (~0.09–0.11), border = color at alpha 55–70 (~0.22–0.27), text = the color.
- **Tags**: neutral fill chips, `#` in `text-faint` followed by the tag in `text-muted` 12/600.

## Gradients

```css
/* Declare inside :root alongside the tokens in "CSS starter". */
--grad-primary: linear-gradient(90deg, #54E4EF, #8B5CF6);           /* buttons, active tab */
--grad-aurora: linear-gradient(135deg, #54E4EF, #8B5CF6, #FF4FD8);  /* live mic button */
--grad-ring: conic-gradient(#54E4EF, #8B5CF6, #FF4FD8, #54E4EF);    /* speaking avatar ring */

/* Hairline border on glass cards (1px stroke, top-left to bottom-right) */
--grad-card-border: linear-gradient(135deg,
  rgba(84,228,239,0.44) 0%,
  rgba(139,92,246,0.19) 35%,
  rgba(255,255,255,0.08) 70%,
  rgba(255,79,216,0.25) 100%);

/* Navbar/dock top hairline */
--grad-hairline: linear-gradient(90deg,
  rgba(84,228,239,0), rgba(84,228,239,0.5), rgba(139,92,246,0.5),
  rgba(255,79,216,0.5), rgba(255,79,216,0));
```

Gradient buttons ("gradient shell") carry two soft shadows:
violet `rgba(139,92,246,0.27)` blur 18 offset (0, 6) and
cyan `rgba(84,228,239,0.16)` blur 12 offset (-4, 0).

## Aurora background

Base `#0B0B1E`, plus four large radial blobs that drift on a 28 s loop.
Each blob is a radial gradient: color at full alpha → alpha/3 at 45% → 0.

| Color | Anchor (x, y of page) | Drift (x, y) | Radius (× longest side) | Alpha |
| --- | --- | --- | --- | --- |
| cyan | 0.10, 0.05 | 0.18, 0.08 | 0.75 | 70 (0.27) |
| violet | 0.95, 0.30 | 0.15, 0.12 | 0.80 | 80 (0.31) |
| magenta | 0.15, 0.85 | 0.20, 0.10 | 0.70 | 55 (0.22) |
| cyan | 0.85, 0.95 | 0.12, 0.08 | 0.55 | 35 (0.14) |

Position: `x = anchor.x + sin(t + phase) * drift.x`,
`y = anchor.y + cos((t + phase) * 0.8) * drift.y`; radius breathes ±8%.
Phases are 0, 0.33, 0.66, 0.5 of a turn. On web this works well as a fixed
`<canvas>` behind the app, or as four absolutely positioned blurred divs
animated with CSS keyframes.

## Typography

Font: **Sora** everywhere.

| Style | Size / weight / line height | Use |
| --- | --- | --- |
| Page title | 28 / 800 / 1.15 | Top-level page headers ("Home") |
| Sub-page title | 20 / 700 | Headers with a back button |
| Title | 18 / 700 | Sheet and dialog titles |
| Card title | 15 / 700 (16 on outpost cards, 1.25) | Card headings |
| Body | 14 / 400 / 1.4 | Paragraphs |
| Muted | 13, grey | Subtitles, descriptions |
| Caption | 12, grey | Meta text |
| Label | 12 / 700, letter-spacing 1.2, UPPERCASE, grey | Section headers ("ON STAGE") |
| Chip/pill | 12 / 600–700 | Chips, pills, badges |

Numbers that change (timers, counts) use tabular figures
(`font-variant-numeric: tabular-nums`).

## Shape and spacing

- Radii: `sm 12`, `md 14` (inputs, buttons, small cards), `lg 18` (cards,
  primary buttons), `xl 24` (sheets, dialogs). Pills and chips: fully round.
- Page horizontal padding: 16 (cards), 20 (headers and section labels).
- Card padding 14–16; gap between list cards 10–12.
- Primary/secondary buttons: full width, 52 tall. Compact header buttons: 36.
  Icon buttons: circular, 36–40.

## Components

- **Glass card**: glass surface fill, radius 18, 1px gradient border
  (`--grad-card-border`). When tappable: press scale 0.985 and a faint violet
  ripple. Selected/attention state swaps the gradient border for a solid
  primary border at alpha 90–140.
- **Primary button**: `--grad-primary` fill + gradient-shell shadows, text
  `#14142B` 15/700, radius 18, press scale 0.97. Loading: 20px spinner in the
  text color. Disabled: white at alpha 18 with white-alpha-90 text.
- **Secondary button**: fill color, 1px `card-border`, white text.
- **Icon button**: circle, fill color, 1px `card-border`, white icon at 50% of size.
- **Pill / status chip**: tinted chip (see derived colors). LIVE badge: red tint,
  pulsing red dot, "LIVE" 12/800 letter-spacing 0.6, white count.
- **Inputs**: fill white alpha 10, radius 14, border `card-border`, focus border
  primary 1.4px, hint grey 14.
- **Segmented tabs**: container fill + border radius 14, 4px padding; the
  selected tab is `--grad-primary` radius 10 with a violet glow, label `#14142B`.
- **Bottom sheet**: `surface-raised`, top radius 24, top border `card-border`,
  40×4 grabber.
- **Outpost card**: glass card whose fill glows from the top-left with a
  "tone" (alpha 30 dark / 18 light, fading out by 60%) and whose gradient
  border uses the same tone. Tone is `live` when people are online, `text-faint`
  when archived, otherwise the access color: public = primary (globe),
  link only = lilac (link), invite only = pink (person lock), ticket gated =
  warning (Arena: ticket, Friendtech: key, Podium Pass: badge). Lilac and pink
  are violet/magenta lerped 35% toward white on dark palettes. The access icon
  sits in a 24px badge on the thumbnail's bottom-right corner and leads the
  meta row as a tinted pill; members and speakers follow as plain
  icon + caption, and recordable/Luma/18+ are 24px icon-only circles.
  Scheduled outposts show a strip (warning tint, green once started) with a
  38px date tile, "Today/Tomorrow/weekday · time" and a countdown
  ("in 2d 3h", "in 12m 5s", "18m ago"); hidden two hours after the start.
  Archived cards greyscale the thumbnail and show an "Archived" pill. The
  creator line reads "Hosted by you" in success for your own outposts, with a
  small "JOINED" primary badge when you're a member.
- **Dialog**: `surface-raised`, radius 24, optional 52px tinted circular icon.
- **Empty state**: 72px circle with a cyan→violet→magenta tint at alpha ~46,
  violet border, soft violet glow; title + muted message, optional action.
- **Bottom nav**: `navbar-background` with `--grad-hairline` on top. Active
  item: pill behind the icon (56 wide vs 44 inactive, 30 tall) filled with
  cyan→violet at alpha 56 (0.22) and a violet glow; icon becomes filled and cyan;
  label 12/700 white. Inactive label 12/500 `text-faint`. Unread badge: red
  pill with a 2px navbar-colored outline.
- **Page header**: page title on the left with a muted subtitle beneath;
  compact 36px actions on the right (for example refresh + gradient
  "Start new outpost" button). A gradient hairline fades in under the header
  once the list scrolls.

## Motion

Every animation is disabled when the OS asks for reduced motion
(`prefers-reduced-motion: reduce` on web).

| Pattern | Spec |
| --- | --- |
| List entrance | Opacity 0→1 and translateY 18px→0, 420 ms ease-out-cubic, staggered 60 ms per item (cap at item 6). Play once per item id, not again on scroll-back. |
| Press | Scale to 0.97 (cards 0.985, nav items 0.92, small round buttons 0.9) in 120 ms ease-out. |
| State crossfade | Skeleton ↔ empty ↔ list: 280 ms fade. |
| Rolling text | When a count or subtitle changes, old text slides up 60% of its height and fades out while new text slides in from below; 300 ms, ease-out-cubic in / ease-in-cubic out, clipped to the text box. |
| Badge pop | New badges/pills scale 0→1 with ease-out-back, 240–320 ms; raised hand uses elastic-out. |
| Sheen | A soft white band (35% of width, peak alpha 0.35) sweeps across gradient buttons in 1.1 s ease-in-out, first after 1.2 s, then every 7 s. |
| Breathing | 0→1→0 ease-in-out, 1.6 s (glows), 2.6–2.8 s (floating illustrations, ±3–4px). |
| Collapsing label | "Start new outpost" shrinks to a "+" after 3 s (400 ms ease-in-out-cubic) while the plus turns a quarter turn. |
| Refresh button | 36px circle. While loading: icon turns cyan and spins (850 ms per turn, linear), a 2px cyan→violet arc (252°) spins around it, a violet glow fades in, taps are ignored. When loading ends the spin eases to the end of its turn (ease-out-cubic, 200 + 500 × remaining ms), then a green check pops in for 1.1 s. |
| Nav icon | Active icon swaps with scale 0.6→1 ease-out-back 320 ms; pill width/color 220 ms ease-out-cubic. |
| Skeletons | Shimmer white alpha 16 → 40 over card-shaped blocks. |

## Live audio (call room)

Jitsi sends each participant's mic level (0–1) about every 150 ms. The app
rounds to steps of 0.1, decays silent levels by ×0.75 every 150 ms, and eases
the displayed value over 160 ms.

- **Avatar halo**: radial glow from violet (alpha 170 × strength) to cyan
  (alpha 90 × strength) to transparent, its radius growing with the level;
  `strength = min(1, level × 1.4)`. The avatar scales up by `1 + 0.05 × level`.
- **Speaking ring**: `--grad-ring` stroke (≈6% of avatar size + 1.5px) while
  unmuted or audible; plain `card-border` stroke otherwise.
- **Voice bars**: 3–4 rounded bars (width = height/5, gap = 0.7 × width) rest at
  22% height and rise with `min(1, level × 1.6)`, weighted 0.7/1.0/0.8/0.6, each
  wobbling on its own sine (900 ms loop) only while audible. Used in the stage
  mic badge (black on success), participant rows and "You're live" card.
- **Mic button**: 68px circle with `--grad-aurora` when live. Its violet/cyan
  glow follows `max(breath × 0.5, level × 1.4)` and it scales by
  `1 + 0.06 × level`.
- **Dominant speaker**: name under the avatar fades to `success` and semibold.

## CSS starter

```css
:root {
  --bg: #0B0B1E;
  --nav-bg: #0E0E26;
  --surface: #14142B;
  --surface-glass: rgba(20, 20, 43, 0.78);
  --surface-raised: #1B1B36;
  --border: #2A2A40;
  --fill: rgba(255, 255, 255, 0.047);
  --primary: #54E4EF;
  --on-primary: #14142B;
  --violet: #8B5CF6;
  --magenta: #FF4FD8;
  --success: #3DDC97;
  --danger: #F04141;
  --warning: #FFC857;
  --text: #FFFFFF;
  --text-muted: #C1C1C4;
  --text-faint: #8A93B5;

  --radius-sm: 12px;
  --radius-md: 14px;
  --radius-lg: 18px;
  --radius-xl: 24px;

  --ease-out: cubic-bezier(0.215, 0.61, 0.355, 1);     /* easeOutCubic */
  --ease-in-out: cubic-bezier(0.645, 0.045, 0.355, 1); /* easeInOutCubic */
  --ease-back: cubic-bezier(0.175, 0.885, 0.32, 1.275); /* easeOutBack */

  font-family: "Sora", system-ui, sans-serif;
  color: var(--text);
  background: var(--bg);
}

.glass-card {
  position: relative;
  background: var(--surface-glass);
  border-radius: var(--radius-lg);
}
.glass-card::before { /* 1px gradient border */
  content: "";
  position: absolute;
  inset: 0;
  padding: 1px;
  border-radius: inherit;
  background: var(--grad-card-border);
  -webkit-mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
  pointer-events: none;
}

.btn-primary {
  background: var(--grad-primary);
  color: var(--on-primary);
  border-radius: var(--radius-lg);
  font-weight: 700;
  box-shadow: 0 6px 18px rgba(139, 92, 246, 0.27), -4px 0 12px rgba(84, 228, 239, 0.16);
  transition: transform 120ms ease-out;
}
.btn-primary:active { transform: scale(0.97); }

@keyframes entrance {
  from { opacity: 0; transform: translateY(18px); }
  to { opacity: 1; transform: none; }
}
.list-item {
  animation: entrance 420ms var(--ease-out) both;
  animation-delay: calc(min(var(--i), 6) * 60ms);
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation: none !important; transition: none !important; }
}
```
