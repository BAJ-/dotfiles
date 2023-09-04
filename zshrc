. ~/z.sh
eval "$(starship init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[[ -s "/Users/bjornjohansen/.gvm/scripts/gvm" ]] && source "/Users/bjornjohansen/.gvm/scripts/gvm"

run_test_on_file() {
  TEST_FILE=$(pbpaste)
  FILE_PATH=$(find . -name "$TEST_FILE" -exec sh -c 'echo "${0#./}"' {} \;)
  FILE_PATH=${FILE_PATH//.test/}
  npm run test $TEST_FILE -- --coverage --collectCoverageFrom=$FILE_PATH
}

alias testfile=run_test_on_file
