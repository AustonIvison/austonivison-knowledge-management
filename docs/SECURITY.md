# Security Policy

This tool manages a personal knowledge vault, so its security model is first about
keeping *your notes* from leaking — and only then about conventional code security.

## Privacy model

- **`private/` is local-only by default.** Excluded from git regardless of
  `KM_TRACK_NOTES`. AI assistants don't read it, and `okm grep/tags/files/tagged/recent`
  skip it unless `KM_INCLUDE_PRIVATE=1` is set.
- **Pre-push guard.** The tracked hook [`scripts/hooks/pre-push`](../scripts/hooks/pre-push)
  (activated via `core.hooksPath` by `okm port`) refuses to push personal vault content —
  anything under `public/` or `private/` except inbox templates — to the public tool repo
  (blocked deterministically, offline) or to any other public GitHub remote (checked via
  `gh` visibility). A private remote holding your own vault is unrestricted.
  Emergency bypass: `git push --no-verify` — defeats the guard; use with care.
- **`okm audit`.** Scans tracked and staged files for PARA content, secret patterns
  (cloud keys, tokens, private keys), and sensitive filenames; `--json` for CI use.
- **Secrets never tracked.** `.gitignore` excludes `.env*`, `*.pem`, `*.key`, `*.crt`,
  `*credentials*`, `id_rsa*`, `id_ed25519*`.
- **Encryption at rest (optional).** `okm crypt init` configures git-crypt for tracked
  notes. Key loss means permanent data loss; pre-init commits and filenames stay
  plaintext — see the README [git-crypt section](../README.md#advanced-git-crypt).

## Reporting a vulnerability

Use [GitHub private vulnerability reporting](../../security/advisories/new) for anything
sensitive (e.g., a way to bypass the pre-push guard or exfiltrate `private/` content).
For non-sensitive hardening suggestions, open a regular issue.

Please include reproduction steps; `tests/` shows the existing spec style if you want to
express the report as a failing BATS test.
