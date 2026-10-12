# Worked specs and failure modes

Complete `--spec` strings, ready to adapt, and the defects that show up when a spec is vague.
The style block and the rendering constraints come from the script — nothing below repeats them.

## Recipe 1 — full dashboard page, dark

```bash
bash <ui-mockup base dir>/scripts/mock.sh \
  --preset dashboard-dark --aspect 16:9 \
  --out mocks/cases-dashboard-v1.png \
  --spec "A freight-forwarding operations dashboard, desktop viewport. All interface labels in Russian, short strings only.
Layout: a 240px left sidebar, a 64px top bar across the rest, content area with 24px padding.
SIDEBAR: a square logo mark and the wordmark 'ASA' at the top, then 6 nav rows with thin-line icons — 'Dashboard' (active, accent-tinted background), 'Deals', 'Cases', 'Finance', 'Documents', 'Settings'. At the bottom, an avatar circle with 'Ivan P.'.
TOP BAR: title 'Dashboard' on the left; a search field, a bell icon and an avatar on the right.
CONTENT, three blocks stacked with 24px gaps:
1. A row of 4 equal KPI tiles, 16px apart. Each: small uppercase grey label on top, large bold value under it, and a delta badge to the right of the value. Left to right: 'OPEN CASES' / '128' / green '+8%'; 'REVENUE' / '$4.2M' / green '+12%'; 'OVERDUE' / '$312K' / red '-4%'; 'MARGIN' / '18.4%' / green '+1.2%'. A flat 24px sparkline under each value, its direction matching the delta sign.
2. A two-column row: on the left, 65 percent of the width, a chart panel titled 'Revenue by month' with a small '6 months' dropdown at its top right — a line chart with 2 series, 'Invoiced' in blue and 'Paid' in violet, 2px lines with a 25 percent opacity fill, x-axis ticks 'Jan' 'Feb' 'Mar' 'Apr' 'May' 'Jun', 4 faint gridlines, y ticks '0' '1M' '2M' '3M'; the blue series rises steadily and ends about twice its starting value, violet tracks below it with one dip in the middle; a two-chip legend under the title. On the right, 35 percent, a panel titled 'Activity' with 5 rows of icon + short label + grey timestamp.
3. A table panel titled 'Recent cases' with 5 columns — 'Case' (30 percent width), 'Client', 'Route', 'Status', 'Amount' (right-aligned) — and exactly 6 body rows, 48px tall, hairline separators, no zebra striping. The status column holds pill badges: 3 green 'Paid', 2 amber 'Pending', 1 grey 'Draft'.
Emphasis: the KPI row reads first, then the chart."
```

What this spec gets right: exact tile count and their exact strings, the sparkline-matches-delta
rule, the trend of each series in words, an exact row count, the width split as percentages.

## Recipe 2 — component state sheet, shadcn

```bash
bash <ui-mockup base dir>/scripts/mock.sh \
  --preset shadcn-neutral --aspect 4:3 \
  --out mocks/case-card-states.png \
  --spec "A 2x2 grid of four panels, 24px gutters, on the plain page background. All four panels contain THE SAME card component at the same size (420px wide) and position; only its state differs. Above each panel, a small grey uppercase caption: 'DEFAULT', 'EMPTY', 'LOADING', 'ERROR'.
The card, in its default state: header row with a small package icon in a rounded muted square, title 'Case SEA-1042' beside it, and a green pill badge 'Paid' on the right; body with three label/value pairs stacked 12px apart — 'Client' / 'Acme Logistics', 'Route' / 'Shanghai — Almaty', 'Amount' / '$1,240,000'; a hairline divider; a footer row with a ghost button 'Details' and a solid black button 'Close case' aligned right.
EMPTY: the same frame, centred thin-line box glyph, the line 'No active cases', a small ghost button 'Create'.
LOADING: the same frame with skeleton placeholders — a grey circle for the icon and four rounded grey bars at 60, 100, 85 and 45 percent width, no text at all.
ERROR: the same frame with a red-tinted alert icon, the line 'Failed to load' and a ghost button 'Retry'.
The four card frames are identical in size and alignment; captions sit outside the cards."
```

## Recipe 3 — mobile flow sheet, three screens

```bash
bash <ui-mockup base dir>/scripts/mock.sh \
  --preset ios-native --aspect 16:9 \
  --out mocks/quote-flow.png \
  --spec "Three iPhone screens side by side, equal size, 32px apart, on a plain light grey background, connected by two thin grey arrows pointing left to right. No device bezels. Under each screen a small grey caption: '1. Details', '2. Rate', '3. Confirm'.
SCREEN 1: nav bar title 'New request'; a grouped form with 4 rows — 'From' / 'Shanghai', 'To' / 'Almaty', 'Cargo' / '2 containers', 'Date' / 'May 12'; a blue full-width button 'Calculate' pinned above the tab bar.
SCREEN 2: nav bar title 'Rate' with a back chevron; a large centred amount '$1,240,000' with the grey line '24 days' under it; below it three grouped rows — 'Freight' / '$980,000', 'Terminal' / '$160,000', 'Delivery' / '$100,000'; a blue button 'Confirm'.
SCREEN 3: a centred green circular checkmark, the headline 'Request sent', a grey line 'Reply within 2 hours', and a blue button 'Back to requests'.
All three screens share the same status bar, tab bar and typography; only the content differs."
```

## Recipe 4 — wireframe of a page, structure only

```bash
bash <ui-mockup base dir>/scripts/mock.sh \
  --preset wireframe --aspect 16:9 \
  --out mocks/finance-wire.png \
  --spec "A wireframe of a finance page. Layout: 200px left nav column with 6 grey rows (the second one filled to show it is active), a 56px top bar with a title bar and two small circles on the right, and the content area with 24px padding.
CONTENT: a row of 3 equal boxes, each with a short heading string and a large placeholder bar for the number; below it, one wide box, two thirds of the width, containing a simple bar chart of 7 grey bars of varying height, and beside it a narrower box with 4 stacked list rows (circle + two placeholder bars each); at the bottom, a full-width table block: a header row of 5 column labels and 6 body rows of placeholder bars, with the rightmost column right-aligned.
Only one element is filled in the accent grey-blue: the primary button in the top right of the table block, labelled 'Create'. Headings are real short strings; all other copy is placeholder bars."
```

## Failure modes

| Symptom | Cause | Fix in the spec |
|---|---|---|
| Garbled or misspelled labels, especially Cyrillic | too many distinct strings, or long ones | cut to under ~25 strings, shorten each; move long copy to placeholder bars; or switch to `wireframe` |
| A chart that contradicts its label | trend never stated | state the shape in words and the tick labels; state that sparkline direction matches the delta sign |
| Extra panels, extra nav items, an invented sidebar | unspecified regions | name every region *and* say what stays empty; state exact counts ("exactly 6 rows", "4 tiles") |
| The component comes back huge, or floating in a strange margin | no size given | give a pixel width and say "centred with even margin on the page background" |
| A photo, a 3D render, a phone in a hand, a desk scene | the model defaulting to "mockup" imagery | the render rules already forbid it; if it recurs, add "flat straight-on UI render, no device frame, no scene" once |
| Every panel drawn in the accent colour | no emphasis stated | end the spec with "Emphasis: <the one element>"; say the rest is neutral |
| Two icon styles in one image | icons described inconsistently | describe icons once, collectively: "thin-line icons, one consistent set" |
| Repeated numbering ("1. 1. Rate") | number in both the badge and the heading | number the badge *or* the heading, and say "no repeated number in the heading text" |
| The retry changed everything, not the one thing | `--ref` edit phrased loosely | "Keep this exact layout, palette, typography and spacing. Change ONLY <X>. Everything else identical." |
| `$` disappeared or the shell errored | unescaped `$` in the spec | escape it (`\$1,200`) or write the currency word |

## Cost and timing

One generation takes from under a minute to a few minutes. Run it with `run_in_background` and do
other work meanwhile — draft the component's props, the copy, or the next spec. A few mocks in
parallel are fine. On the API backend every call is billed to the key's account and counts against
its images-per-minute limit; on the Codex backend expect 2-5 minutes each and no more than two in
parallel (the Codex session queue serialises the rest).
