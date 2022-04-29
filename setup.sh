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
fi

