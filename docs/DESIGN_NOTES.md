# Design Notes

Index of `N` (notes) and `B` (bugs/edge cases) codes referenced in `bin/okm` comments.
Each entry records the decision and why it exists, so the code comments stay terse.

## N codes — design decisions

| Code | Decision |
|------|----------|
| N6  | README dual-mode diagram (vault-inside vs vault-outside repo) — deferred to v1 |
| N7  | Log rotation, `sync -m`, `okm version`, decouple cron tests — deferred to v1 |
| N8  | `verify-km.sh` direnv check — deferred to v1 |
| N9  | `okm spot` metadata fetch + URL escape — deferred to v1 |
| N11 | `okm tag` on a file with no frontmatter prepends `---\ntags: []\n---` instead of refusing |
| N13 | YAML double-quoted scalars require backslash-first escaping: `\` → `\\`, then `"` → `\"` |
| N14 | `slugify` fails closed on slugs shorter than 2 chars — prevents creating `-.md` or similar |
| N15 | `okm sync` refuses if any vault symlink resolves outside the vault (leak-prevention) |
| N16 | Spotify IDs are exactly 22 base62 characters — reject anything that doesn't match |
| N17 | `okm tagged` uses exact-match via `grep -xF`, not regex — prevents `tagged source` matching `source/spotify` |
| N18 | Slugs are capped at 200 characters with trailing-hyphen trim |
| N19 | `okm open` validates vault boundary with `realpath -m` (allows non-existent paths for new notes) |
| N20 | `slugify` collapses `\n\r\t` to spaces before slugifying multi-line titles |
| N21 | `first_frontmatter` and `get_tags_line` stop at the second `---`, preventing body `---...---` blocks from being parsed as frontmatter |
| N22 | `grep -qxF -- "$tag"` — `--` prevents tags starting with `-` from being interpreted as flags |
| N23 | `validate_tag` whitelist: `[A-Za-z0-9_./+-]` only — rejects chars that break YAML or shell parsing |
| N26 | `yaml_escape_dq` escapes backslash before double-quote so the two passes don't interfere |
| N27 | `-t` flag validates every tag in the comma-separated list before accepting any of them |
| N28 | `resolve_note` validates vault boundary for existing files (complements N19 for open) |
| N30 | A lone leading `---` is a Markdown horizontal rule, not a frontmatter block — reject rather than silently prepend |
| N31 | `write_tags_line` preserves original file permissions via `stat -c '%a'` + `chmod` after atomic replace |

## B codes — bug/edge-case identifiers

| Code | Edge case |
|------|-----------|
| B2  | `okm tagged source` must NOT match `source/spotify` — exact tag comparison, not prefix/substring |
| B3  | Block-style YAML tags (`tags:\n  - foo`) are read-supported but write operations refuse them (v0); write support is a v1 item |
| B4  | Invalid characters in `-t` flag values (e.g. commas inside a tag, leading `-`) caught by `validate_tag` |
