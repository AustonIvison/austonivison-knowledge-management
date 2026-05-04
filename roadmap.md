# Roadmap

> Companion to [README.md](README.md). Plan-of-record for releases. v0 shipped; v1 in design; v2 planned.

Audit trail (six review passes, B/F/N findings, ship-plan clusters) lives in `git log` and the v0 commit history. This file tracks **what's next**, not what's done — past releases get a brief recap, not a full postmortem.

## Release timeline

| Version | Status | Theme |
|---|---|---|
| **v0** | ✅ shipped | Ship-green core: vault CLI, privacy boundary, hardened against adversarial input |
| **v1** | 🟡 in design | Fork-safety architecture, edge-case bug cleanup, tagging gaps |
| **v2** | 🔵 planned | Feature wave: media ingest (yt/pod/distill), macOS, encryption, performance |
| **v3** | 🔵 planned | Portable-first Obsidian vault — vim/CommonMark compliance, frontmatter schema, Tier taxonomy |

---

## v0 — shipped

Tagged after six review passes (~30 bugs surfaced and fixed, B/F/N-series) and a fuzz gate. Below is what shipped, grouped by cluster.

| Cluster | What changed |
|---|---|
| **Tagging hardening** | `okm tag/untag/tagged` rewrite — boundary regex (no partial matches), regex-injection block, hierarchical tags via awk (no sed-delimiter conflicts), frontmatter-less file handling, character validation, body-`---` parsing, flag-injection-safe dedup |
| **Privacy + sharing safety** | Vault `.gitignore` covers secrets; read-side commands skip `private-*/`; fork-safety docs in README + `setup-km.sh`; new `okm audit` scanner (PARA content, secret patterns, sensitive filenames) as pre-share gate |
| **Path safety** | `okm open` refuses paths outside the vault; `okm sync` refuses symlinks pointing outside; `resolve_note` vault-boundary check; `list_notes` excludes `.git/` |
| **Input validation** | YAML quote/backslash escaping; slug fail-closed on empty/short/long titles, newline-in-title collapse; Spotify ID validation; `-t` flag values run through `validate_tag` |
| **Format Specification** | All four template producers (`okm today/new/spot track/spot episode`) render via placeholder substitution from a single source-of-truth |
| **WSL2 disclosure** | README documents Windows-side writes; font install gated behind a flag |
| **Fuzz gate** | Bats property-test harness over `bin/okm` (Unicode/quotes/slashes/newlines/empty/long inputs to every subcommand) — final v0 gate |
| **Test + CI hygiene** | `direnv.bats` updated for shipped behavior; `gitignore.bats` matches dead-rule removal; `tests/run_all.sh` quiet on locale warnings; CI green on `main` |
| **Skills (editors/templates)** | Public/private PARA banners (Neovim winbar / Vim statusline); typed templates with required `## Sources Cited` / `## Actionable Insights` / `## Follow-ups`; `seed-demo.sh` dataset; auto-loading project config via direnv; high-fidelity transcripts spec; insight-oriented distill prompt |

**v0 strengths to preserve** (don't regress in v1/v2):

- 280+ BATS tests, fast, isolated via `FAKE_VAULT_DIR` and fake `$HOME`
- `scripts/lib/scan.sh` real shared library (not duplicated across `todo-summary.sh` / `weekly-tasks.sh`)
- Idempotent `setup-km.sh`, `okm new/today/spot`
- `verify-km.sh` exit-code discipline (FAIL blocks, WARN doesn't)
- `_skills/`, `disclaimer.md`, `private-*` privacy boundary
- Minimal correct CI

---

## v1 — in design

Cleanup, tagging gaps, edge-case bugs, and the fork-safety architecture decision.

| Item | Notes |
|---|---|
| **Fork-safety architecture** | Two competing topologies under evaluation. See [Fork-safety architecture](#fork-safety-architecture). |
| Block-style YAML read support | v0 hard-fails block-style tags (B3); v1 adds tolerant read |
| `okm sync` confirms uncommon file extensions | Friction against accidental commits of `.env`, binaries, etc. |
| `okm private <subcmd>` namespace | Richer than v0's read-side exclusion |
| `okm audit --json` + pre-commit hook integration | Machine-readable output, optional commit-time gate |
| `okm rename-tag <old> <new>` | Tagging gap |
| `-t` flag on `okm today` | Symmetry with `okm new/capture` |
| `okm tags --json` | Tagging gap |
| `okm spot` metadata fetch | Use `spotdl meta` or `yt-dlp` |
| `okm spot` URL escape in markdown link | `[Listen on Spotify](${url})` hardening for `)` / backticks (N9) |
| Offline Mode docs — mark `okm spot` networked | F2 |
| `KM_TRACK_NOTES` default unified to `true` everywhere | F6 |
| Decouple cron tests from README strings | F7 — test fragility |
| README dual-mode architecture diagram | Project=vault when same name (N6) |
| `okm version` / `--version` flag | Bug-report essential once forks exist (N7) |
| `verify-km.sh` reports direnv / `.envrc` state | Health-check gap (N8) |
| `has_frontmatter` horizontal-rule false positive | N30 — silent no-op on tag-write to notes starting with `---` |
| `write_tags_line` preserves file permissions | N31 — `mktemp`+`mv` currently clobbers 644 → 600 |
| macOS support | Homebrew install paths in `setup-km.sh`; refactor `find … -exec stat …` macOS branch in `pick_file` / `recent_notes` |
| `okm crypt init` | git-crypt initialisation as a first-class subcommand |
| **Polish** | Setup log rotation (keep-last-N); `okm sync -m "msg"` flag form; `LC_ALL=C` in test runner; `verify-km.sh` banner-vs-exit-code note in README |

---

## v2 — planned

Feature wave. Not started.

| Item | Notes |
|---|---|
| `okm yt` | YouTube transcript + metadata → note |
| `okm pod` | Local audio → whisperX → note |
| `okm distill` | AI summary (Claude + Ollama backends) |
| `okm online` / `okm offline` | Network-state toggle |
| HuggingFace token for pyannote | Speaker diarization |
| Private PARA mirror folder | |
| fzf-based tag picker | |
| `#inline-tags` body scanning | Obsidian-style. **Revisit under v3's Portable Vault Specification (PVS)** — depends on whether inline tags count as Tier-1 portable or Tier-2 Obsidian-flavored. |
| Tag aliasing | Different tags meaning the same thing (orthogonal to frontmatter `aliases:` field). |
| ~~Hierarchical tags first-class~~ | **Superseded by v3 PVS** (Portable Vault Specification). PVS §2 mandates flat tag lists ("no nested taxonomies"), so the v2 plan to promote `source/spotify`-style hierarchies is dropped pending the PVS decision. Hierarchical tags continue to work via convention until v3 lands. |
| **Rust mirror** | Slow Bash/Python utilities (fuzz harness, `okm audit` scanner, large TODO scans) ported once their patterns stabilize. See [Performance Policy](#performance-policy). |

---

## v3 — planned

Portable-first Obsidian vault. Codify rules so every note is fully readable and navigable with `cat`, `grep`, and any CommonMark renderer — vim, neovim, GitHub, etc. — without depending on Obsidian-specific features.

| Item | Notes |
|---|---|
| **Portable Vault Specification (PVS) v1.0** | Adopt the spec as project policy. See [Portable Vault Specification](#portable-vault-specification-pvs-v10). |
| Standard-markdown links (no `[[wikilinks]]`) | Rule: `[Display](relative/path.md)` only. Migrate existing wikilink-style embeds in templates and `seed-demo.sh` (e.g. `![[demo-screenshot.png]]` → `![screenshot](attachments/demo-screenshot.png)`). Update obsidian.nvim config to disable wikilink generation. |
| Frontmatter schema + `VAULT_SCHEMA.md` | Permitted-key allowlist (`title`, `date`, `modified`, `tags`, `aliases`, `status`, `type`, `source`); plugin-injected keys must be documented. Extend `okm audit` to flag undocumented keys. |
| `okm audit` PVS rules | New checks: wikilink usage, undocumented frontmatter keys, query blocks without static snapshots, Tier-2 artifacts without Tier-1 fallback. |
| Tier-2 artifact policy | `.canvas`, `.base`, `.excalidraw.md` need Tier-1 export or a fallback note documenting their content. |
| Query block static snapshots | Dataview/Tasks/Bases queries paired with auto-updated static tables; script regenerates snapshots on a defined schedule. |
| Decide on `#inline-tags` | Tier-1 portable or Tier-2 Obsidian-flavored? Resolves the v2 deferral. |
| Decide on hierarchical tags | PVS §2 says flat-only; this overrides the v2 plan to promote hierarchies to first-class. Confirm or carve a documented exception. |

**Crosswalk to other versions:**

- v0 templates already comply with PVS Tier-1 for plain markdown + inline-array YAML tags.
- v1 "block-style YAML read support" is compatible with PVS §2 (block-style is valid YAML 1.1) — v3 layers schema enforcement on top.
- v2 "Hierarchical tags first-class" is **superseded** by PVS §2's flat-tag rule.
- v2 "Tag aliasing" is **orthogonal** — it's about tag-name equivalence, not the YAML `aliases:` field.

---

## Fork-safety architecture

Post-v0 (v1) work. Replaces the doc-only "Fork safety" item shipped in v0 with a structurally enforced separation between the public OSS app code and the user's private notes/data.

**Problem this solves.** v0's fork-safety story is a README paragraph and a `GIT_REMOTE` arg to `setup-km.sh` that just runs `git remote add origin <url>` + `git push`. It assumes (a) the user already manually forked and renamed the repo on GitHub, and (b) the user correctly reset `origin` before the first `okm sync`. Both are easy to skip or misorder. The risk: a single `okm sync` against an `origin` that still points at the public OSS repo publishes private notes to the upstream project. The user's stated goal is *crystal-clear* separation — they want to pull/push features safely while being structurally unable to leak private content to the public repo.

**Design goal.** Make accidental pushes to upstream *impossible*, not just discouraged. Convention and naming aren't enough; the topology and tooling have to fail closed.

Two architectures are under evaluation. They are not the same — Approach B is structurally stronger because the personal data is in a *different git history entirely*, but it requires a larger restructuring of the project (today the vault directories `daily/`, `inbox/`, `archive/`, `attachments/`, `private-*` live alongside `bin/`, `scripts/`, `tests/` in the same repo). Pick one before building.

### Approach A — single repo, asymmetric remotes (`okm port`)

Lighter-touch automation over the current single-repo design. Keeps the vault and tool co-located and uses two remotes with asymmetric push permissions.

**Topology.**

- `origin` → `git@github.com:{handle}/{handle}-knowledge-management.git` (new, private, push target — this is where `okm sync` goes)
- `upstream` → public OSS repo (fetch-only)
- Pulling new OSS features: `git fetch upstream && git merge upstream/main` — deliberate, two commands, never automatic
- `okm sync` already does `git push` with no remote arg (`bin/okm:639`), which follows the branch's tracking remote (`origin/main`), so sync stays safe by construction once the topology is set

**Structural guards.**

1. **Disabled upstream push URL.** `git remote set-url --push upstream DISABLED`. A `git push upstream` then fails with an unparseable URL — not a confirmation prompt, a hard failure. No human-in-the-loop step that can be clicked through.
2. **Pre-push hook with upstream blocklist.** Installed into `.git/hooks/pre-push`. Refuses any push whose remote URL matches a configurable blocklist (defaults: the upstream OSS repo path). Override requires explicit env: `KM_ALLOW_UPSTREAM_PUSH=1`. The override is loud — surfaces in shell history and `verify-km.sh`.
3. **`okm sync` self-check.** Before pushing, refuses if `origin`'s URL looks like the upstream OSS repo (regex match against the blocklist). Currently `okm sync` silently prints "skipped pull/push" when no upstream is configured — that's also tightened: missing `origin` becomes a clear error, not a quiet no-op.

**Command surface.**

```
okm port <github-handle> [--public] [--no-push]
```

Flow:
1. Preconditions: `gh` CLI installed and `gh auth status` OK; current repo is a clone with `origin` pointing at the upstream OSS; working tree clean; `okm audit` passes (pre-share gate).
2. `gh repo create {handle}-knowledge-management --private --clone=false` (or `--public` if `--public` flag given; default is private).
3. `git remote rename origin upstream` (the existing `origin` was the public OSS — relabel it for what it actually is).
4. `git remote set-url --push upstream DISABLED`.
5. `git remote add origin git@github.com:{handle}/{handle}-knowledge-management.git`.
6. Install `.git/hooks/pre-push` with the blocklist guard.
7. `git push -u origin main` (skipped if `--no-push`).
8. Print a status block showing the new topology and what each remote is for.

**Tradeoffs.**

- *Pro:* small architectural delta from today — no restructuring, no submodules, no path reconfiguration. Single command sets it up.
- *Pro:* pulling OSS updates is one merge.
- *Con:* the personal vault still lives in the same git history as the tool. The guards make leakage hard, but not structurally impossible — a determined misuse of `--no-verify` plus the override env could still push private content to upstream.
- *Con:* gives up the GitHub "Sync fork" button and the easy fork-PR flow. Contributing back upstream becomes a rare ceremony — push the contribution branch to a third throwaway fork and PR from there.

### Approach B — two-repo split (private parent, public app)

Stronger separation: the public OSS app is one repo, the user's private notes are a different repo. There is *no shared git history* between them. Two layout options:

**B1 — Private parent with public submodule (recommended within Approach B).** The user's private repo *contains* the public app as a git submodule. Personal data is only ever tracked by the private repo.

```text
my-private-knowledge/      # ← private GitHub repo
├── app/                   # ← git submodule pointing to public project
│   ├── bin/
│   ├── scripts/
│   ├── tests/
│   └── config/
└── vault/                 # ← all personal notes (daily/, inbox/, archive/, etc.)
```

Setup:

```bash
git clone git@github.com:{handle}/my-private-knowledge.git
cd my-private-knowledge
git submodule add https://github.com/{upstream}/knowledge-management.git app
git commit -am "Add app submodule and vault structure"
git push origin main
```

Pulling app updates:

```bash
cd my-private-knowledge/app
git pull origin main
cd ..
git commit -am "Update app submodule"
git push
```

**B2 — Side-by-side clones (simplest).** No submodules. The public repo is cloned for the app; a separate private repo holds the vault. The app is configured (via `OBSIDIAN_VAULT`, which `bin/okm:5-16` already honors) to read data from an external path.

```text
~/projects/
├── knowledge-management/   # public OSS clone (code only)
└── my-private-knowledge/   # private repo (vault, configs)
    └── vault/
```

Configuration:

```bash
export OBSIDIAN_VAULT="$HOME/projects/my-private-knowledge/vault"
```

**Tradeoffs.**

- *Pro:* personal data is **structurally separate** — different repo, different git history. Leaking private notes to the public project is not a foot-gun any more, it's a category error you can't make.
- *Pro:* clean fork/PR ergonomics on the public repo — it's just code, you can fork it normally and open PRs.
- *Pro:* aligns with the existing `OBSIDIAN_VAULT` environment override (already supported), so B2 is a near-zero-code change to the tool.
- *Con:* requires removing vault directories (`daily/`, `inbox/`, `archive/`, `attachments/`, `private-*`) from the public OSS distribution — non-trivial restructuring, plus careful migration for existing users who cloned the current single-repo layout.
- *Con (B1 only):* submodule UX is famously rough — users need to remember `git submodule update --init --recursive` and the two-step update flow.
- *Con:* `okm sync` semantics change: it has to know whether it's syncing the vault repo (private) or the app repo (public, contributor's branch). The current single-`git push` shape no longer fits.
- *Con:* setup is more manual — the `setup-km.sh` flow has to either bootstrap the private repo or detect/instruct.

### Defense-in-depth backstops (apply to either approach)

These add a layer of protection regardless of the chosen topology. v0 already ships the `okm audit` scanner and a `.gitignore` covering common secret patterns; the items below are additive.

**Hardened `.gitignore` patterns for the public repo.** Beyond what v0 ships, the public OSS distribution should ignore the vault directories themselves once Approach B lands (so a wayward symlink or accidental copy can't sneak personal data into the public repo):

```gitignore
# Personal data directories — never tracked in the public app repo
vault/
data/
notes/
personal/

# Live configs — only .example versions are committed
config/config.yaml
config/settings.yaml
*.local.*
*.env
.env*

# Sensitive file types
*.pem
*.key
*.db
*.sqlite
*.sqlite3
```

**Gitleaks pre-commit hook.** Catches staged secrets locally before they reach any remote. Add `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
        args: ["protect", "--staged"]
```

Install once after cloning: `pip install pre-commit && pre-commit install`. Ties into v0's `okm audit` — gitleaks catches commit-time secrets, `okm audit` catches PARA content and broader patterns.

**GitHub server-side push protection.** Enable secret scanning + push protection on the upstream repo (Settings → Code security → Secret scanning). Server-side blocking catches secrets even when local hooks are bypassed via `--no-verify`. Document this in `CONTRIBUTING.md` as a maintainer responsibility.

### Contributing features back (applies to either approach)

When the user wants to open a PR to the public project:

```bash
# Approach A: cd into the single repo
# Approach B1: cd my-private-knowledge/app
# Approach B2: cd ~/projects/knowledge-management

# Add the user's personal fork as a remote
git remote add myfork git@github.com:{handle}/knowledge-management.git

# Clean feature branch — no personal data lives in this scope
git checkout -b feature/cool-tagging-system
git push myfork feature/cool-tagging-system

# Open PR: myfork/feature/cool-tagging-system → upstream/main
```

Under Approach B, the working tree literally cannot contain personal data — there's nothing to leak. Under Approach A, this still relies on the working tree being clean of vault diffs at PR time, which the pre-push hook and `okm audit` enforce.

### Decision criteria

Pick **Approach A** if: the priority is the smallest possible change to v0's architecture, the user is comfortable with hook-based guards, and the contribution flow is rare enough that the throwaway-fork ceremony is acceptable.

Pick **Approach B** (specifically B2 unless submodules are wanted) if: the priority is structural impossibility of leakage over ergonomic simplicity, and a one-time restructuring (extracting vault dirs out of the public repo, documenting `OBSIDIAN_VAULT`-as-required) is acceptable.

A pragmatic third option: **ship Approach A first** as `okm port` (small lift, immediate safety improvement), then evaluate B as a longer-term restructuring once real usage exposes which tradeoff matters more.

### Open questions to resolve before building

- **Which approach (A, B1, B2, or A→B migration path)?** Single biggest decision — everything below depends on it.
- **Private repo by default?** Recommendation: yes. `--public` flag for users who want a public mirror.
- **`gh` CLI as a new dependency?** Not currently installed; not in `setup-km.sh`'s install list. Recommendation: add to `setup-km.sh`'s install list — one-time cost, removes a footgun on first port.
- **Existing users who already manually forked?** `okm port --adopt` mode that rewires remotes + installs the hook on an existing private repo, skipping the create step. (Approach A only — under Approach B, existing users need a migration script that splits their current single repo into two.)
- **`verify-km.sh` integration.** Add a check that confirms the post-port topology is intact: under A, that `origin` is private + `upstream` push URL is `DISABLED` + pre-push hook is installed. Under B, that `OBSIDIAN_VAULT` resolves outside the app repo.
- **README update.** A "Privacy & Personal Data" section in the public README that explains the chosen architecture and tells new users how to set it up safely on first clone.

### Test coverage to plan for

- Unit-style: BATS tests using a fake `gh` shim that records calls without hitting GitHub.
- Integration-style: full port flow against a local bare-repo "GitHub" via `git daemon` or a tmpdir bare repo; assert remotes, hook presence, push refusal on the public path, push success on the private path.
- Negative: `okm sync` against a deliberately-misconfigured `origin` (pointing at upstream OSS) must refuse.
- Approach B2: assert `okm` operates correctly when `$OBSIDIAN_VAULT` resolves to a path outside the app repo, including a vault that is itself a separate git repo with its own remote.

---

## Portable Vault Specification (PVS) v1.0

Post-v2 (v3) work. Codifies "portable-first" as a project rule.

**Target compatibility:** vim, neovim (`obsidian.nvim` / `markdown-oxide` / plain), any CommonMark-aware editor.

**Guiding principle:** Every note must be fully readable and navigable with `cat`, `grep`, and a CommonMark renderer. If it isn't, it doesn't belong in the vault core.

### §0. Taxonomy of Vault Artifacts

Before rules, name the problem. Vault artifacts fall into three tiers:

| Tier | Type | Examples | Portable? |
|------|------|----------|-----------|
| **1 – Core** | Plain markdown + YAML frontmatter | `.md` notes, attachments | ✅ Yes |
| **2 – Derived** | Obsidian-aware but reconstructable | `.canvas`, `.base`, `.excalidraw.md` | ⚠️ Conditional |
| **3 – Opaque** | App/plugin state, computed outputs | `.obsidian/`, Dataview results, sync state | ❌ No |

**Rule 0:** Tier-3 artifacts must never be the sole record of intent, structure, or content. Tier-2 artifacts must have a Tier-1 fallback or export. Tier-1 is the source of truth.

### §1. Link Format

**Problem:** `[[wikilinks]]` are Obsidian-specific. They are not rendered by vim, neovim's built-in LSP, or most CommonMark parsers without a plugin.

**Rules:**

- **MUST** use standard Markdown links: `[Display Text](relative/path/to/note.md)`
- **MUST** use relative paths from the current file, not shortest-path or absolute vault paths
- **MUST NOT** use `[[wikilinks]]` in any Tier-1 note (disable `Settings > Files & Links > Use Wikilinks`)
- **MUST NOT** use bare `[[links]]` without display text fallback
- Heading anchors are permitted: `[Section](note.md#heading-slug)` — these survive in any CommonMark renderer

**Vim/neovim compliance:** `markdown-oxide` resolves relative `.md` links natively via LSP; `obsidian.nvim` does the same. Plain `gf` in vim follows relative file paths.

### §2. YAML Frontmatter

**Problem:** Plugin-injected properties (Dataview, Tasks, Templater, Readwise) accumulate opaque keys that have no meaning outside Obsidian. Frontmatter becomes noise.

**Rules:**

- **MUST** restrict frontmatter to a defined schema (see §2.1)
- **MUST NOT** allow plugins to auto-inject undocumented keys into frontmatter
- **MUST** use YAML 1.1-compliant syntax (no Obsidian Properties UI-only types unless they serialize to valid YAML strings)
- **SHOULD** keep keys lowercase and hyphen-separated for grep-ability

#### §2.1 Permitted Frontmatter Schema

```yaml
---
title: string           # Human-readable title (required)
date: YYYY-MM-DD        # Creation or reference date (required for dated notes)
modified: YYYY-MM-DD    # Last meaningful edit (optional, can be script-managed)
tags: [list, of, tags]  # Flat list, no nested taxonomies
aliases: [list]         # Alternative names for this note
status: draft|active|archived  # Note lifecycle
type: note|moc|log|ref|project # Note role
source: url-or-citation # Origin of external content
---
```

Any plugin that requires additional frontmatter keys (e.g., Readwise's `doc_id`, Tasks's `scheduled`) **MUST** document those keys in a `VAULT_SCHEMA.md` file at the vault root, and those keys **MUST** be parseable as plain strings by any YAML parser.

### §3. Plugin-Managed Content

**Problem:** Dataview queries, Tasks queries, and Bases queries produce results computed live and never persisted. Moving to vim means queries render as raw code fences.

#### §3.1 Query Blocks

**Rules:**

- **MUST NOT** use inline Dataview/Tasks/Bases query blocks as the *sole* navigation surface for a topic
- **SHOULD** accompany every query block with a human-readable static summary updated on a defined schedule (daily/weekly via script)
- **MUST** keep the query itself as a plain code fence with language identifier so vim renders it as readable text:

  ````markdown
  ```dataview
  TABLE date, status FROM #project WHERE status = "active"
  ```

  <!-- Static snapshot updated: 2026-05-01 -->

  | Title | Date       | Status |
  |-------|------------|--------|
  | Foo   | 2026-04-10 | active |
  ````

*Spec sections beyond §3.1 are TBD — fill in §3.2+, §4 (attachments), §5 (folder structure), §6 (encoding/EOL) as the spec evolves.*

### Implementation status (against current repo)

What v0/v1/v2 already comply with:

- **§0 Tier-1 source of truth.** v0's vault is plain markdown + YAML frontmatter; no Tier-3 artifacts are tracked as authoritative.
- **§2 inline-array YAML.** N1 in v0 converted all four templates to inline-array tags (`tags: [source/youtube]`); block-style triggers a hard fail (B3) until v1's tolerant read lands.
- **§2 schema discipline (partial).** Existing templates already use a near-PVS schema (`title`, `date`, `tags`); v3 adds the formal allowlist + `VAULT_SCHEMA.md`.

What needs work for v3:

- **§1 wikilinks.** Templates and `seed-demo.sh` use `[[demo-screenshot.png]]`-style embeds; README:117 shows `![[demo-screenshot.png]]`. All need migration to standard-markdown form. `obsidian.nvim` config should be flipped to generate standard links.
- **§2 plugin discipline.** No mechanism today prevents Obsidian plugins from injecting undocumented keys. v3 needs an `okm audit` rule that flags any frontmatter key not in `VAULT_SCHEMA.md`'s allowlist.
- **§2 hierarchical tag rule.** Current `okm` accepts hierarchical tags (`source/podcast`); the v2 promotion plan is now superseded. Decide whether existing hierarchical tags get migrated to flat (`source-podcast`) or grandfathered.
- **§3 query-block snapshots.** Not present today; if Dataview/Tasks usage starts, v3 introduces the snapshot-script pattern from the start.

### Open questions

- **Migration cost vs. backfill scope.** Auto-migration of existing wikilinks via a one-shot script, or hand-migration with `okm audit` flagging the violations?
- **Inline `#tag` syntax.** Tier-1 (grep-able, plain text) or Tier-2 (Obsidian convention)? Defer-to-v3 v2 item depends on this.
- **Schema versioning.** `VAULT_SCHEMA.md` becomes a contract. Bump rule when keys are added/removed?
- **Per-note opt-out.** Some notes (e.g. third-party imports) may need to keep non-conforming frontmatter. Allow a `pvs: ignore` escape hatch, or hard-rule no-exceptions?

---

## Performance Policy

Slow scripting features (Bash or Python) — fuzz harnesses, audit scanners, large TODO scans, batch transcripts — should be mirrored in a lower-level language (Rust preferred) once their patterns stabilize, so the day-to-day CLI stays compact while heavy ops scale.

**Mirror when:** the script takes >1s on a typical vault, runs in a hot loop (every commit / every CI run), or is iteration-bound (e.g. property-testing with Python `hypothesis`).

**Don't mirror:** one-off setup or maintenance scripts, I/O-bound work, or anything still under active design — mirror only after patterns are stable.

The v2 "Rust mirror" row tracks the mirror work itself; v0 and v1 keep everything in Bash/Python for iteration speed.
