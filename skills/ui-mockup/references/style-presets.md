# Style presets

Each preset is a verbatim style-token block in `assets/presets/<name>.txt`, prepended to the
prompt by `scripts/mock.sh --preset <name>`. The token text itself is not repeated here — read
the `.txt` only when a token needs to be quoted or edited. This page is for **choosing**.

`bash scripts/mock.sh --list-presets` prints the live list.

## The catalogue

| Preset | Look | Pick it when |
|---|---|---|
| `saas-light` | Light web app, white cards on #F7F8FA, indigo accent, airy | Default for any B2B web screen: CRM, admin panel, settings, list+detail. Safest choice when the user has no opinion. |
| `dashboard-dark` | Dark analytics, #0B0F17 canvas, blue/violet accents, tabular numerals | Metrics, monitoring, charts, trading- or ops-style density. Also the best backdrop for a chart widget shown alone. |
| `shadcn-neutral` | shadcn/ui + Tailwind, zinc neutrals, borders not shadows, 8px radius | The project is actually built on shadcn/Tailwind and the mock must look like what will be shipped. |
| `glass-dark` | Frosted translucent panels, violet/cyan glow on near-black | Consumer-premium products, chat and messaging UI, launch screens, anything meant to feel expensive. |
| `ios-native` | iOS 17: SF Pro, grouped lists, system blue, tab bar + home indicator | An iPhone screen that must read as native, not as "a website on a phone". |
| `android-material` | Material 3: Roboto, tonal surfaces, purple primary, FAB, pill nav | An Android screen, or a cross-platform app shown in its Android skin. |
| `wireframe` | Greyscale lo-fi, placeholder bars, one grey-blue accent | The discussion is about structure, density or flow. Also the safest mode for long or Cyrillic copy — no colour to distract from a garbled word. |
| `marketing-page` | Landing page: big hero, 3-column feature grid, section rhythm | Marketing site, product page, pricing page, hero concepts. |

## Combining preset and fidelity

The preset carries the *look*; the spec carries the *structure*. Two knobs to remember:

- **A wireframe of a themed product** — use `wireframe` and mention the product's structure only.
  Do not ask a themed preset to "look like a wireframe"; the model splits the difference and
  produces a washed-out hi-fi screen.
- **A hi-fi screen with unsettled copy** — keep the themed preset and specify grey placeholder
  bars for the unsettled text: "three lines of neutral grey placeholder bars, 100%/85%/60% width".

## Deriving a project-specific style

When the mock must match a real application, build a style block once and reuse it with
`--style-file`:

1. **From design tokens.** Read `tailwind.config.*`, `app.css`/`globals.css` (`--background`,
   `--primary`, `--radius`), or the design system doc. Extract: page background, surface colour,
   border colour and width, corner radius, primary/secondary/success/danger accents, font family,
   base font size, default padding.
2. **From a screenshot.** Open a real screen of the app and describe what is there. `--ref` on the
   screenshot alone also works for a one-off, but a written style block is reusable and does not
   drag the reference's layout into the new screen.
3. **Write it in the same voice as the bundled presets** — one paragraph, starting with
   `STYLE: high-fidelity screenshot of ...`, concrete hex values, explicit typography, explicit
   spacing, and an explicit statement of what the style does *not* use (gradients, shadows, 3D).
4. **Save it** next to the project (`docs/mocks/style.txt`) rather than in this skill, unless it
   is a style worth reusing across projects — then add it to `assets/presets/`.

```bash
bash <ui-mockup base dir>/scripts/mock.sh \
  --style-file docs/mocks/style.txt --aspect 16:9 \
  --out docs/mocks/settings.png --spec "<spec>"
```

## Overriding a preset in the spec

Small deviations belong in the spec, not in a new file — the spec is read after the style block
and wins on conflicts:

> "Use the preset palette, but this screen's primary accent is amber #F59E0B instead of indigo,
> including the primary button and the active nav item."

Keep overrides to two or three; more than that means the preset is wrong for the job.

## What never varies

`assets/render-rules.txt` is appended to every prompt (unless `--no-rules`): flat straight-on
render, pixel alignment, correct spelling, one icon set, no real logos, no invented panels,
numbers that agree with their labels. Do not restate those rules in a spec — they are already
there, and repeating them costs prompt budget that specific layout numbers use better.
