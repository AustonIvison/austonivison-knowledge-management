#!/usr/bin/env bash
# scripts/lib/platform.sh — portable OS detection and cross-platform wrappers.
#
# Usage:
#   source "${SCRIPT_DIR}/scripts/lib/platform.sh"

_platform_os() {
    case "$(uname -s)" in
        Darwin) printf 'macos\n' ;;
        Linux)  printf 'linux\n' ;;
        *)      return 1 ;;
    esac
}

_platform_arch() {
    case "$(uname -m)" in
        x86_64|amd64)  printf 'x86_64\n' ;;
        arm64|aarch64) printf 'arm64\n' ;;
        *)             return 1 ;;
    esac
}

is_macos() { [ "$(_platform_os 2>/dev/null)" = "macos" ]; }
is_wsl2()  { grep -qi 'microsoft' /proc/version 2>/dev/null; }
is_linux() { [ "$(_platform_os 2>/dev/null)" = "linux" ]; }

_require_bash4() {
    if [ "${BASH_VERSINFO[0]:-0}" -ge 4 ]; then
        return 0
    fi

    printf 'Bash 4 or newer is required (found %s).\n' "${BASH_VERSION:-unknown}" >&2
    if is_macos; then
        printf 'Install it with: brew install bash\n' >&2
        printf 'Then activate this project from zsh and retry: source env.sh\n' >&2
    fi
    return 1
}

# _timeout SECONDS CMD [ARGS...]
# Works on GNU Linux (timeout) and macOS with Homebrew coreutils (gtimeout).
# Falls back to running the command without a timeout if neither is available.
_timeout() {
    local dur="$1"; shift
    if command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$dur" "$@"
    elif command -v timeout >/dev/null 2>&1; then
        timeout "$dur" "$@"
    else
        "$@"
    fi
}

# _date_add YYYY-MM-DD OFFSET_DAYS
# Prints the resulting date in YYYY-MM-DD format.
# Supports GNU date (Linux) and BSD date (macOS).
# OFFSET_DAYS may be positive or negative (e.g. "-3" or "+5").
_date_add() {
    local base="$1" days="$2"
    # GNU date
    if date -d "${base} ${days} days" +%F 2>/dev/null; then
        return
    fi
    # BSD date (macOS): date -v[+-]Nd -j -f fmt input +fmt
    local abs="${days#[+-]}"
    if [ "${days:0:1}" = "-" ]; then
        date -v "-${abs}d" -j -f "%Y-%m-%d" "${base}" +%Y-%m-%d 2>/dev/null
    else
        date -v "+${abs}d" -j -f "%Y-%m-%d" "${base}" +%Y-%m-%d 2>/dev/null
    fi
}

# _realpath [-m] PATH
# Resolves existing paths on both GNU and BSD userlands. With -m, missing path
# components are allowed (matching GNU realpath -m semantics).
_realpath() {
    local allow_missing=false
    if [ "${1:-}" = "-m" ]; then
        allow_missing=true
        shift
    fi
    [ "${1:-}" = "--" ] && shift
    [ "$#" -eq 1 ] || return 2

    local path="$1"
    if "${allow_missing}"; then
        if command -v realpath >/dev/null 2>&1 \
           && realpath -m -- "${path}" 2>/dev/null; then
            return 0
        fi
    elif command -v realpath >/dev/null 2>&1; then
        if realpath -- "${path}" 2>/dev/null; then
            return 0
        fi
        case "${path}" in
            -*) ;;
            *) realpath "${path}" 2>/dev/null && return 0 ;;
        esac
    fi

    command -v python3 >/dev/null 2>&1 || {
        printf 'Cannot resolve path: install python3 or GNU realpath\n' >&2
        return 1
    }

    python3 - "${path}" "${allow_missing}" <<'PY'
import os
import sys

path, allow_missing = sys.argv[1], sys.argv[2] == "true"
if not allow_missing and not os.path.lexists(path):
    raise SystemExit(1)
print(os.path.realpath(path))
PY
}

# Decode base64 from stdin using the host implementation's supported flag.
_base64_decode() {
    if is_macos; then
        base64 -D
    else
        base64 -d
    fi
}

_file_mode() {
    if stat -c '%a' "$1" >/dev/null 2>&1; then
        stat -c '%a' "$1"
    else
        stat -f '%Lp' "$1"
    fi
}

# _pkg_install_hint PKG
# Prints the appropriate install hint for the current platform.
_pkg_install_hint() {
    local pkg="$1"
    case "${pkg}" in
        rg)      pkg="ripgrep" ;;
        wl-copy) pkg="wl-clipboard" ;;
        python3)
            if is_macos; then
                pkg="python"
            else
                pkg="python3"
            fi
            ;;
    esac

    if is_macos; then
        printf 'brew install %s' "${pkg}"
    else
        printf 'sudo apt install %s' "${pkg}"
    fi
}

_launch_obsidian() {
    if is_macos; then
        command -v open >/dev/null 2>&1 || {
            printf 'okm obs: macOS open command not found\n' >&2
            return 1
        }
        if ! open -Ra "Obsidian" >/dev/null 2>&1; then
            printf 'okm obs: Obsidian is not installed — run: brew install --cask obsidian\n' >&2
            return 1
        fi
        open -a "Obsidian" >/dev/null
        return
    fi

    command -v flatpak >/dev/null 2>&1 || {
        printf 'okm obs: flatpak is not installed\n' >&2
        return 1
    }
    if ! flatpak info --user md.obsidian.Obsidian >/dev/null 2>&1; then
        printf 'okm obs: Obsidian Flatpak is not installed\n' >&2
        return 1
    fi
    flatpak run md.obsidian.Obsidian >/dev/null 2>&1 &
}
