# tools/

Home for **MCP servers and other tools/integrations** that operate on this
knowledge-management vault. Anything that lets an external program or AI
assistant *do work against the vault* — beyond what the `okm` CLI already does
directly — belongs here.

> **Status:** placeholder. Nothing is built yet. This README is a design sketch
> of what *should* live here so the directory has a clear charter before code
> lands. Add real tools as subdirectories (one per tool).

---

## Conventions

Tools here are bound by the same rules as the rest of the framework
([README → Rules](../README.md#rules)):

- **Respect the privacy boundary.** `private/` bodies are AI-private and
  local-only. Any read/search tool must default to *excluding* `private/`
  (mirror `okm`'s `KM_INCLUDE_PRIVATE=1` opt-in). Never expose private content
  to a remote service.
- **Never touch global config.** Project-scoped only — no writes to
  `~/.config/*`, `~/.zshrc`, etc. (see how `env.sh` scopes everything).
- **Offline-first.** Prefer local execution. If a tool needs the network, make
  it explicit and optional; honor [Offline Mode](../README.md#offline-mode).
- **Fork-safe.** No hardcoded paths or usernames; resolve the vault via
  `$OBSIDIAN_VAULT` / `okm path`.
- **Language follows the [Performance policy](../README.md#performance-policy):**
  Bash/Python first, port to Rust once the pattern is hot and stable.
- **Layout:** each tool gets its own subdirectory with its own `README.md`
  (purpose, install, config, MCP manifest if applicable).

Reuse `okm` wherever possible — it already encodes the vault layout, the PARA
model, and the privacy guard. A thin wrapper over `okm` is preferable to
re-implementing vault logic.

---

## Candidate tools

### MCP servers (expose the vault to AI assistants)

- **`vault-mcp`** — the flagship. Wrap `okm` as MCP tools (`search`, `capture`,
  `new`, `today`, `recent`, `tags`, `tagged`) so an assistant can read and
  append notes through the same privacy-aware paths. Default-deny `private/`
  bodies; gate any private access behind an explicit flag.
- **`vault-search-mcp`** — read-only, screen-share-safe search over `public/`
  (ripgrep + tag/PARA filters). Could be a restricted profile of `vault-mcp`
  for contexts where write access is undesirable.
- **`semantic-recall-mcp`** *(future)* — local embeddings index for "what did I
  write about X" recall. Tension with offline mode if it needs a hosted model;
  prefer a local embedder.

### Capture & ingest

- **`web-clip`** — fetch a URL → readable Markdown → `public/inbox/`
  (complements `okm capture`).
- **`media-transcribe`** — thin wrapper exposing the existing
  yt-dlp + WhisperX pipeline (`okm pod` / `okm distill`, `venv/`) as a
  callable tool/MCP.
- **`calendar-email-digest`** *(integration)* — pull the day's calendar events
  and flagged emails into the daily note. Privacy note: this is personal data —
  it lands in `private/` by default.

### Organization & maintenance

- **`para-tagger`** — suggest a PARA folder + tags for a note.
- **`inbox-dedupe`** — flag near-duplicate captures for inbox hygiene.
- **`digest`** — daily/weekly rollups (complements
  [`scripts/todo-summary.sh` / `scripts/weekly-tasks.sh`](../scripts/README.md)).

### Safety

- **`publish-guard`** — pre-publish linter that scans a note for secrets/PII
  before it leaves `private/`. Aligns with the v3 push-safety work
  (destination-aware notes, server-side vault guard) in
  [`docs/roadmap.md`](../docs/roadmap.md).

---

## Not here

Keep the scope honest — these intentionally live elsewhere:

- One-liner conveniences like `link` / `backlinks` / `stats` — see
  [README → Out of scope](../README.md#out-of-scope) (`rg` one-liners, not tools).
- Cron scanners and image compression — [`scripts/`](../scripts/README.md).
- AI skills (prompts/playbooks, not executables) — [`docs/skills/`](../docs/skills/README.md).

## See also

- [`README.md`](../README.md) — framework overview, rules, architecture
- [`bin/okm`](../bin/okm) — the vault CLI most tools should build on
- [`docs/SECURITY.md`](../docs/SECURITY.md) — privacy model these tools must honor
