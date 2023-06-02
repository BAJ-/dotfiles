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
    info "Install Plug"
    curl -fLo "${HOME}/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi

  if [ -f /usr/local/bin/starship ]; then
    version=$(starship --version | grep "starship")
    note "${version} is already installed"
  else
    info "Installing starship..."
    brew install starship
    info "Starship installed"

    info "Symlink Starship config"
    ln -s "${DOTFILES_DIR}/dotfiles/config/starship.toml" "${HOME}/.config/starship.toml"

    info "Installing Nerd Font"
    brew tap homebrew/cask-fonts
    brew install --cask font-hack-nerd-font
    note "Open iterm2 profiles > Text and select Hack Nerd Font"
  fi

  if [ -f /usr/local/bin/tig ]; then
    version=$(tig --version | grep "tig")
    note "${version} is already installed"
  else
    info "Installing tig..."
    brew install tig
    info "tig installed"
  fi

  info "Symlink .zshrc"
  ln -s "${DOTFILES_DIR}/dotfiles/zshrc" "${HOME}/.zshrc"

  info "Symlink z folder jumper"
  ln -s "${DOTFILES_DIR}/dotfiles/z.sh" "${HOME}/z.sh"

  info "Installing mercurial for gvm..."
  brew install mercurial

  info "Installing go using brew to get around gvm bootstrapping problem..."
  brew install go

  info "Installing tokyonight-storm color theme for iTerm"
  curl -o "${HOME}/Documents" https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/schemes/tokyonight-storm.itermcolors
  note "Open iterm2 profiles > Colors > Color Presets... and click import. The theme is in the /Documents folder"
}
