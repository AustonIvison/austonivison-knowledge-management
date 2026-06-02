# Portable Vault Specification (PVS) v1.0

Every note readable with `cat`/`grep`/any CommonMark renderer without Obsidian.

## §0. Artifact tiers

| Tier | Type | Examples | Portable? |
|---|---|---|---|
| **1 – Core** | Plain markdown + YAML frontmatter | `.md`, attachments | ✅ |
| **2 – Derived** | Obsidian-aware, reconstructable | `.canvas`, `.base`, `.excalidraw.md` | ⚠️ w/ fallback |
| **3 – Opaque** | App/plugin state | `.obsidian/`, live query output | ❌ |

Rule 0: Tier-3 never sole record. Tier-2 must have Tier-1 fallback. Tier-1 is source of truth.

## §1. Link format

**MUST** use `[Display](relative/path.md)` — no `[[wikilinks]]`. Relative paths only. Heading anchors OK.

## §2. YAML frontmatter

```yaml
---
title: string
date: YYYY-MM-DD
modified: YYYY-MM-DD
tags: [flat, list]       # no nested taxonomies
aliases: [list]
status: draft|active|archived
type: note|moc|log|ref|project
source: url-or-citation
---
```

Plugin keys allowed only if valid YAML strings + documented in `VAULT_SCHEMA.md`.

## §3. Query blocks

Every query block must include a static snapshot:

````markdown
```dataview
TABLE date, status FROM #project WHERE status = "active"
```
<!-- Static snapshot updated: 2026-05-01 -->
| Title | Date | Status |
````

## §4. Ejectability properties

| Property | Requirement |
|---|---|
| **Completeness** | Bundle: all notes, attachments, config, static fallbacks |
| **Self-hostability** | Fresh machine opens vault in neovim via `neovim/install.sh` |
| **Continuity** | Every Obsidian workflow has named fallback; degradation documented |
| **Reversibility** | Notes move Obsidian ↔ neovim without repair |
| **Link integrity (U1)** | Every relative link resolves — `scripts/link-integrity.sh` must exit 0 |
| **MVR compatibility (U2)** | Any app satisfying the MVR contract can open the vault |
| **Threat model (U3)** | `VAULT_SCHEMA.md` documents each dependency + mitigation |
| **Ejection runbook (U4)** | `EJECT.md`: neovim / any editor / read-only options + "What you will lose" |
| **Observability (U5)** | `scripts/ejectability-check.py` reports portability debt continuously |

**MVR contract** (Minimum Viable Reader):

| Capability | Level |
|---|---|
| Render CommonMark; parse YAML 1.1; follow relative links; render code blocks + tables; list files | MUST |
| Full-text search; resolve backlinks | SHOULD |

**Threat model scenarios:**

| Threat | Mitigation |
|---|---|
| App death (Obsidian shuts down) | All notes pass MVR; neovim distribution present |
| Plugin death (Dataview/Tasks/Excalidraw abandoned) | Static snapshots; SVG exports alongside `.excalidraw.md` |
| Format death (`.canvas`/`.base` schema change) | Companion `.md` for every Tier-2 artifact |

## Required vault files

```
VAULT_INDEX.md       — editor-agnostic entry point
VAULT_SCHEMA.md      — frontmatter allowlist, folder rules, threat model
VAULT_MANIFEST.json  — machine-readable spec version, workflow continuity map
EJECT.md             — ejection runbook (3 options + degraded features list)
neovim/              — pinned plugins, config, setup guide
Templates/plain/     — Obsidian template parity in plain text
scripts/             — smoke-test.sh, link-integrity.sh, snapshot.py, ejectability-check.py
```

## Compliance checklist

- Every Tier-1 note readable as plain Markdown
- Every Tier-2 artifact has a Tier-1 fallback
- No Tier-3 artifact is sole source of structure or knowledge
- Bundle validated: `scripts/smoke-test.sh && scripts/link-integrity.sh` exit 0
- neovim distribution reproducible on a fresh machine
- Every workflow has a declared fallback or is marked degraded
- Notes move Obsidian ↔ neovim without repair
- Portability debt visible via `ejectability-check.py`

**Minimum neovim stack:** `obsidian.nvim` + `markdown-oxide` (LSP backlinks) + Telescope + snippet support.

**Implementation status:** Tier-1 plain markdown and inline-array YAML are compliant now. v3 work: migrate `[[wikilinks]]`, `okm audit` PVS rules, hierarchical tag decision, query snapshot infra.

**Open questions:** Wikilink migration strategy (one-shot script vs `okm audit`-guided) · `#inline-tags` Tier-1 or Tier-2? · `VAULT_SCHEMA.md` versioning · Per-note PVS opt-out (`pvs: ignore`)?
