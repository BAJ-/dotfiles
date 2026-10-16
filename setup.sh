#!/usr/bin/env bash

source script/log.sh
source script/osx.sh
source script/linux.sh

mkdir -p "${HOME}/.config"

DOTFILES_DIR=$(cd $(dirname "$0")/.. && pwd)
info "Dotfiles directory: ${DOTFILES_DIR}"

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
