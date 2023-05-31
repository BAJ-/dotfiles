#!/usr/bin/env bash

source script/log.sh
source script/osx.sh
source script/linux.sh

mkdir -p "${HOME}/.config"

DOTFILES_DIR=$(cd $(dirname "$0")/.. && pwd)
info "Dotfiles directory: ${DOTFILES_DIR}"

if [ $CODESPACES ]; then
  setup_linux
fi

if [[ $OSTYPE == "darwin"* ]]; then
  setup_osx

  info "Symlink Starship config"
  ln -s "${DOTFILES_DIR}/dotfiles/config/starship.toml" "${HOME}/.config/starship.toml"

  info "Symlink .zshrc"
  ln -s "${DOTFILES_DIR}/dotfiles/zshrc" "${HOME}/.zshrc"

  info "Symlink z folder jumper"
  ln -s "${DOTFILES_DIR}/dotfiles/z.sh" "${HOME}/z.sh"
fi

info "Installing nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
info "nvm installed"

info "Symlink init.lua"
ln -s "${DOTFILES_DIR}/dotfiles/init.lua" "${HOME}/.config/nvim/init.lua"
inro "Symlink lua/"
ln -s "${DOTFILES_DIR}/dotfiles/lua" "${HOME}/.config/nvim/lua"
info "Symlink .vimrc"
ln -s "${DOTFILES_DIR}/dotfiles/vimrc" "${HOME}/.vimrc"

