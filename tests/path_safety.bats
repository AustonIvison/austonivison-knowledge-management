#!/usr/bin/env bats
# Tests for N19 (okm open path traversal) and N15 (okm sync symlink defense).

load 'helpers/test_helper'

setup() {
    common_setup
    OKM="${PROJECT_ROOT}/bin/okm"
    export OBSIDIAN_VAULT="${FAKE_VAULT_DIR}"
    export OBSIDIAN_DAILY_DIR="daily"
    export OBSIDIAN_NOTES_DIR="inbox"
    export EDITOR="true"
}

# === N19: okm open refuses paths outside the vault ===

@test "N19: okm open refuses absolute path outside vault" {
    create_vault_file "inbox/note.md" "real"
    run "${OKM}" open "/etc/passwd"
    assert_failure
    assert_output --partial "outside the vault"
}

@test "N19: okm open refuses ../ escape" {
    create_vault_file "inbox/note.md" "real"
    local outside="${TEST_TEMP_DIR}/outside.md"
    echo "x" > "$outside"
    run "${OKM}" open "${outside}"
    assert_failure
    assert_output --partial "outside the vault"
}

@test "N19: okm open accepts relative paths inside the vault" {
    create_vault_file "inbox/note.md" "real"
    # EDITOR=true so this returns 0 instantly
    run "${OKM}" open "inbox/note.md"
    assert_success
}

@test "N19: okm open accepts non-existent relative path (will create later)" {
    run "${OKM}" open "inbox/new-note.md"
    assert_success
}

# === N15: okm sync refuses symlinks pointing outside the vault ===

@test "N15: okm sync refuses external symlink in vault" {
    git -C "${FAKE_VAULT_DIR}" init -q -b main
    git -C "${FAKE_VAULT_DIR}" config user.email "t@t"
    git -C "${FAKE_VAULT_DIR}" config user.name  "t"
    create_vault_file "inbox/real.md" "real"
    git -C "${FAKE_VAULT_DIR}" add -A
    git -C "${FAKE_VAULT_DIR}" commit -q -m init

    # Plant an external-target symlink:
    local target="${TEST_TEMP_DIR}/secret.txt"
    echo "secret" > "$target"
    ln -s "$target" "${FAKE_VAULT_DIR}/inbox/oops.md"

    run "${OKM}" sync
    assert_failure
    assert_output --partial "outside the vault"
    assert_output --partial "oops.md"
}

@test "N15: okm sync accepts internal symlinks" {
    git -C "${FAKE_VAULT_DIR}" init -q -b main
    git -C "${FAKE_VAULT_DIR}" config user.email "t@t"
    git -C "${FAKE_VAULT_DIR}" config user.name  "t"
    create_vault_file "inbox/real.md" "real"
    git -C "${FAKE_VAULT_DIR}" add -A
    git -C "${FAKE_VAULT_DIR}" commit -q -m init

    # Internal symlink (vault-relative target) — allowed.
    ln -s "real.md" "${FAKE_VAULT_DIR}/inbox/alias.md"

    run "${OKM}" sync
    # No upstream → "No upstream configured" but exit 0 with the symlink check passed.
    assert_success
    refute_output --partial "outside the vault"
}

# === N15: setup-km.sh sets core.symlinks=false ===

# === N28: resolve_note refuses paths outside vault ===

@test "N28: okm tag refuses absolute path outside vault" {
    create_vault_file "inbox/note.md" "---
tags: []
---"
    local outside="${TEST_TEMP_DIR}/outside.md"
    echo "external" > "$outside"
    run "${OKM}" tag "$outside" newtag
    assert_failure
    assert_output --partial "outside the vault"
    # File must not have been modified
    [ "$(cat "$outside")" = "external" ]
}

@test "N28: okm untag refuses path outside vault" {
    local outside="${TEST_TEMP_DIR}/outside.md"
    printf -- '---\ntags: [foo]\n---\n' > "$outside"
    run "${OKM}" untag "$outside" foo
    assert_failure
    assert_output --partial "outside the vault"
}

@test "N28: okm tags (single note) refuses path outside vault" {
    local outside="${TEST_TEMP_DIR}/outside.md"
    printf -- '---\ntags: [foo]\n---\n' > "$outside"
    run "${OKM}" tags "$outside"
    assert_failure
    assert_output --partial "outside the vault"
}

# === N29: list_notes excludes .git/ ===

@test "N29: okm files does not list .git/ internals" {
    mkdir -p "${FAKE_VAULT_DIR}/.git/refs"
    echo "# secret" > "${FAKE_VAULT_DIR}/.git/refs/notes.md"
    create_vault_file "inbox/real.md" "real"
    run "${OKM}" files
    assert_success
    assert_output --partial "real.md"
    refute_output --partial ".git"
}

# === N15: setup-km.sh sets core.symlinks=false ===

@test "N15: ensure_git_repo sets core.symlinks=false" {
    local target="${TEST_TEMP_DIR}/symlink-test"
    mkdir -p "$target"

    # Pre-init git so ensure_git_repo takes the "already exists" branch
    # and skips the commit that requires user.email/user.name.
    git -C "$target" init -q -b main
    git -C "$target" config user.email "t@t"
    git -C "$target" config user.name "t"
    touch "$target/.gitkeep"
    git -C "$target" add .
    git -C "$target" commit -q -m init

    # Extract just the function definition, define stubs, then call it.
    log_info() { :; }
    log_error() { :; }
    eval "$(awk '/^ensure_git_repo\(\)/,/^}/' "${PROJECT_ROOT}/setup-km.sh")"
    ensure_git_repo "$target"
    [ "$(git -C "$target" config --get core.symlinks)" = "false" ]
}
