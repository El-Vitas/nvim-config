#!/usr/bin/env bash
# Installs this Neovim config:
#   curl -fsSL https://raw.githubusercontent.com/El-Vitas/nvim-config/main/install.sh | bash
# Options (after `bash -s --`): --no-fonts skips the folder-icon font, --dir <path> installs elsewhere.
# An existing config is moved aside, never deleted.
set -euo pipefail

REPO_URL="https://github.com/El-Vitas/nvim-config.git"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
FONTCONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/conf.d"
MIN_NVIM_MINOR=12
INSTALL_FONTS=1

while [ $# -gt 0 ]; do
  case "$1" in
    --no-fonts) INSTALL_FONTS=0 ;;
    --dir) TARGET="$2"; shift ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

say() { printf '\033[1;35m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m  x\033[0m %s\n' "$*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }

check_requirements() {
  say "Checking requirements"
  has git || fail "git is required"
  has nvim || fail "Neovim 0.${MIN_NVIM_MINOR}+ is required: https://github.com/neovim/neovim/releases"
  local minor
  minor="$(nvim --version | head -1 | sed -E 's/^NVIM v0\.([0-9]+).*/\1/')"
  [ "${minor:-0}" -ge "$MIN_NVIM_MINOR" ] 2>/dev/null || fail "Neovim 0.${MIN_NVIM_MINOR}+ is required, found $(nvim --version | head -1)"
  # Optional tools: the editor starts without them, but these features need them.
  has rg || warn "ripgrep (rg) not found: live grep in Telescope will not work"
  has make && { has cc || has gcc || has clang; } || warn "make and a C compiler not found: fzf-native falls back to the slower sorter"
  has tree-sitter || warn "tree-sitter CLI not found: treesitter parsers cannot be compiled"
  has node || warn "Node.js not found: the TypeScript, ESLint and Tailwind language servers cannot be installed"
}

backup_existing() {
  [ -e "$TARGET" ] || [ -L "$TARGET" ] || return 0
  local backup
  backup="${TARGET}.bak-$(date +%Y%m%d-%H%M%S)"
  say "Moving your current config to $backup"
  mv "$TARGET" "$backup"
}

install_fonts() {
  [ "$INSTALL_FONTS" -eq 1 ] || return 0
  say "Installing the folder-icon font"
  mkdir -p "$FONT_DIR" "$FONTCONFIG_DIR"
  cp "$TARGET/fonts/MaterialFolders.ttf" "$FONT_DIR/"
  cp "$TARGET/fonts/99-material-folders.conf" "$FONTCONFIG_DIR/"
  if has fc-cache; then fc-cache -f "$FONT_DIR" >/dev/null; fi
}

install_plugins() {
  say "Installing plugins (first run takes a minute)"
  nvim --headless "+Lazy! sync" +qa || warn "Some plugins failed to install; open Neovim and run :Lazy to retry"
}

check_requirements
backup_existing
say "Cloning into $TARGET"
git clone --depth 1 "$REPO_URL" "$TARGET"
install_fonts
install_plugins
say "Done. Open nvim and press <space>? for the cheatsheet."
warn "Use a Nerd Font in your terminal (the config expects CaskaydiaCove Nerd Font): https://www.nerdfonts.com/font-downloads"
