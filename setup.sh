#!/usr/bin/env bash

source script/log.sh
source script/osx.sh
source script/linux.sh

mkdir -p "${HOME}/.config"

DOTFILES_DIR=$(cd $(dirname "$0")/.. && pwd)
info "Dotfiles directory: ${DOTFILES_DIR}"

# nvm is not loaded into this environment
if ! [ -f "${HOME}/.nvm/nvm.sh" ]
then
  info "Installing nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
  info "nvm installed"
else
  # load nvm
  . $HOME/.nvm/nvm.sh
  note "nvm $(nvm --version) is already installed"
fi

if ! command -v gvm &> /dev/null
then
  info "Installing gvm"
  zsh < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
  info "gvm installed"
else
  note "$(gvm version)"
fi

info "Symlink init.lua"
ln -sf "${DOTFILES_DIR}/dotfiles/init.lua" "${HOME}/.config/nvim/init.lua"
info "Symlink lua/"
ln -sfn "${DOTFILES_DIR}/dotfiles/lua" "${HOME}/.config/nvim/lua"
info "Symlink .vimrc"
ln -sf "${DOTFILES_DIR}/dotfiles/vimrc" "${HOME}/.vimrc"

if [ $CODESPACES ]
then
  setup_linux
fi

if [[ $OSTYPE == "darwin"* ]]
then
  setup_osx
fi
