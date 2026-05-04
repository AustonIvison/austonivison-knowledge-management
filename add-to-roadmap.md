
A# PVS Addendum v3: What Thymer's Article Actually Implies
*A close reading of https://thymer.com/ejectable — focusing on the
implications, not just the four named properties*

---

## What the Article Says vs. What It Implies

The article names four properties but contains several additional
structural claims embedded in its framing. Those implied claims are
actually the most useful for the PVS spec, because the four named
properties were already addressed in Addendum v1/v2. What's left is
what the article *assumes* without stating.

---

## Implied Property 1: Export Must Be Usable in Practice, Not Just Complete

> *"goes beyond the basic export some apps offer, which typically provides
> a partial data dump that's unusable in practice"*

The word **unusable** is doing a lot of work here. The article is not
just saying the export must be *complete* — it's saying completeness alone
is not sufficient. A complete dump can still be unusable.

**What makes a complete export unusable?**
- Files are present but links are broken (path references changed)
- Data is present but requires the original app to interpret it
- All notes exist but have no navigable entry point
- File names are GUIDs or hashes, not human-readable titles
- Attachments are present but de-associated from the notes that reference them

**Gap in the current spec:** The PVS spec constrains *what goes into* notes
but never defines a **link integrity guarantee** — the property that every
link in every note resolves to a real file in the bundle, verifiably, before
the bundle is handed off.

**New rule — U1: Link Integrity Guarantee**

The vault bundle MUST pass a link integrity check before it is considered
complete. This is a distinct check from the smoke test (§C5) — it is
*content-level* correctness, not *format-level* correctness.

```bash
# scripts/link-integrity.sh
# Verifies every markdown link in every .md file resolves to a real file

import re, os, sys
from pathlib import Path

vault = Path("vault/")
broken = []

for md_file in vault.rglob("*.md"):
    content = md_file.read_text()
    links = re.findall(r'$$.*?$$$$(.*?)$$', content)
    for link in links:
        # Strip anchors and query strings
        target = link.split('#').split('?')
        if target.startswith('http') or target == '':
            continue
        resolved = (md_file.parent / target).resolve()
        if not resolved.exists():
            broken.append(f"{md_file}: broken link → {link}")

if broken:
    for b in broken: print(b)
    sys.exit(1)
print(f"All links valid.")
```

This script MUST be run as part of every vault bundle creation (§C1).
A bundle with broken links fails the "usable in practice" standard even
if it is informationally complete.

---

## Implied Property 2: Alternative App Compatibility Is a Design Constraint, Not a Bonus

> *"Ideally the output is well-documented so alternative apps can also
> work on the same data."*

The word **ideally** makes this sound optional. But in the context of
the article's argument — that enshittification, bait-and-switch pricing,
and arbitrary account suspension are real risks — alternative app
compatibility is actually a *survivability* property. If the original
app disappears and no alternative can open your data, the export was
not useful.

**Gap in the current spec:** The PVS spec targets vim/neovim as the
portability target. But the spec never defines a **minimum viable reader
interface** — the smallest set of capabilities any app needs to claim
it can "work on" PVS-compliant vault data.

**New rule — U2: Minimum Viable Reader (MVR) Definition**

A PVS-compliant vault must be openable by any app that satisfies the
MVR contract:

| Capability | Requirement |
|---|---|
| Render CommonMark | MUST |
| Parse YAML 1.1 frontmatter | MUST |
| Follow relative `[text](path.md)` links | MUST |
| List files in a directory | MUST |
| Full-text search across files | SHOULD |
| Resolve backlinks (parse all files for references to current file) | SHOULD |
| Render fenced code blocks as text | MUST |
| Render standard markdown tables | MUST |

Any app that satisfies the MUST requirements can work on PVS vault data.
This is the bar to clear — not "works in Obsidian" or "works in neovim"
specifically, but "works in anything that passes the MVR."

The MVR definition also constrains the spec retroactively: any rule in
§1–9 that would prevent a MVR-compliant app from opening a note is a
spec violation. For example, using Obsidian-specific `[[wikilinks]]`
violates MVR because most MVR-compliant apps do not resolve them.

---

## Implied Property 3: Longevity Is the Actual Goal, Not Just Portability

> *"They ensure that what we create with our modern tools today remains
> accessible and functional far into the future."*

> *"just as future-proof as DOOM.EXE or NOTEPAD.EXE"*
> *(from the companion article https://thymer.com/local-first-ejectable)*

The article frames ejectability not as a migration convenience but as a
**preservation guarantee**. The threat model is not just "I want to switch
apps" — it is "the app might cease to exist, and my data must survive that."

**Gap in the current spec:** Addendum v1 introduced a longevity tier table
(E5), but it was framed as a format stability decision. It was not framed
as what the article actually intends: a **threat-model-driven constraint**.

The threat model has three distinct failure scenarios, each requiring a
different spec response:

| Threat | Scenario | Required mitigation |
|---|---|---|
| **App death** | Obsidian shuts down; no new versions | MVR (§U2): any compliant app opens the vault |
| **Plugin death** | Dataview, Tasks, or Excalidraw plugin abandoned | Static fallbacks (§3.1, §4, §5): snapshots carry meaning without the plugin |
| **Format death** | `.canvas` or `.base` schema changes incompatibly | Companion `.md` (§4, §6): the Tier-1 file carries the information |

**New rule — U3: Threat Model Documentation**

`VAULT_SCHEMA.md` MUST contain a threat model section listing every
Obsidian-specific dependency and its mitigation:

```markdown
## Threat Model

| Dependency | Failure scenario | Mitigation | Status |
|---|---|---|---|
| Obsidian app | App shuts down | All notes pass MVR (§U2); neovim/ distribution present | ✅ |
| Dataview plugin | Plugin abandoned | Static snapshot updated weekly; MOC covers same notes | ✅ |
| Excalidraw plugin | Plugin abandoned | SVG auto-export present alongside every .excalidraw.md | ✅ |
| Canvas format | Schema change | Companion .md exists for every .canvas | ✅ |
| Obsidian Sync | Service ends | git is canonical; sync is secondary | ✅ |
| Templater plugin | Plugin abandoned | plain/ equivalents in Templates/plain/ | ✅ |
```

Any dependency with no listed mitigation is a **portability debt** that
MUST be resolved before the vault is considered ejectable.

---

## Implied Property 4: The Ejection Process Must Not Require Expert Knowledge

> *"The ejection process should be straightforward. Just click a button
> or two, download some files; it should not be a 100-step process."*

Thymer is describing a SaaS app where the vendor builds the export button.
For Obsidian, there is no vendor export button — the *vault author* is
responsible for building the equivalent.

**Gap in the current spec:** The `neovim/README.md` (§C2) says "≤5 step
install instructions" but that only covers the neovim toolchain setup. There
is no defined **ejection runbook** — the procedure a person (including future-
you with no memory of these decisions) follows to extract a complete, usable
bundle from the vault.

**New rule — U4: Ejection Runbook**

The vault MUST contain a `EJECT.md` file at the vault root. It MUST be
executable by someone with no prior knowledge of the vault's configuration.
Required sections:

```markdown
# EJECT.md — Vault Ejection Runbook

## What this file is
This vault is designed to be ejectable. If you need to stop using Obsidian
and open this vault elsewhere, follow these steps.

## Option A: Open in neovim (full experience)
1. Install neovim ≥ 0.9
2. Run: `cd neovim/ && ./install.sh`
3. Open neovim from the vault root: `nvim .`
4. All plugins, keymaps, and templates are pre-configured.

## Option B: Open in any markdown editor (basic experience)
1. Open the vault folder in any editor (VS Code, Typora, Zed, etc.)
2. All notes are standard CommonMark + YAML frontmatter
3. All links are relative paths — they will resolve correctly
4. Start from: VAULT_INDEX.md

## Option C: Read-only access (emergency)
1. Every note is a plain .md file readable with any text editor
2. VAULT_INDEX.md is the entry point
3. Static snapshots of all live queries are embedded in each MOC note

## Verifying the bundle is complete
Run: `scripts/smoke-test.sh && scripts/link-integrity.sh`
Both must exit 0.

## What you will lose
Features that require Obsidian or the neovim stack and have no full equivalent:
- Live Dataview/Tasks query rendering (static snapshots available)
- Visual graph view (MOC hierarchy + VAULT_INDEX.md available)
[list any other degraded continuity items from VAULT_MANIFEST.json]
```

The final section — "What you will lose" — is critical. It is the honest
disclosure that Thymer's article implies with its "unusable in practice"
warning. A runbook that overpromises is worse than no runbook.

---

## The Property the Article Does Not Name But Should: Observability

There is one property implied by the entire framing of the Thymer article
that none of its four named properties capture explicitly:

> How do you know, *right now*, whether your vault is ejectable?

Thymer's framing assumes the app vendor ensures ejectability. For a
self-managed vault, the user is the vendor. That means the vault needs
**observability** — a way to continuously measure its own ejectability
health, not just at export time.

**New rule — U5: Ejectability Health Score**

The vault MUST include a `scripts/ejectability-check.py` that produces a
structured report:

A
# Portable Vault Specification and Ejectability Addendum

This document defines a portable-first specification for an Obsidian vault and extends it with ejectability properties inspired by Thymer's concept of ejectable apps.[1][2] The goal is to guarantee that a vault remains readable, navigable, and operational outside Obsidian, with vim and neovim as the minimum target environments.[3][1]

## Purpose

The core problem is that an Obsidian vault is not just a collection of plain Markdown files.[1] While note bodies may be stored as Markdown, significant value is also encoded in app configuration, plugin state, derived JSON artifacts, computed views, and sync metadata that do not naturally survive a move to another editor.[1][2] A portability specification therefore has to cover not only note syntax, but also links, metadata, derived artifacts, reconstruction rules, and operational safeguards.[1]

## Artifact tiers

The vault should be treated as a set of artifacts with different portability characteristics.[1]

| Tier | Type | Examples | Portability |
|------|------|----------|-------------|
| 1 | Core | `.md` notes, YAML frontmatter, attachments | High |
| 2 | Derived | `.canvas`, `.base`, `.excalidraw.md` | Conditional |
| 3 | Opaque | `.obsidian/`, plugin state, live query output, sync state | Low |

Tier-3 artifacts must never be the sole record of structure, meaning, or workflow intent.[1] Tier-2 artifacts are allowed only when they have a Tier-1 fallback that preserves the same informational content in plain Markdown or a standard export such as SVG.[1][2]

## Core portability rules

### Link format

Tier-1 notes must use standard Markdown links with relative paths, such as `[Note](../path/to/note.md)`, rather than Obsidian wikilinks.[4][5] This makes link following work in CommonMark-aware tools and enables basic traversal in vim or neovim without depending on Obsidian-specific parsing.[3][6]

### Frontmatter

Frontmatter should be constrained to a documented YAML schema so that notes remain understandable to general-purpose tools instead of only Obsidian plugins.[7][8] Plugin-specific keys are allowed only if they serialize as ordinary YAML values and are documented in a schema file at the vault root.[7]

### Query blocks

Dataview, Tasks, and similar query blocks may be stored in Markdown, but their rendered results are not portable because they are computed live and not persisted.[1] Every query-based dashboard therefore needs a static Markdown fallback, such as an embedded snapshot table or a companion manually maintained MOC note.[1][2]

### Canvas, Bases, and Excalidraw

`.canvas` and `.base` files are JSON-based derived views and must be treated as optional visualizations rather than primary records.[1] Each one needs a companion Markdown note that explains its purpose, lists the notes it references, and preserves the same navigational structure in text.[1] `.excalidraw.md` files should be treated as opaque drawing containers for portability purposes, with SVG or PNG exports serving as the portable representation.[9][10]

### Link graph and backlinks

Backlinks and graph relationships are one of the few Obsidian features that are genuinely derived from portable source data, because the references live inside the Markdown itself.[1] In neovim, tools such as `markdown-oxide` and `obsidian.nvim` can materialize much of that navigation layer through link completion, references, and note search.[3][11]

### Sync and configuration

Sync state is not portable knowledge; it is operational metadata owned by a sync backend.[1] The vault should designate one sync backend, treat git as the canonical history layer, and document any structural settings from `.obsidian/` in a human-readable schema so they can be recreated elsewhere.[1][2]

## Required vault files

A compliant vault should contain a small set of required documents that make the structure self-describing and reconstructable.[1][2]

```text
vault/
  VAULT_INDEX.md
  VAULT_SCHEMA.md
  VAULT_MANIFEST.json
  EJECT.md
  .gitignore
  neovim/
  Templates/plain/
  scripts/
```

These files serve distinct roles: `VAULT_INDEX.md` provides an editor-agnostic entry point, `VAULT_SCHEMA.md` documents the structure and dependency model, `VAULT_MANIFEST.json` makes that model machine-readable, and `EJECT.md` explains how to leave Obsidian without losing usability.[1][2]

## Ejectability properties

Thymer's ejectable-app model adds a stronger standard than basic portability by requiring not only that data be exportable, but that a user can leave, continue working, and return without losing the working system.[1][2] In this context, four named properties are essential: completeness, self-hostability, continuity, and reversibility.[1]

| Property | Meaning in this spec |
|----------|----------------------|
| Completeness | A vault bundle contains all notes, derived artifacts, required config, and static fallbacks.[1] |
| Self-hostability | A fresh machine can open the vault in neovim using the included toolchain and instructions.[1][2] |
| Continuity | Core workflows continue outside Obsidian, even if some are degraded through snapshots or text substitutes.[1] |
| Reversibility | Notes authored in neovim remain valid Obsidian vault members without repair work.[1][2] |

### Completeness

A portable vault bundle must be more than a raw data dump.[1] It should include all note files, attachments, relevant `.obsidian/` config, required snapshots, companion files, and neovim configuration so that the bundle is usable in practice rather than merely exhaustive.[1][2]

### Self-hostability

The `neovim/` directory should be treated as the equivalent of a self-hostable runtime.[1] It needs pinned plugin versions, vault-specific configuration, templates or snippets, keymaps, and a short setup guide so a fresh machine can recreate the working environment reliably.[3][11][1]

### Continuity

Every structural Obsidian workflow should have a named fallback outside Obsidian.[1][2] For example, graph exploration can degrade to explicit MOC navigation, and live Dataview tables can degrade to snapshot tables, but the loss must be documented rather than hidden.[1]

### Reversibility

A vault is not truly ejectable if notes can leave Obsidian but cannot return cleanly.[1][2] Relative Markdown links, a stable frontmatter schema, declared folder conventions, and template parity between Obsidian and neovim together create that bidirectional contract.[4][7][1]

## Additional implied properties

A close reading of Thymer's argument suggests several further requirements beyond the four named properties.[1][2]

### Usability of export

Thymer distinguishes between a complete export and one that is actually usable in practice.[1] That implies a link-integrity requirement: every Markdown link in the bundle must resolve, attachments must remain associated with notes, and the vault must expose at least one clear human entry point such as `VAULT_INDEX.md`.[1]

### Alternative-app compatibility

The article argues that exported data should be documented well enough for alternative apps to work on it.[1] That implies a minimum viable reader contract: any app that can render CommonMark, parse YAML frontmatter, follow relative Markdown links, show code fences, and list files should be able to read a compliant vault meaningfully.[1]

### Threat-model awareness

The deeper goal is preservation under failure, not just migration convenience.[1][2] The vault should therefore document failure scenarios such as Obsidian disappearing, a plugin being abandoned, or a JSON schema changing, along with the mitigation for each dependency.[1]

### Low-friction ejection

If leaving the app requires expert memory or a long undocumented process, the system is still practically locked in.[1] `EJECT.md` should therefore function as an explicit runbook covering neovim setup, basic editor access, read-only fallback access, validation commands, and the known degraded features after ejection.[1][2]

### Observability

An ejectable vault needs a way to measure whether it is still ejectable today, not only at export time.[1] A continuous validation script should report broken links, stale query snapshots, missing canvas companions, schema violations, and any workflow with no fallback so portability debt stays visible.[1]

## Operational files

### `VAULT_SCHEMA.md`

This file documents the human-facing rules of the vault: folder structure, allowed frontmatter fields, plugin inventory, ownership of special folders, sync backend, and the threat model for each Obsidian-specific dependency.[1][2]

### `VAULT_MANIFEST.json`

This file makes the vault machine-readable.[1] It should include the spec version, link format, attachment path, folder conventions, plugin metadata, snapshot policy, and a `workflow_continuity` section that records whether each important workflow is fully preserved, degraded, or missing outside Obsidian.[1]

### `EJECT.md`

This file is the ejection runbook.[1] It should tell a future reader how to open the vault in neovim, how to open it in a generic Markdown editor, what the read-only fallback path is, how to verify bundle integrity, and what features remain degraded after the move.[1][2]

## Validation requirements

A vault should not merely claim portability; it should prove it through repeatable checks.[1] At minimum, the scripts directory should contain a smoke test, a link-integrity check, a snapshot refresher, and an ejectability report that summarizes current compliance status.[1]

| Script | Purpose |
|--------|---------|
| `smoke-test.sh` | Rejects format violations such as wikilinks or missing companion files.[1] |
| `link-integrity.sh` | Verifies that every relative Markdown link resolves.[1] |
| `snapshot.py` | Refreshes static snapshots for query-driven views.[1] |
| `ejectability-check.py` | Produces a structured health report for the vault.[1] |

## Minimum neovim target

The minimum portability target is vim or neovim, but full continuity is most realistic in neovim with a small supporting stack.[3][11] `obsidian.nvim` helps with daily notes, note search, and link flows, while `markdown-oxide` supplies LSP-based backlinks, references, and completions over the vault directory.[3][11]

A practical minimum setup includes:

- `obsidian.nvim` for workspace-aware note operations.[3]
- `markdown-oxide` for backlink and reference resolution in neovim.[11]
- Telescope or an equivalent fuzzy finder for search across notes.[3]
- Snippet support that mirrors any Templater-generated note scaffolding in plain text form.[1]

## Compliance summary

A vault should be considered compliant only if it satisfies all of the following conditions.[1][2]

- Every Tier-1 note is readable and navigable as plain Markdown.[1]
- Every Tier-2 artifact has a Tier-1 fallback that preserves its meaning.[1]
- No Tier-3 artifact is the sole source of knowledge or structure.[1]
- The bundle is complete, usable, and validated by scripts.[1]
- The neovim distribution is reproducible on a fresh machine.[3][1]
- Every important workflow has a declared fallback or is explicitly marked as degraded.[1]
- Notes can move from Obsidian to neovim and back without repair.[1][2]
- The vault exposes its own portability debt through continuous checks.[1]

## Closing frame

The strongest lesson from Thymer's ejectability model is that portability is not the same thing as having plain-text note bodies.[1][2] A system is portable only when its content, structure, workflows, reconstruction instructions, and validation mechanisms all survive outside the originating app with enough fidelity to keep the work usable.[1]
