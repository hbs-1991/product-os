# Anatomy of a spec, per artifact

What to state for each kind of mock, and the numbers the model needs in order not to guess.
Snippets are spec fragments — pass them to `mock.sh --spec` after filling the angle brackets.
The style block and the rendering constraints are added by the script; never restate them here.

## Choosing the canvas

| Artifact | `--aspect` | Chrome to draw |
|---|---|---|
| Single card / component | `1:1` or `4:3` | none — the component centred on the page background with even margin |
| Widget in context | `4:3` | a hint of the surrounding grid, cropped at the frame edge |
| Full desktop page | `16:9` | sidebar + top bar + content |
| Wide desktop page / flow sheet | `2:1` | as above, or 3 phone screens side by side |
| Mobile screen | `9:16` | status bar, nav/app bar, tab bar; no device bezel unless asked |
| State sheet (2x2) | `16:9` or `4:3` | none — 4 copies of the component, each with a caption |
| Landing page | `4:5` or `9:16` | browser chrome only if asked; usually a bare page |

## Card / component

State the container, then the content top to bottom, then the interactive elements.

```
A single <what> card, centred, 480px wide, on the plain page background with even margin
around it. Card content, top to bottom:
- Header row: a <icon> icon in a rounded tinted square on the left, title '<Title>' next to
  it, and a small pill badge '<Badge>' on the right.
- Body: <the fields, each as a label/value pair, label above value, left-aligned, 12px apart>:
  '<Label A>' / '<Value A>', '<Label B>' / '<Value B>'.
- A thin divider, then a footer row: a ghost button '<Secondary>' and a solid primary button
  '<Primary>' aligned to the right.
Emphasis: the primary button is the only filled colour element in the card.
```

Two failure modes: cards drift oversized (say the width), and the model adds a decorative
illustration (say "no illustration, no photo" when it keeps happening).

## KPI tile / stat widget

```
A row of 4 equal-width KPI tiles, 16px apart, each 1/4 of the width minus gutters. Each tile:
a small uppercase label at the top ('<LABEL>'), a large bold value below it, and a small
delta badge to the right of the value (green with an up arrow for positive, red with a down
arrow for negative). Tiles, left to right:
'REVENUE' — '$4.2M' — '+12%'; '<...>'.
Under each value, a flat 24px-tall sparkline in the accent colour whose shape agrees with the
delta sign.
```

Always state that the sparkline direction must match the delta — the model pairs them randomly
otherwise.

## Chart widget

Name the chart type, the axes, the number of series, the series names, and the shape of the
data. A chart with an unstated shape comes back as noise.

```
A chart panel, 720x400, titled '<Title>' with a small '<Last 30 days>' dropdown at the top
right. A line chart with 2 series: '<Series A>' in the primary accent and '<Series B>' in the
secondary accent, both 2px with a 25% opacity fill under the line. X axis: 6 month ticks
'Jan'…'Jun'. Y axis: 4 gridlines, ticks '0', '1M', '2M', '3M'. Series A rises steadily and
ends about twice as high as it starts; Series B is flat with one dip in the middle. Legend as
two small dot+label chips under the title.
```

Rules: state the trend in words ("rises steadily", "one dip in month 4"), state the tick labels,
and never ask for more than 2–3 series or 8 x-ticks in one panel.

## Data table

```
A data table panel, full width, titled '<Cases>' with a search field and a 'Filters' ghost
button on the same row. The table has 6 columns — '<A>' (widest, 30%), '<B>', '<C>', '<D>',
'<E>' (status), '<F>' (right-aligned amount) — and exactly 7 body rows. Header row in muted
uppercase 12px text with a bottom border; body rows 48px tall separated by hairline borders,
no zebra striping. The status column holds pill badges: 3 green '<Paid>', 2 amber
'<Pending>', 2 grey '<Draft>'. Amounts are right-aligned tabular numerals. A pagination
row at the bottom: '1–7 of 42' on the left, page chips '1 2 3' on the right.
```

State the exact row count. "A table with several rows" yields a wall of 20 unreadable rows.

## Full desktop page

Compose the page as chrome + regions, and always spell out the empty areas.

```
A <product> dashboard page, desktop viewport.
Layout: a 240px dark left sidebar, a 64px top bar across the remaining width, and a content
area with 24px padding.
SIDEBAR: product name '<ASA Gateway>' at the top with a small square logo mark, then 6 nav
items with thin-line icons — '<Dashboard>' (active, with a filled accent highlight), '<Deals>',
'<Cases>', '<Finance>', '<Documents>', '<Settings>'. A user chip with an avatar circle and
'<Ivan P.>' pinned at the bottom.
TOP BAR: page title '<Dashboard>' on the left; a search field, a bell icon and an avatar on the
right.
CONTENT, three stacked blocks with 24px gaps:
1. <KPI row — see the KPI recipe>
2. A 2-column row: a 65%-wide chart panel <chart recipe> and a 35%-wide list panel titled
   '<Recent activity>' with 5 rows of icon + short label + timestamp.
3. <Table recipe>
Emphasis: the KPI row reads first, then the chart.
```

## Form / settings screen

```
A settings form, 720px wide content column, left-aligned, the area to its right left empty.
Section heading '<Company profile>' with a one-line grey description under it, then 5 fields
stacked 20px apart, each a label above a full-width input with a 1px border and 8px radius:
'<Name>' (filled with '<Acme Logistics>'), '<Tax ID>' (filled), '<Email>' (filled),
'<Plan>' (a select with a chevron, showing '<Basic>'), '<Time zone>' (a select).
One field, '<Email>', shows an error state: red border and a red 12px message under it,
'<Invalid format>'. A footer row with a ghost 'Cancel' and a solid 'Save'.
```

## Modal / dialog

```
A modal dialog centred over a dimmed blurred page behind it (the background page is only
suggested, out of focus, no readable text). The dialog is 480px wide, 16px radius: a title
'<Delete case?>', a two-line grey body text, a checkbox row '<I understand the consequences>', and
a footer with a ghost 'Cancel' and a solid red 'Delete' aligned right. A small X in the top
right corner.
```

## Mobile screen

Say the platform preset does the chrome; the spec does the content. Do not draw a device bezel
unless the user asks for a "device mockup".

```
A mobile screen of <product>. Status bar, then a nav bar with the title '<Cases>' and a
trailing filter icon. Content: a segmented control with '<Active>' / '<Archive>' (first
selected), then a scrolling list of 5 cards, each 88px tall: a 40px rounded avatar-square on
the left, two text lines in the middle (bold title '<...>' and a grey subtitle '<...>'), and a
status pill plus a chevron on the right. Bottom tab bar with 4 items — '<Home>' (active),
'<Cases>', '<Finance>', '<Profile>'.
```

## State sheet (default / empty / loading / error)

One component, four states, one image. Captions belong *outside* the panels.

```
A 2x2 grid of four panels, 24px gutters, on a plain background. All four panels show THE SAME
<component> at the same size and position; only its state differs. Above each panel, a small
grey uppercase caption: 'DEFAULT', 'EMPTY', 'LOADING', 'ERROR'.
1 DEFAULT: <the populated component — 3 rows of data>.
2 EMPTY: the same frame with a centred thin-line illustration glyph, the line '<No cases yet>' and a small ghost button '<Create case>'.
3 LOADING: the same frame with 3 grey skeleton rows — rounded bars at 100%, 80% and 60% width.
4 ERROR: the same frame with a red-tinted icon, '<Failed to load>' and a '<Retry>'
  ghost button.
The four frames are pixel-identical in size and alignment.
```

## Flow sheet (3 screens, one path)

```
Three <mobile screens|desktop screens> side by side, equal size, 32px apart, on a plain
background, connected by two thin arrows pointing left to right. Under each screen a small
grey caption: '1. <Choose cargo>', '2. <Get a rate>', '3. <Confirm>'.
SCREEN 1: <content>. SCREEN 2: <content>. SCREEN 3: <content>.
All three share the same chrome, palette and typography; only the content area differs.
```

For more than three steps, generate two sheets rather than shrinking the screens — or generate
each screen separately with `--ref` on the previous one.

## Landing page

```
A landing page for <product>, full page from the top, no browser chrome.
HEADER: logo mark and wordmark '<ASA>' on the left, 4 nav links '<Product>', '<Pricing>',
'<Cases>', '<Contact>' centred, a solid 'Get started' button on the right.
HERO: a 56px headline '<One system instead of ten spreadsheets>' over two lines, an 18px grey
subline, a solid primary button '<Try it>' and a ghost '<Demo>' beside it. On the right,
a flat preview panel of the product dashboard (simplified: a sidebar, 3 KPI tiles, one chart).
LOGO STRIP: 5 neutral grey invented wordmarks in a row.
FEATURES: a 3-column card row, each with a thin-line icon in a rounded tinted square, a bold
title and two lines of grey placeholder bars: '<Rates>', '<Cases>', '<Finance>'.
CTA BAND: a full-width tinted band with a centred line '<Start in 10 minutes>' and one button.
```
