#!/usr/bin/env bats
# Tests for `okm audit` — pre-share gate scanner.

load 'helpers/test_helper'

setup() {
    common_setup
    OKM="${PROJECT_ROOT}/bin/okm"
    AUDIT_VAULT="${TEST_TEMP_DIR}/audit-vault"
    mkdir -p "$AUDIT_VAULT"
    git -C "$AUDIT_VAULT" init -q -b main
    git -C "$AUDIT_VAULT" config user.email "audit@test"
    git -C "$AUDIT_VAULT" config user.name  "audit-test"
    export OBSIDIAN_VAULT="$AUDIT_VAULT"
    export EDITOR="true"
}

stage_file() {
    local rel="$1" content="$2"
    mkdir -p "$AUDIT_VAULT/$(dirname "$rel")"
    printf '%s\n' "$content" > "$AUDIT_VAULT/$rel"
    git -C "$AUDIT_VAULT" add -- "$rel"
}

@test "audit: clean repo exits 0" {
    stage_file "README.md" "# vault"
    git -C "$AUDIT_VAULT" commit -q -m init
    run "${OKM}" audit
    assert_success
    assert_output --partial "clean"
}

@test "audit: PARA content under inbox/ is flagged" {
    stage_file "inbox/personal.md" "private thought"
    run "${OKM}" audit
    assert_failure
    assert_output --partial "inbox/personal.md"
    assert_output --partial "para-content"
}

@test "audit: PARA content under daily/ is flagged" {
    stage_file "daily/2026-05-03.md" "log"
    run "${OKM}" audit
    assert_failure
    assert_output --partial "daily/2026-05-03.md"
}

@test "audit: PARA content under attachments/ is flagged" {
    stage_file "attachments/screenshot.png" ""
    run "${OKM}" audit
    assert_failure
    assert_output --partial "attachments/screenshot.png"
}

@test "audit: PARA content under private-*/ is flagged" {
    stage_file "private-inbox/secret.md" "secret"
    run "${OKM}" audit
    assert_failure
    assert_output --partial "private-inbox/secret.md"
}

@test "audit: templates under inbox/templates/ are NOT flagged" {
    stage_file "inbox/templates/yt-template.md" "template"
    git -C "$AUDIT_VAULT" commit -q -m templates
    run "${OKM}" audit
    assert_success
}

@test "audit: demo-* files are NOT flagged" {
    stage_file "inbox/demo-yt-example.md" "demo"
    git -C "$AUDIT_VAULT" commit -q -m demos
    run "${OKM}" audit
    assert_success
}

@test "audit: .env files are flagged" {
    stage_file ".env" "SECRET=hunter2"
    run "${OKM}" audit
    assert_failure
    assert_output --partial ".env"
    assert_output --partial "sensitive-filename"
}

@test "audit: *.pem files are flagged" {
    stage_file "key.pem" "x"
    run "${OKM}" audit
    assert_failure
    assert_output --partial "key.pem"
    assert_output --partial "sensitive-filename"
}

@test "audit: AWS access key pattern is flagged" {
    stage_file "config.txt" "key=AKIAIOSFODNN7EXAMPLE end"
    run "${OKM}" audit
    assert_failure
    assert_output --partial "config.txt"
    assert_output --partial "secret-pattern"
}

@test "audit: BEGIN PRIVATE KEY block is flagged" {
    stage_file "id.txt" "-----BEGIN RSA PRIVATE KEY-----"
    run "${OKM}" audit
    assert_failure
    assert_output --partial "secret-pattern"
}

@test "audit: --quiet suppresses output but keeps exit code" {
    stage_file ".env" "x"
    run "${OKM}" audit --quiet
    assert_failure
    [ -z "$output" ]
}

@test "audit: --paths restricts findings" {
    stage_file "inbox/note.md" "x"
    stage_file "daily/log.md" "y"
    run "${OKM}" audit --paths inbox
    assert_failure
    assert_output --partial "inbox/note.md"
    refute_output --partial "daily/log.md"
}

@test "audit: --code-only and --vault-only are mutually exclusive" {
    run "${OKM}" audit --code-only --vault-only
    [ "$status" -eq 2 ]
    assert_output --partial "mutually exclusive"
}

@test "audit: unknown flag exits 2" {
    run "${OKM}" audit --bogus
    [ "$status" -eq 2 ]
    assert_output --partial "unknown flag"
}

@test "audit: non-git directory exits 2" {
    rm -rf "$AUDIT_VAULT/.git"
    run "${OKM}" audit
    [ "$status" -eq 2 ]
    assert_output --partial "not a git repository"
}

@test "audit: --help prints usage and exits 0" {
    run "${OKM}" audit --help
    assert_success
    assert_output --partial "Usage: okm audit"
    assert_output --partial "Exit codes"
}
