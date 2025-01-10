#!/bin/sh
set -e

# Make sure important variables exist if not already defined
#
# $USER is defined by login(1) which is not always executed (e.g. containers)
# POSIX: https://pubs.opengroup.org/onlinepubs/009695299/utilities/id.html
USER=${USER:-$(id -u -n)}

# $HOME is defined at the time of login, but it could be unset. If it is unset,
# a tilde by itself (~) will not be expanded to the current user's home directory.
# POSIX: https://pubs.opengroup.org/onlinepubs/009696899/basedefs/xbd_chap08.html#tag_08_03
HOME="${HOME:-$(getent passwd "$USER" 2>/dev/null | cut -d: -f6)}"
# macOS does not have getent, but this works even if $HOME is unset
HOME="${HOME:-$(eval echo ~"$USER")}"

command_exists() {
    command -v "$@" >/dev/null 2>&1
}

# The [ -t 1 ] check only works when the function is not called from
# a subshell (like in `$(...)` or `(...)`, so this hack redefines the
# function at the top level to always return false when stdout is not
# a tty.
if [ -t 1 ]; then
    is_tty() {
        true
    }
else
    is_tty() {
        false
    }
fi

# This function uses the logic from supports-hyperlinks[1][2], which is
# made by Kat Marchán (@zkat) and licensed under the Apache License 2.0.
# [1] https://github.com/zkat/supports-hyperlinks
# [2] https://crates.io/crates/supports-hyperlinks
#
# Copyright (c) 2021 Kat Marchán
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
supports_hyperlinks() {
    # $FORCE_HYPERLINK must be set and be non-zero (this acts as a logic bypass)
    if [ -n "$FORCE_HYPERLINK" ]; then
        [ "$FORCE_HYPERLINK" != 0 ]
        return $?
    fi

    # If stdout is not a tty, it doesn't support hyperlinks
    is_tty || return 1

    # DomTerm terminal emulator (domterm.org)
    if [ -n "$DOMTERM" ]; then
        return 0
    fi

    # VTE-based terminals above v0.50 (Gnome Terminal, Guake, ROXTerm, etc)
    if [ -n "$VTE_VERSION" ]; then
        [ "$VTE_VERSION" -ge 5000 ]
        return $?
    fi

    # If $TERM_PROGRAM is set, these terminals support hyperlinks
    case "$TERM_PROGRAM" in
    Hyper | iTerm.app | terminology | WezTerm | vscode) return 0 ;;
    esac

    # These termcap entries support hyperlinks
    case "$TERM" in
    xterm-kitty | alacritty | alacritty-direct) return 0 ;;
    esac

    # xfce4-terminal supports hyperlinks
    if [ "$COLORTERM" = "xfce4-terminal" ]; then
        return 0
    fi

    # Windows Terminal also supports hyperlinks
    if [ -n "$WT_SESSION" ]; then
        return 0
    fi

    # Konsole supports hyperlinks, but it's an opt-in setting that can't be detected
    # https://github.com/ohmyzsh/ohmyzsh/issues/10964
    # if [ -n "$KONSOLE_VERSION" ]; then
    #   return 0
    # fi

    return 1
}

# Adapted from code and information by Anton Kochkov (@XVilka)
# Source: https://gist.github.com/XVilka/8346728
supports_truecolor() {
    case "$COLORTERM" in
    truecolor | 24bit) return 0 ;;
    esac

    case "$TERM" in
    iterm | \
        tmux-truecolor | \
        linux-truecolor | \
        xterm-truecolor | \
        screen-truecolor) return 0 ;;
    esac

    return 1
}

fmt_link() {
    # $1: text, $2: url, $3: fallback mode
    if supports_hyperlinks; then
        printf '\033]8;;%s\033\\%s\033]8;;\033\\\n' "$2" "$1"
        return
    fi

    case "$3" in
    --text) printf '%s\n' "$1" ;;
    --url | *) fmt_underline "$2" ;;
    esac
}

fmt_underline() {
    is_tty && printf '\033[4m%s\033[24m\n' "$*" || printf '%s\n' "$*"
}

# shellcheck disable=SC2016 # backtick in single-quote
fmt_code() {
    is_tty && printf '`\033[2m%s\033[22m`\n' "$*" || printf '`%s`\n' "$*"
}

fmt_error() {
    printf '%sError: %s%s\n' "${FMT_BOLD}${FMT_RED}" "$*" "$FMT_RESET" >&2
}

setup_color() {
    # Only use colors if connected to a terminal
    if ! is_tty; then
        FMT_RAINBOW=""
        FMT_RED=""
        FMT_GREEN=""
        FMT_YELLOW=""
        FMT_BLUE=""
        FMT_PURPLE=""
        FMT_CYAN=""
        FMT_GREY=""
        FMT_BLACK=""
        FMT_BOLD=""
        FMT_RESET=""
        return
    fi

    if supports_truecolor; then
        FMT_RAINBOW="
      $(printf '\033[38;2;255;0;0m')
      $(printf '\033[38;2;255;97;0m')
      $(printf '\033[38;2;247;255;0m')
      $(printf '\033[38;2;0;255;30m')
      $(printf '\033[38;2;77;0;255m')
      $(printf '\033[38;2;168;0;255m')
      $(printf '\033[38;2;245;0;172m')
    "
    else
        FMT_RAINBOW="
      $(printf '\033[38;5;196m')
      $(printf '\033[38;5;202m')
      $(printf '\033[38;5;226m')
      $(printf '\033[38;5;082m')
      $(printf '\033[38;5;021m')
      $(printf '\033[38;5;093m')
      $(printf '\033[38;5;163m')
    "
    fi

    FMT_RED=$(printf '\033[31m')
    FMT_GREEN=$(printf '\033[32m')
    FMT_YELLOW=$(printf '\033[33m')
    FMT_BLUE=$(printf '\033[34m')
    FMT_PURPLE=$(printf '\033[35m')
    FMT_CYAN=$(printf '\033[36m')
    FMT_GREY=$(printf '\033[37m')
    FMT_BLACK=$(printf '\033[38m')
    FMT_BOLD=$(printf '\033[1m')
    FMT_RESET=$(printf '\033[0m')
}

add_to_rc_file() {
    shell_rc_file=""

    case "$SHELL" in
    */bash)
        shell_rc_file="$HOME/.bashrc"
        ;;
    */zsh)
        shell_rc_file="$HOME/.zshrc"
        ;;
    */ksh)
        shell_rc_file="$HOME/.kshrc"
        ;;
    *)
        fmt_error "[!] Unsupported shell. Please add the PATH to your shell's RC file manually."
        return 1
        ;;
    esac

    bin_path='[ -d "$HOME/bin" ] && export PATH="$HOME/bin:$PATH"'

    if ! grep -Fxq "$bin_path" "$shell_rc_file"; then
        echo "$bin_path" >>"$shell_rc_file"
        echo "[!] ${FMT_BLUE}Added PATH update to $shell_rc_file${FMT_RESET}"
    else
        echo "[?] ${FMT_YELLOW}PATH update already exists in $shell_rc_file${FMT_RESET}"
    fi
}

create_bin_dir() {
    if [ ! -d "$HOME/bin" ]; then
        mkdir "$HOME/bin"
        printf "%s\n" "[!] ${FMT_BLUE}Created \$HOME/bin directory${FMT_RESET}"
    else
        printf "%s\n" "[?] ${FMT_YELLOW}\$HOME/bin directory already exists${FMT_RESET}"
    fi
}

prompt_yes_no() {
    prompt="$1"
    default="${2:-n}"
    response=

    while true; do
        printf "%s [y/n] " "$prompt"
        read -r response
        case "$response" in
        [yY]*) return 0 ;;
        [nN]*) return 1 ;;
        "") [ "$default" = "y" ] && return 0 || return 1 ;;
        esac
    done
}

main() {
    # Check if the terminal supports colors
    setup_color

    printf "%s\n%s\n" \
        "${FMT_PURPLE}${FMT_BOLD}$(fmt_underline "Automated Installer")${FMT_RESET}" \
        "${FMT_BOLD}-------------------${FMT_RESET}"

    # Create the bin directory
    create_bin_dir
    add_to_rc_file

    # Check if any URLs were provided
    if [ $# -eq 0 ]; then
        fmt_error "No URLs provided"
        return 1
    fi

    # Check if curl or wget is available
    if ! command_exists curl && ! command_exists wget; then
        fmt_error "Neither curl nor wget is available. Skipping download."
        return 1
    fi

    # Download the files
    for repo_url in "$@"; do
        if [ "${repo_url#http}" = "$repo_url" ]; then
            fmt_error "Invalid URL: $repo_url"
            continue
        fi

        file_name=$(basename "$repo_url")
        file_path="$HOME/bin/${file_name}"

        if [ -f "$file_path" ]; then
            printf "[?] ${FMT_YELLOW}The file ${FMT_BOLD}%s${FMT_RESET} ${FMT_YELLOW}already exists...${FMT_RESET}\n" \
                "$(fmt_link "$file_name" "$file_path" --text)"

            # Prompt to overwrite the file
            if ! prompt_yes_no "    Do you want to overwrite the file?"; then
                printf "[?] ${FMT_YELLOW}Skipping %s${FMT_RESET}\n" \
                    "$(fmt_link "$file_name" "$file_path" --text)"
                continue
            else
                printf "[!] ${FMT_YELLOW}Overwriting %s${FMT_RESET}\n" \
                    "$(fmt_link "$file_name" "$file_path" --text)"
            fi
        fi

        printf "[!] ${FMT_YELLOW}Downloading ${FMT_BLUE}%s${FMT_RESET}\n" \
            "$(fmt_underline "$repo_url")"

        contents=""
        if command_exists curl; then
            contents=$(curl -sSL "$repo_url")
        elif command_exists wget; then
            contents=$(wget -qO- "$repo_url")
        fi

        # Check if the download was successful
        if [ -z "$contents" ]; then
            fmt_error "Failed to download $repo_url"
            continue
        fi

        # Write the contents to the file
        printf "%s" "$contents" >"$file_path"
        if [ ! -f "$file_path" ]; then
            fmt_error "Failed to write to $file_path"
            continue
        else
            printf "[!] ${FMT_YELLOW}Downloaded %s${FMT_RESET}\n" \
                "$(fmt_link "$file_name" "$file_path" --text)"
        fi

        # Set file to be executable by the user
        chmod u+x "$file_path"
        if [ ! -x "$file_path" ]; then
            fmt_error "Failed to make $file_path executable"
            continue
        else
            printf "[!] ${FMT_YELLOW}Made %s executable${FMT_RESET}\n" \
                "$(fmt_link "$file_name" "$file_path" --text)"
        fi
    done

    printf "\n%s\n" "${FMT_GREEN}${FMT_BOLD}Installation complete!${FMT_RESET}"
    printf "%s%s\n\n" \
        "${FMT_BLUE}${FMT_BOLD}Please restart your shell to " \
        "apply the changes${FMT_RESET}"

    return 0
}

main "$@"
