export LANG=en_GB.UTF-8
export LC_MESSAGES=en_GB.UTF-8

# Nested shells (e.g. Neovim's terminal) would otherwise keep re-adding PATH entries
typeset -U path PATH

[ -f ~/z.sh ] && . ~/z.sh
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# Node via fnm: the nearest .nvmrc/.node-version wins, else fnm's default.
# Custom hook because fnm's --use-on-cd can't install missing versions.
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --version-file-strategy=recursive --shell zsh)"
  _fnm_use_project_node() { fnm use --silent-if-unchanged --install-if-missing; }
  autoload -U add-zsh-hook
  add-zsh-hook chpwd _fnm_use_project_node
  _fnm_use_project_node
fi

run_test_on_file() {
  TEST_FILE=''
  if [[ $1 =~ ^[A-Z][a-zA-Z]*\.test.(ts|tsx)$ ]]; then
    TEST_FILE=$1
  else
    PASTE_BUFFER=$(pbpaste)
    if [[ $PASTE_BUFFER =~ ^[A-Z][a-zA-Z]*\.test.(ts|tsx)$ ]]; then
      TEST_FILE=$PASTE_BUFFER
    else
      echo 'No matching file name was found'
    fi
  fi

  if [ -n "$TEST_FILE" ]; then
    FILE_PATH=$(find . -name "$TEST_FILE" -exec sh -c 'echo "${0#./}"' {} \;)
    FILE_PATH=${FILE_PATH//.test/}
    npm run test --if-present $TEST_FILE -- --coverage --collectCoverageFrom=$FILE_PATH
  else
    echo 'No matching file name was found'
  fi
}

alias testfile=run_test_on_file

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

export PATH="$HOME/.gum/bin:$PATH"
if [ -x "$HOME/.local/bin/mise" ]; then
  # fnm owns Node; stop mise from putting a second node on PATH
  command -v fnm >/dev/null 2>&1 && export MISE_DISABLE_TOOLS="${MISE_DISABLE_TOOLS:+$MISE_DISABLE_TOOLS,}node"
  eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
if [ -d "$HOME/Library/Android/sdk" ]; then
  export ANDROID_HOME=$HOME/Library/Android/sdk
  export PATH=$PATH:$ANDROID_HOME/emulator
  export PATH=$PATH:$ANDROID_HOME/platform-tools
fi
if [ -d /opt/homebrew/opt/openjdk@17 ]; then
  export JAVA_HOME=/opt/homebrew/opt/openjdk@17
  export PATH="$JAVA_HOME/bin:$PATH"
fi
