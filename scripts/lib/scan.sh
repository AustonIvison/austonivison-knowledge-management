#!/usr/bin/env bash
# scripts/lib/scan.sh — Shared PARA scanning functions for todo-summary.sh and weekly-tasks.sh.
#
# Source this file; it provides:
#   get_title <filepath>          — extract a human-readable title from a file
#   format_item <dir> <rg-line>   — format a ripgrep match as a PARA checklist item
#   scan_directory <dir>          — populate projects_items, areas_items, resources_items
#   carry_forward_into <new> <prev> — merge unchecked items from a previous section

# Title cache (caller must declare: declare -A _title_cache)
get_title() {
    local filepath="$1"

    if [[ -n "${_title_cache["$filepath"]+x}" ]]; then
        echo "${_title_cache["$filepath"]}"
        return
    fi

    local title=""

    if [[ "$filepath" == *.md ]]; then
        if [[ -f "$filepath" ]]; then
            title="$(sed -n '/^---$/,/^---$/{/^title:/{ s/^title:[[:space:]]*//; s/^["'\''"]//; s/["'\''"]$//; p; q; }}' "$filepath")"
        fi
        if [[ -z "$title" && -f "$filepath" ]]; then
            title="$(sed -n 's/^# *//p' "$filepath" | head -1)"
        fi
        if [[ -z "$title" ]]; then
            title="$(basename "$filepath" .md)"
        fi
    else
        title="$(basename "$filepath")"
    fi

    _title_cache["$filepath"]="$title"
    echo "$title"
}

format_item() {
    local dir="$1"
    local line="$2"
    local relative="${line#"$dir"/}"
    local file_part="${relative%%:*}"
    local rest="${relative#*:}"
    local lineno="${rest%%:*}"
    local text="${rest#*:}"
    text="$(echo "$text" | sed 's/^[[:space:]]*//')"
    text="$(echo "$text" | sed 's/^- \[ \] *//')"

    local title
    title="$(get_title "${dir}/${file_part}")"

    echo "- [ ] **${title}** (\`${file_part}:${lineno}\`) — ${text}"
}

# Scan a directory for TODO markers and unchecked tasks.
# Appends results to: projects_items, areas_items, resources_items (caller must init).
# Accepts extra exclude globs after the directory argument.
scan_directory() {
    local dir="$1"; shift

    if [[ ! -d "$dir" ]]; then
        return
    fi

    local -a exclude_globs=(
        --glob '!**/todo-summary.sh'
        --glob '!**/weekly-tasks.sh'
        --glob '!**/todo-summary-*.md'
        --glob '!**/weekly-*.md'
        --glob '!**/weekly-template.md'
        --glob '!tests/**'
    )
    # Append caller-specified extra excludes
    exclude_globs+=("$@")

    local -a type_globs=(
        --glob '*.sh' --glob '*.lua' --glob '*.yml' --glob '*.json' --glob '*.md'
        --glob '*.py' --glob '*.vim' --glob '*.toml'
    )

    # Projects: code markers (TODO, FIXME, HACK, XXX)
    local marker_hits
    marker_hits="$(rg -n --no-heading \
        "${type_globs[@]}" \
        "${exclude_globs[@]}" \
        -e '\bTODO:' -e '\bFIXME:' -e '\bHACK:' -e '\bXXX:' \
        "$dir" 2>/dev/null || true)"

    if [[ -n "$marker_hits" ]]; then
        while IFS= read -r line; do
            local text_part="${line#*:*:}"
            if [[ "$text_part" == *"|"*"TODO:"*"|"* || "$text_part" == *"|"*"FIXME:"*"|"* || \
                  "$text_part" == *"|"*"HACK:"*"|"* || "$text_part" == *"|"*"XXX:"*"|"* ]]; then
                continue
            fi
            projects_items+="$(format_item "$dir" "$line")"$'\n'
        done <<< "$marker_hits"
    fi

    # Resources: REVIEW markers
    local review_hits
    review_hits="$(rg -n --no-heading \
        "${type_globs[@]}" \
        "${exclude_globs[@]}" \
        -e '\bREVIEW:' \
        "$dir" 2>/dev/null || true)"

    if [[ -n "$review_hits" ]]; then
        while IFS= read -r line; do
            local text_part="${line#*:*:}"
            if [[ "$text_part" == *"|"*"REVIEW:"*"|"* ]]; then
                continue
            fi
            resources_items+="$(format_item "$dir" "$line")"$'\n'
        done <<< "$review_hits"
    fi

    # Areas: unchecked markdown tasks
    local unchecked_tasks
    unchecked_tasks="$(rg -n --no-heading --glob '*.md' \
        "${exclude_globs[@]}" \
        -e '^\s*- \[ \]' \
        "$dir" 2>/dev/null || true)"

    if [[ -n "$unchecked_tasks" ]]; then
        while IFS= read -r line; do
            areas_items+="$(format_item "$dir" "$line")"$'\n'
        done <<< "$unchecked_tasks"
    fi
}

# Extract unchecked items from a sed range of a section.
_unchecked_from_section() {
    printf '%s\n' "$1" | sed -n "$2" | grep '^\- \[ \]' || true
}

# Merge unchecked items from a previous day section into a new day section.
carry_forward_into() {
    local new_section="$1"
    local prev_section="$2"

    if [[ -z "$prev_section" ]]; then
        echo "$new_section"
        return
    fi

    local prev_projects prev_areas prev_resources
    prev_projects="$(_unchecked_from_section "$prev_section" '/^#### Projects/,/^#### Areas/p')"
    prev_areas="$(_unchecked_from_section "$prev_section" '/^#### Areas/,/^#### Resources/p')"
    prev_resources="$(_unchecked_from_section "$prev_section" '/^#### Resources/,/^---$/p')"

    local _merge_items  # carries items to inject at current bucket boundary
    _merge_items() {
        local items="$1"
        [[ -z "$items" ]] && return
        while IFS= read -r item; do
            printf '%s\n' "$new_section" | grep -qF "$item" || result+="${item}"$'\n'
        done <<< "$items"
    }

    local current_bucket="" result=""
    while IFS= read -r line; do
        case "$line" in
            "#### Projects") current_bucket="projects" ;;
            "#### Areas")    _merge_items "$prev_projects"; current_bucket="areas" ;;
            "#### Resources") _merge_items "$prev_areas";  current_bucket="resources" ;;
            "---")
                [[ "$current_bucket" == "resources" ]] && { _merge_items "$prev_resources"; current_bucket=""; }
                ;;
        esac
        result+="${line}"$'\n'
    done <<< "$new_section"

    echo "$result"
}
