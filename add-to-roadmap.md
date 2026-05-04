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
