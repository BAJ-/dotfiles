export LANG=en_GB.UTF-8
export LC_MESSAGES=en_GB.UTF-8

. ~/z.sh
eval "$(starship init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[[ -s "/Users/bjornjohansen/.gvm/scripts/gvm" ]] && source "/Users/bjornjohansen/.gvm/scripts/gvm"

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

  if [ -n $TEST_FILE ]; then
    FILE_PATH=$(find . -name "$TEST_FILE" -exec sh -c 'echo "${0#./}"' {} \;)
    FILE_PATH=${FILE_PATH//.test/}
    npm run test --if-present $TEST_FILE -- --coverage --collectCoverageFrom=$FILE_PATH
  else
    echo 'No matching file name was found'
  fi
}

alias testfile=run_test_on_file

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
