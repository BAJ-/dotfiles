#!/usr/bin/env bash
# Sets up this Mac, or brings an existing setup up to date: Homebrew tools,
# shell and Neovim config, Node. Safe to run again at any time: every step
# checks first and only changes what is missing or outdated.
#
#   ./setup.sh             apply
#   ./setup.sh --dry-run   list what would change, change nothing
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=script/log.sh
source "$DOTFILES_DIR/script/log.sh"

DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    -n | --dry-run) DRY_RUN=true ;;
    -h | --help)
      sed -n '2,7p' "${BASH_SOURCE[0]}" | sed -E 's/^# ?//'
      exit 0
      ;;
    *)
      warn "Unknown option: $arg (see --help)"
      exit 2
      ;;
  esac
done

if [[ "$(uname -s)" != Darwin ]]; then
  warn "This setup is for macOS"
  exit 1
fi

# -E runs this inside functions too. Subshells ($(...), <(...)) can fail on
# purpose, so only the main shell reports; $BASH_COMMAND must be read first
on_error() { # <command> <subshell level>
  (($2 > 0)) || warn "Stopped: \"$1\" failed"
}
trap 'on_error "$BASH_COMMAND" "$BASH_SUBSHELL"' ERR

BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
NVIM_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
CHANGES=()
FAILED=()
MANUAL=()

# Changes something; a dry run only records what would change (see changed)
run() {
  $DRY_RUN || "$@"
}

changed() {
  CHANGES+=("$1")
  $DRY_RUN || info "$1"
}

failed() {
  FAILED+=("$1")
  warn "$1"
}

tilde() {
  # shellcheck disable=SC2088 # a literal ~ for display
  case "$1" in
    "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;;
    *) printf '%s' "$1" ;;
  esac
}

# --- Homebrew ----------------------------------------------------------------

brew_shellenv() {
  local brew_bin
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
      eval "$("$brew_bin" shellenv)"
      return 0
    fi
  done
  return 1
}

brewfile_names() { # brew | cask
  sed -nE "s/^$1 \"([^\"]+)\".*/\1/p" "$DOTFILES_DIR/Brewfile"
}

# "name version" for every installed Brewfile entry
brew_versions() {
  # shellcheck disable=SC2046 # one name per word
  brew list --formula --versions $(brewfile_names brew) 2>/dev/null || true
  # shellcheck disable=SC2046
  brew list --cask --versions $(brewfile_names cask) 2>/dev/null || true
}

homebrew() {
  if ! command -v brew >/dev/null 2>&1 && ! brew_shellenv; then
    if $DRY_RUN; then
      changed "install Homebrew and everything in the Brewfile"
      return 0
    fi
    info "Installing Homebrew (it asks for your password)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew_shellenv
    changed "install Homebrew"
  fi
  $DRY_RUN && export HOMEBREW_NO_AUTO_UPDATE=1

  # Official taps that are part of Homebrew itself now. Updating first empties
  # Homebrew's old copy of them: an out-of-date copy can still hold casks that
  # are installed (the Hack Nerd Font), and untap then asks to uninstall them.
  local tap taps retired=()
  taps="$(brew tap)"
  for tap in homebrew/cask-fonts homebrew/bundle homebrew/services; do
    if grep -qx "$tap" <<<"$taps"; then
      retired+=("$tap")
    fi
  done
  if ((${#retired[@]})); then
    if ! run brew update --quiet; then
      failed "brew update failed (see above)"
    fi
    for tap in "${retired[@]}"; do
      run brew untap "$tap"
      changed "untap $tap (retired, now part of Homebrew)"
    done
  fi

  local before line name was
  before="$(brew_versions)"
  if $DRY_RUN; then
    for name in $(brewfile_names brew) $(brewfile_names cask); do
      grep -q "^$name " <<<"$before" || changed "install $name"
    done
    # shellcheck disable=SC2046
    while read -r line; do
      [[ -n "$line" ]] && changed "upgrade $(sed -E 's/ \((.*)\) [<!]=? / \1 → /' <<<"$line")"
    done <<<"$({
      brew outdated --formula --verbose $(brewfile_names brew)
      brew outdated --cask --verbose $(brewfile_names cask)
    } 2>/dev/null || true)"
    return 0
  fi

  if ! brew bundle --file="$DOTFILES_DIR/Brewfile"; then
    failed "brew bundle failed (see above)"
  fi
  while read -r line; do
    [[ -n "$line" ]] || continue
    name="${line%% *}"
    was="$(grep "^$name " <<<"$before" || true)"
    if [[ -z "$was" ]]; then
      changed "install $line"
    elif [[ "$was" != "$line" ]]; then
      changed "upgrade $name ${was#* } → ${line#* }"
    fi
  done <<<"$(brew_versions)"
}

# --- Config files --------------------------------------------------------------

# Links into this repo, or into the old layout (repo inside a "dotfiles"
# folder), are ours to replace; so are dangling links
ours() {
  local target
  target="$(readlink "$1")" || return 1
  [[ "$target" == "$DOTFILES_DIR"/* || "$target" == */dotfiles/* || ! -e "$1" ]]
}

# A folder holding nothing but links of ours (the old ~/.config/nvim)
only_our_links() {
  local entry
  for entry in "$1"/* "$1"/.[!.]*; do
    [[ -e "$entry" || -L "$entry" ]] || continue
    if [[ ! -L "$entry" ]] || ! ours "$entry"; then
      return 1
    fi
  done
  return 0
}

backup() {
  local rel="${1#"$HOME"/}"
  run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  run mv "$1" "$BACKUP_DIR/$rel"
  changed "move your $(tilde "$1") to $(tilde "$BACKUP_DIR")/"
}

link() { # <path in this repo> <path in $HOME>
  local src="$DOTFILES_DIR/$1" dest="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    return 0
  fi
  if [[ -L "$dest" ]]; then
    if ours "$dest"; then run rm "$dest"; else backup "$dest"; fi
  elif [[ -d "$dest" ]] && only_our_links "$dest"; then
    run rm -r "$dest"
  elif [[ -e "$dest" ]]; then
    backup "$dest"
  fi
  run mkdir -p "$(dirname "$dest")"
  run ln -s "$src" "$dest"
  changed "link $(tilde "$dest") → $(tilde "$src")"
}

dotfiles() {
  link zshrc "$HOME/.zshrc"
  link z.sh "$HOME/z.sh"
  link config/starship.toml "$HOME/.config/starship.toml"
  link nvim "$HOME/.config/nvim"
  if [[ -L "$HOME/.vimrc" ]] && ours "$HOME/.vimrc"; then
    run rm "$HOME/.vimrc"
    changed "remove ~/.vimrc (plain Vim isn't configured anymore)"
  fi
}

# --- Node ------------------------------------------------------------------------

# npm settings from an old Node's global npmrc that ~/.npmrc doesn't have yet.
# A per-version npmrc vanishes with its Node; ~/.npmrc applies to every version
carry_npm_config() {
  local npmrc="$1" line key keys=() lines=()
  [[ -s "$npmrc" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*([^#\;=[:space:]][^=]*)= ]] || continue
    key="${BASH_REMATCH[1]%"${BASH_REMATCH[1]##*[![:space:]]}"}"
    if [[ "$key" == *'[]' ]]; then
      grep -qxF "$line" "$HOME/.npmrc" 2>/dev/null && continue
    elif awk -F= -v k="$key" '{ gsub(/^[ \t]+|[ \t]+$/, "", $1) } $1 == k { found = 1 } END { exit !found }' \
      "$HOME/.npmrc" 2>/dev/null; then
      continue
    fi
    lines+=("$line")
    [[ " ${keys[*]:-} " == *" $key "* ]] || keys+=("$key")
  done <"$npmrc"
  if ((${#lines[@]} > 0)); then
    if ! $DRY_RUN; then
      printf '%s\n' "${lines[@]}" >>"$HOME/.npmrc"
      chmod 600 "$HOME/.npmrc" # may hold registry tokens
    fi
    changed "copy npm settings (${keys[*]}) from $(tilde "$npmrc") to ~/.npmrc"
  fi
}

# Global npm packages from an old Node's node_modules folder onto the default Node
carry_npm_globals() {
  local from="$1" root dir name pkgs=()
  root="$(npm root -g)"
  for dir in "$from"/* "$from"/@*/*; do
    [[ -d "$dir" ]] || continue
    name="${dir#"$from"/}"
    case "$name" in
      npm | corepack | @*/*/* ) continue ;;
      @*/*) ;;
      @*) continue ;;
    esac
    [[ -d "$root/$name" ]] || pkgs+=("$name")
  done
  if ((${#pkgs[@]} > 0)); then
    if run npm install -g --no-fund --no-audit "${pkgs[@]}"; then
      changed "reinstall global npm packages on the new Node: ${pkgs[*]}"
    else
      failed "couldn't reinstall global npm packages: ${pkgs[*]}"
    fi
  fi
}

node_lts() {
  if ! command -v fnm >/dev/null 2>&1; then
    $DRY_RUN || failed "fnm is missing, so Node isn't set up"
    return 0
  fi
  eval "$(fnm env --shell bash)"
  local before after
  before="$(fnm exec --using=default node --version 2>/dev/null || true)"
  if $DRY_RUN; then
    after="$(fnm ls-remote --lts 2>/dev/null | tail -1 | awk '{print $1}' || true)"
    if [[ -n "$after" && "$after" != "$before" ]]; then
      changed "make Node $after (latest LTS) the default${before:+ instead of $before}"
    fi
    return 0
  fi
  fnm install --lts
  fnm default lts-latest
  fnm use --silent-if-unchanged default
  after="$(node --version)"
  if [[ "$after" != "$before" ]]; then
    changed "make Node $after (latest LTS) the default${before:+ instead of $before}"
    if [[ -n "$before" ]]; then
      carry_npm_config "$(fnm exec --using="$before" npm config get globalconfig)"
      carry_npm_globals "$(fnm exec --using="$before" npm root -g)"
    fi
  fi
}

# --- Leftovers from the old setup ---------------------------------------------------

# Removing never stops the run: files left by an old sudo need your password
remove_dir() { # <dir> <why>
  if run rm -rf "$1"; then
    changed "remove $(tilde "$1") ($2)"
  else
    MANUAL+=("Finish removing $(tilde "$1"), some files there belong to root: sudo rm -rf $(tilde "$1")")
  fi
}

retired_tools() {
  if [[ -d "$HOME/.nvm" ]]; then
    local version
    # newest first: its settings win when versions disagree
    for version in $(printf '%s\n' "$HOME"/.nvm/versions/node/v* | sort -rV); do
      carry_npm_config "$version/etc/npmrc"
    done
    version="$(printf '%s\n' "$HOME"/.nvm/versions/node/v* | sort -V | tail -1)"
    if [[ -d "$version/lib/node_modules" ]] && command -v npm >/dev/null 2>&1; then
      carry_npm_globals "$version/lib/node_modules"
    fi
    remove_dir "$HOME/.nvm" "fnm manages Node now"
  fi
  if [[ -d "$HOME/.gvm" ]]; then
    run chmod -R u+w "$HOME/.gvm" 2>/dev/null || true # Go's module cache is read-only
    remove_dir "$HOME/.gvm" "no longer used"
  fi
  if [[ -d "$HOME/.rye" ]]; then
    remove_dir "$HOME/.rye" "Rye is no longer developed"
  fi

  # Their installers add these to shell startup files; Rye's line errors once it's gone
  local rc pattern='\.rye/env|NVM_DIR|\.nvm/nvm\.sh|\.gvm/scripts'
  for rc in .zprofile .zshenv .zlogin .profile .bash_profile .bashrc; do
    rc="$HOME/$rc"
    if [[ -f "$rc" && ! -L "$rc" ]] && grep -qE "$pattern" "$rc"; then
      run mkdir -p "$BACKUP_DIR"
      run cp "$rc" "$BACKUP_DIR/"
      run sed -i '' -E "\#$pattern#d" "$rc"
      changed "remove nvm/gvm/Rye lines from $(tilde "$rc") (copy in $(tilde "$BACKUP_DIR"))"
    fi
  done
}

# vim-plug's files mark the old Vimscript setup: its plugins, Mason packages,
# state and logs are of no use to the new config
old_neovim() {
  if [[ -e "$HOME/.vim/plugged" || -e "$HOME/.vim/autoload/plug.vim" || -e "$NVIM_DATA/site/autoload/plug.vim" ]]; then
    local dir
    for dir in "$HOME/.vim" "$NVIM_DATA" "${XDG_STATE_HOME:-$HOME/.local/state}/nvim" "${XDG_CACHE_HOME:-$HOME/.cache}/nvim"; do
      if [[ -e "$dir" ]]; then
        remove_dir "$dir" "old Vimscript setup"
      fi
    done
  fi
}

# --- Neovim --------------------------------------------------------------------------

# One line per plugin, parser and Mason package with its version
nvim_state() {
  local dir
  for dir in "$NVIM_DATA"/site/pack/core/opt/*/; do
    [[ -d "$dir" ]] && echo "plugin $(basename "$dir") $(git -C "$dir" rev-parse --short HEAD 2>/dev/null || true)"
  done
  for dir in "$NVIM_DATA"/site/parser/*.so; do
    [[ -e "$dir" ]] && echo "parser $(basename "$dir" .so) $(stat -f %m "$dir")"
  done
  for dir in "$NVIM_DATA"/mason/packages/*/; do
    [[ -d "$dir" ]] && echo "server $(basename "$dir")"
  done
  return 0
}

count() { # <n> <thing>
  if (($1 == 1)); then echo "1 $2"; else echo "$1 $2s"; fi
}

# Sorted entries of one kind (plugin, parser, server) from nvim_state output
entries() { # <kind> <state> [names]
  if [[ "${3:-}" == names ]]; then
    { grep "^$1 " <<<"$2" || true; } | cut -d' ' -f2 | sort
  else
    { grep "^$1 " <<<"$2" || true; } | sort
  fi
}

# "3 plugins installed, 1 parser updated" from two nvim_state outputs
nvim_changes() {
  local kind label added updated removed parts=() part out=""

  for kind in plugin parser server; do
    case "$kind" in
      plugin) label="plugin" ;;
      parser) label="parser" ;;
      server) label="Mason package" ;;
    esac
    added="$(comm -13 <(entries "$kind" "$1" names) <(entries "$kind" "$2" names) | wc -l | tr -d ' ')"
    removed="$(comm -23 <(entries "$kind" "$1" names) <(entries "$kind" "$2" names) | wc -l | tr -d ' ')"
    updated="$(comm -13 <(entries "$kind" "$1") <(entries "$kind" "$2") | wc -l | tr -d ' ')"
    updated=$((updated - added))
    ((added > 0)) && parts+=("$(count "$added" "$label") installed")
    ((updated > 0)) && parts+=("$(count "$updated" "$label") updated")
    ((removed > 0)) && parts+=("$(count "$removed" "$label") removed")
  done
  for part in ${parts[@]+"${parts[@]}"}; do
    out="${out:+$out, }$part"
  done
  echo "$out"
}

neovim() {
  if ! command -v nvim >/dev/null 2>&1; then
    $DRY_RUN || failed "Neovim is missing"
    return 0
  fi
  local version minor
  version="$(nvim --version | sed -n 's/^NVIM v//p')"
  minor="$(cut -d. -f2 <<<"$version")"
  if [[ "$version" == 0.* ]] && ((minor < 12)); then
    if $DRY_RUN; then
      note "Neovim $version is too old for this config; the Homebrew upgrade above takes care of it"
    else
      failed "Neovim $version is too old for this config (needs 0.12 or newer)"
    fi
    return 0
  fi
  if $DRY_RUN; then
    note "would bring Neovim's plugins (to the lockfile), parsers and Mason packages up to date"
    return 0
  fi

  info "Neovim: plugins, parsers and language servers"
  # Mason's servers install with npm; parsers build with tree-sitter and cc
  command -v fnm >/dev/null 2>&1 && fnm use --silent-if-unchanged default
  local before after summary
  before="$(nvim_state)"
  # Plugins are public: clone over HTTPS even where ~/.gitconfig sends GitHub
  # through SSH, which fails (or hangs) without a key loaded in the agent
  if (cd "$HOME" && GIT_CONFIG_GLOBAL=/dev/null env -u NVIM_APPNAME nvim --headless "+luafile $DOTFILES_DIR/script/nvim-sync.lua"); then
    after="$(nvim_state)"
    summary="$(nvim_changes "$before" "$after")"
    [[ -z "$summary" ]] || changed "Neovim: $summary"
  else
    failed "Neovim sync failed (see above)"
  fi

  local copilot="$HOME/.config/github-copilot" # auth.db now, *.json in older versions
  if [[ ! -s "$copilot/auth.db" && ! -s "$copilot/apps.json" && ! -s "$copilot/hosts.json" ]]; then
    MANUAL+=("Sign in to Copilot: in Neovim press ,al (starts Copilot), then run :LspCopilotSignIn")
  fi
}

# --- iTerm2 ---------------------------------------------------------------------------

# Marks every prompt, so iTerm2 can jump between commands, select a command's
# output and tell you when one finishes. It changes with iTerm2, so it's
# fetched each run and replaced when it differs
iterm_shell_integration() {
  local dest="$HOME/.iterm2_shell_integration.zsh" latest
  latest="$(mktemp)"
  if ! curl -fsSL --max-time 30 https://iterm2.com/shell_integration/zsh -o "$latest"; then
    rm -f "$latest"
    failed "Couldn't download iTerm2's shell integration"
    return 0
  fi
  if [[ ! -f "$dest" ]]; then
    run cp "$latest" "$dest"
    changed "install iTerm2 shell integration"
  elif ! cmp -s "$latest" "$dest"; then
    run cp "$latest" "$dest"
    changed "update iTerm2 shell integration"
  fi
  rm -f "$latest"
}

iterm() {
  [[ -d /Applications/iTerm.app ]] || return 0
  iterm_shell_integration
}

# --- Run ---------------------------------------------------------------------------------

$DRY_RUN && note "Dry run: nothing is changed"
info "Dotfiles: $(tilde "$DOTFILES_DIR")"
homebrew
dotfiles
node_lts
retired_tools
old_neovim
neovim
iterm

if grep -q 'install font-hack-nerd-font' <<<"${CHANGES[*]:-}"; then
  MANUAL+=("iTerm2: Settings › Profiles › Text › Font: Hack Nerd Font")
fi

echo
if ((${#CHANGES[@]} == 0)); then
  info "Everything is up to date"
else
  info "$($DRY_RUN && echo 'Would change' || echo 'Changed'):"
  printf '  - %s\n' "${CHANGES[@]}"
  if ! $DRY_RUN && grep -qE 'link ~/.zshrc|\.zprofile|\.zshenv' <<<"${CHANGES[*]}"; then
    MANUAL+=("Open a new terminal (or run: exec zsh) for the shell changes")
  fi
fi
if [[ -d "$BACKUP_DIR" ]]; then
  note "Files that were replaced are in $(tilde "$BACKUP_DIR")"
fi
if ((${#MANUAL[@]} > 0)); then
  note "Left for you:"
  printf '  - %s\n' "${MANUAL[@]}"
fi
if ((${#FAILED[@]} > 0)); then
  warn "Not everything worked:"
  printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi
