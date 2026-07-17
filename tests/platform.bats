#!/usr/bin/env bats

load 'helpers/test_helper'

setup() {
    common_setup
    source "${PROJECT_ROOT}/scripts/lib/platform.sh"
}

@test "platform helpers identify the current runner" {
    case "$(uname -s)" in
        Darwin)
            [ "$(_platform_os)" = "macos" ]
            is_macos
            ;;
        Linux)
            [ "$(_platform_os)" = "linux" ]
            is_linux
            ;;
        *)
            false
            ;;
    esac
}

@test "platform architecture normalizes Intel and ARM names" {
    case "$(uname -m)" in
        arm64|aarch64) [ "$(_platform_arch)" = "arm64" ] ;;
        x86_64|amd64)  [ "$(_platform_arch)" = "x86_64" ] ;;
        *)             false ;;
    esac
}

@test "_date_add handles BSD or GNU date" {
    [ "$(_date_add "2026-01-31" "+1")" = "2026-02-01" ]
    [ "$(_date_add "2026-01-01" "-1")" = "2025-12-31" ]
}

@test "_realpath resolves existing and missing paths" {
    mkdir -p "${TEST_TEMP_DIR}/paths/existing"
    local physical_paths
    physical_paths="$(cd "${TEST_TEMP_DIR}/paths" && pwd -P)"
    [ "$(_realpath -- "${TEST_TEMP_DIR}/paths/existing")" = "${physical_paths}/existing" ]
    [ "$(_realpath -m -- "${TEST_TEMP_DIR}/paths/missing/../target")" = "${physical_paths}/target" ]
}

@test "_base64_decode supports the host base64 implementation" {
    [ "$(printf 'cG9ydGFibGU=' | _base64_decode)" = "portable" ]
}

@test "package hints map command names to Homebrew formulae" {
    is_macos() { return 0; }
    [ "$(_pkg_install_hint rg)" = "brew install ripgrep" ]
    [ "$(_pkg_install_hint python3)" = "brew install python" ]
}

@test "package hints map command names to apt packages" {
    is_macos() { return 1; }
    [ "$(_pkg_install_hint rg)" = "sudo apt install ripgrep" ]
    [ "$(_pkg_install_hint python3)" = "sudo apt install python3" ]
}

@test "Obsidian launcher uses native open on macOS" {
    local fake_bin="${TEST_TEMP_DIR}/mac-launch"
    export OPEN_LOG="${TEST_TEMP_DIR}/open.log"
    mkdir -p "${fake_bin}"
    cat > "${fake_bin}/open" <<'OPEN'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${OPEN_LOG}"
OPEN
    chmod +x "${fake_bin}/open"
    PATH="${fake_bin}:${PATH}"
    is_macos() { return 0; }

    _launch_obsidian

    grep -q '^-Ra Obsidian$' "${OPEN_LOG}"
    grep -q '^-a Obsidian$' "${OPEN_LOG}"
}

@test "Obsidian launcher uses Flatpak on Linux" {
    local fake_bin="${TEST_TEMP_DIR}/linux-launch"
    export FLATPAK_LOG="${TEST_TEMP_DIR}/flatpak.log"
    mkdir -p "${fake_bin}"
    cat > "${fake_bin}/flatpak" <<'FLATPAK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${FLATPAK_LOG}"
FLATPAK
    chmod +x "${fake_bin}/flatpak"
    PATH="${fake_bin}:${PATH}"
    is_macos() { return 1; }

    _launch_obsidian
    sleep 0.1

    grep -q '^info --user md.obsidian.Obsidian$' "${FLATPAK_LOG}"
    grep -q '^run md.obsidian.Obsidian$' "${FLATPAK_LOG}"
}
