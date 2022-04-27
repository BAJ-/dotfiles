source script/log.sh

function setup_osx() {
  if [ -f /usr/local/bin/gh ]; then
    version=$(gh version)
    note "GitHub CLI ${version} is already installed"
  else
    info "Installing GitHub CLI..."
    # Install GitHub CLI
    brew install gh
    version=$(gh version)
    info "GitHub CLI ${version} installed"
  fi

  info "Install ripgrep..."
  brew install ripgrep
  info "ripgrep installed"
  
  if [ -f /usr/local/bin/nvim ]; then
    version=$(nvim --version | grep "NVIM")
    note "${version} is already installed"
  else
    info "Installing neovim..."
    brew install neovim
    info "neovim installed"
    info "Setup .vim folders"
    mkdir -p "${HOME}/.vim" "${HOME}/.vim/autoload" "${HOME}/.vim/backup" "${HOME}/.vim/colors" "${HOME}/.vim/plugged"
    info "Get colorscheme"
    curl -o "${HOME}/.vim/colors/zengarden.vim" https://raw.githubusercontent.com/tobi-wan-kenobi/zengarden/main/colors/zengarden.vim
    info "Prepare for init.lua"
    mkdir -p "${HOME}/.config/nvim"
    info "Symlink init.lua"
    ln -s "${DOTFILES_DIR}/init.lua" "${HOME}/.config/nvim/init.lua"
    info "Symlink .vimrc"
    ln -s "${DOTFILES_DIR}/vimrc" "${HOME}/.vimrc"
    info "Install Plug"
    curl -fLo "${HOME}/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi
}
