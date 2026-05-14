#!/usr/bin/env bats
# Tests for .gitignore correctness.

load 'helpers/test_helper'

setup() {
    common_setup
    GITIGNORE="${PROJECT_ROOT}/.gitignore"
}

@test ".gitignore exists" {
    [ -f "$GITIGNORE" ]
}

@test "bin/nvim is ignored" {
    grep -q '^bin/nvim$' "$GITIGNORE"
}

@test "bin/lazygit is ignored" {
    grep -q '^bin/lazygit$' "$GITIGNORE"
}

@test "public/inbox/*.md is ignored" {
    grep -q 'public/inbox/\*.md' "$GITIGNORE"
}

@test "public/inbox/templates/ directory is exempted from inbox ignore" {
    grep -q '!public/inbox/templates/' "$GITIGNORE"
}

@test "swap files *.swp are ignored" {
    grep -q '^\*\.swp$' "$GITIGNORE"
}

@test "swap files *.swo are ignored" {
    grep -q '^\*\.swo$' "$GITIGNORE"
}

@test "attachment PDFs are ignored" {
    grep -q 'public/attachments/\*\.pdf' "$GITIGNORE"
}

@test ".obsidian/workspace.json is ignored" {
    grep -q '\.obsidian/workspace\.json' "$GITIGNORE"
}

@test ".DS_Store is ignored" {
    grep -q '\.DS_Store' "$GITIGNORE"
}

@test "bin/okm is NOT ignored" {
    # bin/okm should be tracked (only bin/nvim and bin/lazygit are gitignored)
    ! grep -q '^bin/okm$' "$GITIGNORE"
}

@test "venv/ is ignored" {
    grep -q '^venv/$' "$GITIGNORE"
}
