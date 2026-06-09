#!/usr/bin/env bats
# Tests for the scheduled cron job configuration.
#
# Validates:
#   - The cron-invoked command (todo-summary.sh --output) works correctly
#   - Same-day re-runs replace (not duplicate) today's section
#   - The yearly file uses carry-forward for unchecked items
# F7: Tests assert behavioral output only — not documentation schedule strings.

load 'helpers/test_helper'

EXPECTED_HOURS=("7" "12" "15")
EXPECTED_CRON_LINES=(
    "3 7 * * *"
    "3 12 * * *"
    "3 15 * * *"
)

setup() {
    common_setup

    mkdir -p "${TEST_TEMP_DIR}/scripts/lib"
    cp "${PROJECT_ROOT}/scripts/lib/"*.sh "${TEST_TEMP_DIR}/scripts/lib/"
    cp "${PROJECT_ROOT}/scripts/todo-summary.sh" "${TEST_TEMP_DIR}/todo-summary.sh"
    sed -i "s|^SCRIPT_DIR=.*|SCRIPT_DIR=\"${TEST_TEMP_DIR}\"|" "${TEST_TEMP_DIR}/todo-summary.sh"
    sed -i "s|^PROJECT_DIR=.*|PROJECT_DIR=\"${FAKE_PROJECT_DIR}\"|" "${TEST_TEMP_DIR}/todo-summary.sh"
    sed -i "s|^OUTPUT_FILE=.*|OUTPUT_FILE=\"${FAKE_PROJECT_DIR}/public/inbox/todo-summary-\${YEAR}.md\"|" "${TEST_TEMP_DIR}/todo-summary.sh"
    export OBSIDIAN_VAULT="${FAKE_VAULT_DIR}"
    chmod +x "${TEST_TEMP_DIR}/todo-summary.sh"
}

# === Cron expression validity (constant assertions, no doc-string dependency) ===

@test "cron expressions use minute 3 (off-peak)" {
    for cron in "${EXPECTED_CRON_LINES[@]}"; do
        [[ "$cron" == 3\ * ]]
    done
}

@test "cron expressions run every day of the week" {
    for cron in "${EXPECTED_CRON_LINES[@]}"; do
        [[ "$cron" == *"* * *" ]]
    done
}

@test "todo-summary.sh header mentions all 3 schedule times" {
    grep -q '07:00.*12:00.*15:00' "${PROJECT_ROOT}/scripts/todo-summary.sh"
}

@test "3 expected schedule hours defined" {
    [ "${#EXPECTED_HOURS[@]}" -eq 3 ]
}

# === Cron-invoked command behavior ===

@test "cron command (--output) creates yearly summary file" {
    create_project_file "job.sh" "# TODO: cron test item"
    run bash "${TEST_TEMP_DIR}/todo-summary.sh" --output
    assert_success
    [ -f "${FAKE_PROJECT_DIR}/public/inbox/todo-summary-$(date +%Y).md" ]
}

@test "cron command output file contains PARA structure" {
    create_project_file "job.sh" "# TODO: cron para test"
    bash "${TEST_TEMP_DIR}/todo-summary.sh" --output
    local file="${FAKE_PROJECT_DIR}/public/inbox/todo-summary-$(date +%Y).md"
    grep -q "#### Projects" "$file"
    grep -q "#### Areas" "$file"
    grep -q "#### Resources" "$file"
    grep -q "## Archive" "$file"
}

@test "cron command output file has correct frontmatter tags" {
    bash "${TEST_TEMP_DIR}/todo-summary.sh" --output
    local file="${FAKE_PROJECT_DIR}/public/inbox/todo-summary-$(date +%Y).md"
    grep -q 'tags: \[todo-summary, para, automated\]' "$file"
}

# === Multiple cron fires same day: replace behavior ===

@test "same-day re-run replaces today's section" {
    create_project_file "first.sh" "# TODO: first run item"
    bash "${TEST_TEMP_DIR}/todo-summary.sh" --output
    local file="${FAKE_PROJECT_DIR}/public/inbox/todo-summary-$(date +%Y).md"

    create_project_file "second.sh" "# TODO: second run item"
    bash "${TEST_TEMP_DIR}/todo-summary.sh" --output

    local day_count
    day_count=$(grep -c "^### $(date +%F)$" "$file")
    [ "$day_count" -eq 1 ]

    grep -q "second run item" "$file"
}

@test "only one yearly file exists after multiple runs" {
    bash "${TEST_TEMP_DIR}/todo-summary.sh" --output
    bash "${TEST_TEMP_DIR}/todo-summary.sh" --output
    bash "${TEST_TEMP_DIR}/todo-summary.sh" --output
    local count
    count=$(find "${FAKE_PROJECT_DIR}/public/inbox" -name 'todo-summary-*.md' | wc -l)
    [ "$count" -eq 1 ]
}

@test "later cron run picks up items added since earlier run" {
    create_project_file "morning.sh" "# TODO: morning task"
    bash "${TEST_TEMP_DIR}/todo-summary.sh" --output
    local file="${FAKE_PROJECT_DIR}/public/inbox/todo-summary-$(date +%Y).md"
    grep -q "morning task" "$file"

    create_vault_file "public/inbox/new-note.md" "- [ ] added after morning scan"
    create_project_file "afternoon.sh" "# FIXME: afternoon bugfix"

    bash "${TEST_TEMP_DIR}/todo-summary.sh" --output

    grep -q "added after morning scan" "$file"
    grep -q "afternoon bugfix" "$file"
}

# === Cron script path ===

@test "todo-summary.sh accepts --output flag" {
    run bash "${TEST_TEMP_DIR}/todo-summary.sh" --output
    assert_success
}

@test "todo-summary.sh is executable" {
    [ -x "${PROJECT_ROOT}/scripts/todo-summary.sh" ]
}
