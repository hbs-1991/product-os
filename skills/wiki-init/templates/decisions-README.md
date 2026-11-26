# Decisions — dev-time ADR

Decisions made **during implementation** that are not in the design documents. If a decision belongs to frozen design, it belongs there, not here.

Format: ADR-lite, see [_template.md](_template.md).
One file per decision, listed by the folder: `<YYYY-MM-DD>-<slug>.md`, where the file name (without `.md`) is the ADR's id.
The heading is `# <id> — <title>`; an ADR is cited `ADR <id>` and linked `[[decisions/<id>]]`.
Every ADR carries `- **Status:**`, `- **Date:**` and `- **Summary:**` lines; the date in the name is the `Date:` line's date.
There is no table here and no row in `../index.md`: list the folder (`ls`), or grep the `Summary:` lines for a keyword.
