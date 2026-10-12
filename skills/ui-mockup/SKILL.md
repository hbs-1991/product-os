---
name: ui-mockup
displayName: "🖼️ UI Mockup — image mocks of screens, components and widgets"
description: >
  Generate image mockups of user interfaces — dashboards, pages, cards, widgets,
  tables, forms, modals, mobile screens, empty/loading/error state sheets and short
  screen flows — through the gpt-image-2 skill. Use when the user asks to "нарисуй
  мокап", "сделай макет экрана", "покажи как будет выглядеть виджет", "картинку
  интерфейса", "набросай вайрфрейм", "mock up this card", "generate a UI mockup",
  "design a component image", "wireframe this page", "show me what this screen would
  look like", or wants a picture of an interface before it is built in code. Covers
  the style presets, layout anatomy, the specification template, image-to-image
  iteration with --ref, and the verification pass.
emoji: "🖼️"
---

# UI Mockup

A picture of an interface that does not exist yet — to agree on layout, density and hierarchy
before anyone writes JSX. One image, one screen (or one sheet of related states).

Generation runs through the **`gpt-image-2`** skill. This skill is the brief that goes into it:
a style preset, a layout specification written like a build order, and a verification pass that
catches the two lies image models tell — misspelled labels and charts that contradict their own
numbers.

**This produces an image, not code.** When the user wants working UI, build components instead;
when they want to *look* at an idea first, generate here. If genuinely unclear, ask in one line.

## Workflow

1. **Name the artifact and its container.** A card? a widget inside a dashboard? a whole page? a
   mobile screen? a sheet of four states? The answer sets the canvas ratio and how much
   surrounding chrome (sidebar, top bar, tab bar) must be drawn.
2. **Pick a preset and a fidelity mode.** `--list-presets` gives the catalogue; selection
   guidance and how to derive a project-specific style live in `references/style-presets.md`.
   Default to hi-fi; use the `wireframe` preset when the open question is structure, not looks.
3. **Write the specification** with the template below, using the per-artifact recipes in
   `references/anatomy.md`. Every visible string in single quotes, every proportion as a number.
4. **Generate**, in the background — it can take a few minutes:

   ```bash
   bash <ui-mockup base dir>/scripts/mock.sh \
     --preset dashboard-dark --aspect 16:9 \
     --out /abs/path/mocks/cases-dashboard.png \
     --spec "<the specification>"
   ```

   `--dry-run` prints the composed prompt without generating — use it to check the assembly.
   `--ref <image>` (repeatable) switches to image-to-image; see "Iterating with --ref".
5. **Read the PNG back** with the Read tool and run the verification checklist. Not optional:
   the model will render `Total` as `Tota1` and still look convincing at thumbnail size.
6. **Regenerate at most twice**, and only for a real defect. If the same element fails twice,
   simplify or drop it from the spec rather than fighting the model.
7. **Deliver the image** — display it, say what it shows and which file to keep. Never stop at
   "done, the file is at X".

## The specification template

Describe the screen to an illustrator who cannot ask questions and has never seen the product.
Order matters: canvas → chrome → content grid → region by region → data → emphasis.

```
A <page|component|sheet> of <product name>: <one sentence on what it is for>.

Layout: <how the frame is divided, with numbers — 'a 240px left sidebar, the rest content',
'a 3-column grid of equal cards', '4 panels in a 2x2 grid with 24px gutters'>.

TOP BAR (64px tall): <left content>, <right content>. Every label in quotes.

REGION 1 — <name>, <position and size>: <what objects, in what arrangement>, labels
'<A>', '<B>', '<C>'. <The values, and how each is rendered.>

REGION 2 — ... same shape ...

Data: <the concrete strings and numbers that must appear, with units>.
Emphasis: <the single element that is the visual focus>.
```

Rules that earn their place in every spec:

- **State proportions as numbers.** "the sidebar takes 18 percent of the width", "the first
  column is twice as wide as the other three", "the green segment is exactly one quarter of the
  bar". Without numbers the model draws whatever *feels* balanced.
- **Quote every string that must appear**, and keep the total under ~25 distinct strings. Past
  that, labels start losing letters. Long body copy is a defect, not a feature — ask for grey
  placeholder bars instead.
- **Name the arrangement, not just the contents.** "in a single row, equal width, 16px apart"
  beats "some KPI cards".
- **Say where a label goes** when its shape is too small to hold it: "the value above the label,
  both left-aligned inside the tile".
- **Specify the empty parts.** "the area right of the form stays empty white space" is what
  stops the model from inventing a panel there.
- **One accent, one focus.** Name the primary action; everything else stays neutral.
- **Escape `$` in the shell** (`~\$1,200`) and avoid backticks inside the spec string.
- **Localisation:** for a Russian-language UI say so explicitly — "all interface labels in
  Russian" — and keep strings short; Cyrillic garbles faster than Latin. For long or
  business-critical Russian copy, prefer the `wireframe` preset or accept Latin labels.

## Fidelity modes

| Mode | Preset | Use when |
|---|---|---|
| Hi-fi (default) | any themed preset | agreeing on the actual look, showing a stakeholder, seeding a component build |
| Wireframe | `wireframe` | arguing about structure, density and flow; early exploration; copy not settled |
| State sheet | any + `--aspect 16:9` | default / empty / loading / error of one component in one image |
| Flow sheet | any + `--aspect 16:9` or `2:1` | 3 screens left to right with captions and arrows, one user path |

Sheets are one image with labelled panels — recipes in `references/anatomy.md`. Do not exceed
4 panels per sheet: a fifth makes every label unreadable at review size.

## Iterating with --ref

Image-to-image is the cheap way to keep a series consistent and to make a local change:

```bash
bash <ui-mockup base dir>/scripts/mock.sh --ref mocks/v1.png \
  --preset dashboard-dark --out mocks/dashboard-v2.png \
  --spec "Keep this exact layout, palette, typography and spacing. Change ONLY the left
          sidebar: replace the 5 nav items with 'Deals', 'Cases', 'Finance', 'Documents'.
          Everything else pixel-identical."
```

Three uses that work reliably:

- **Series consistency** — pass the previous screen as `--ref` so screen 2 of a flow inherits the
  chrome, palette and rhythm of screen 1.
- **Targeted edit** — "change ONLY <X>, keep everything else identical". Expect a redraw, not a
  patch: the result resembles the original, it is never a pixel-exact diff.
- **Style transfer from the real product** — pass a screenshot of the existing app and ask for a
  new screen "in the visual style of the attached interface".

For anything more structural than a local edit, rewrite the spec and generate fresh.

## Verification

Read the generated PNG and check, in this order:

1. **Text.** Every quoted string present and correctly spelled, no invented words, no doubled
   labels, nothing clipped by its container. By far the most common defect.
2. **Data fidelity.** Bars, segments and sparklines agree with their numbers; a total equals the
   sum of its parts; a "+12%" badge sits on a rising line, not a falling one.
3. **Structure.** The specified regions exist, in the specified positions, with no extra panels
   or menu items the spec never asked for.
4. **Craft.** Aligned edges, equal gaps, one icon set, one stroke width, consistent radii.
5. **Series consistency** when it belongs to a set: same chrome, same palette, same density.

Keep a flawed attempt on disk under a different name (`-2b`) rather than overwriting — the
earlier composition is often the better one — and state plainly which file is the good one.

## Output

Write images into a `mocks/` (or `docs/mocks/`) directory next to the work they describe, named
for the screen: `mocks/cases-dashboard-v1.png`. Suffix retries (`-v2`, `-2b`), never overwrite.

## Additional resources

- **`references/style-presets.md`** — the preset catalogue, when each fits, and how to derive a
  project-specific style block from Tailwind tokens or a screenshot.
- **`references/anatomy.md`** — per-artifact spec recipes: card, KPI tile, chart widget, table,
  full dashboard page, form, modal, mobile screen, state sheet, flow sheet, landing page.
- **`references/prompt-recipes.md`** — complete worked specifications that produced good results,
  plus the failure modes and their fixes.
- **`scripts/mock.sh`** — the wrapper: composes preset + canvas + spec + rendering constraints and
  calls the `gpt-image-2` generator. Flags: `--list-presets`, `--dry-run`, `--ref`, `--style-file`,
  `--aspect`, `--size`, `--quality` (default `high`, API backend only), `--backend auto|api|codex`, `--timeout-sec`, `--no-rules`. Needs `OPENAI_API_KEY` or a logged-in `codex` CLI (see the gpt-image-2 skill's backend rule).
- **`assets/presets/*.txt`** — the verbatim style token blocks; **`assets/render-rules.txt`** — the
  constraints appended to every prompt.

## Hard constraints

- Do not silently substitute an HTML/React mockup, a screenshot or another image model when the
  user asked for a generated mock. If `gpt-image-2` is unavailable (neither `OPENAI_API_KEY` nor a logged-in
  `codex` CLI, no access to the model, quota exhausted), say so in one sentence and offer the alternative — do not fake it.
- Do not promise pixel-exact edits from `--ref`; every generation redraws the whole image.
- Do not ship a mock without reading it back first.
