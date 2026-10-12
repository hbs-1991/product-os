# Visual board

A local page in the owner's browser where you show what is clearer seen than read — layout options, a flow, an architecture diagram, mocks side by side — and the owner answers by clicking.
It is a tool for single questions, not a mode: most of brainstorming stays in the terminal.

## Show it or say it?

| Use the board | Stay in the terminal |
|---|---|
| two or three layouts to compare | a requirement, a scope or a product question |
| a user flow across screens | a trade-off list, A/B/C options in words |
| an architecture or data-flow diagram | anything the owner answers with one sentence |
| the three ui-direction mocks next to each other | |

A question about a UI *topic* is not automatically visual: "who uses this screen?" is a terminal question; "which of these two layouts?" is a board question.

## Offer it once, just in time

The first time a question would be clearer shown, ask in a message of its own (nothing else in it):

> The next question is easier to show than to describe — open a board in your browser with the diagrams and options? (Ask in the owner's language.)

"No" → terminal only, and do not offer again unless the owner asks.

## Start

Node 18+ is the only requirement. Run with the Bash tool, `run_in_background: true`:

```bash
node <brainstorming base dir>/scripts/board.cjs --dir <main checkout>/.plans/brainstorm --open
```

It prints and writes `<dir>/board.json`: `url` (with the access token), `screens`, `choices`.
`--open` opens the owner's browser; otherwise give them the `url`.
The server listens on `127.0.0.1` only and refuses any request without the token.
`<main checkout>` is the repo root from `git rev-parse --path-format=absolute --git-common-dir` minus `/.git`, never a worktree; `.plans/` is a nested git repo excluded from the code repo, so nothing here is committed to it.

## Show a screen

Write an HTML file into `<dir>/screens/`, numbered so the newest is obvious: `01-layout.html`, `02-flow.html`.
The page shows the most recently written file within a second; never edit an old screen to show something new — write the next number.

Write a **fragment** (no `<html>`, `<head>`, `<body>`): the page already has the theme, light and dark.
Put images next to the screens and reference them as `files/<name>` (the page adds the token): `<img src="files/mock-a.png">`.

Building blocks the page styles for you:

| Class / attribute | Use |
|---|---|
| `.options` > `.option` | a grid of text choices |
| `.cards` > `.card` | a grid of visual choices (an image plus a caption) |
| `.split` | two columns side by side (stacks on mobile) |
| `.panel` | a plain bordered box |
| `.mock` | a frame for a wireframe drawn in HTML/CSS or an image |
| `.muted` | secondary text |
| `data-choice="A"` | makes any element clickable; the click is recorded |
| `data-multiselect` | on a container: allows several picks instead of one |

Example:

```html
<h2>Where should the primary action live?</h2>
<p class="muted">Both use the same table; only the action placement differs.</p>
<div class="cards">
  <div class="card" data-choice="A"><img src="files/action-top.png"><h3>A — top-right of the table</h3></div>
  <div class="card" data-choice="B"><img src="files/action-row.png"><h3>B — on every row</h3></div>
</div>
```

Diagrams: draw them as inline SVG or plain boxes and arrows in HTML; keep labels short.

## Read the answer

The owner clicks a choice or types a comment at the bottom of the page.
Every event is one JSON line in `<dir>/choices.jsonl`: `{"at", "screen", "choice", "picked", "label"}` or `{"at", "screen", "note"}`.

After showing a screen, say in the terminal what you put on the board and what you are asking, then wait for the owner's next message.
Then read the lines for that screen — the last `picked: true` per choice wins.
The owner may also just answer in the terminal; that counts the same.
Confirm what you understood in one line before moving on.

## Stop

```bash
node <brainstorming base dir>/scripts/board.cjs --dir <main checkout>/.plans/brainstorm --stop
```

when brainstorming ends. It also exits by itself after two hours without a request.
Screens and `choices.jsonl` stay in the folder as a record of what was shown and chosen.
