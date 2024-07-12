source script/log.sh

function setup_osx() {
  if ! command -v gh &> /dev/null
  then
    info "Installing GitHub CLI..."
    # Install GitHub CLI
    brew install gh
    version=$(gh version)
    info "GitHub CLI ${version} installed"
  else
    note "$(gh version | grep "gh version") is already installed"
  fi

  if ! command -v rg &> /dev/null
  then
    info "Install ripgrep..."
    brew install ripgrep
    info "ripgrep installed"
  else
    note "$(rg --version | grep ripgrep) is already installed"
  fi

  if ! command -v nvim &> /dev/null
  then
    info "Installing neovim..."
    brew install neovim
    info "neovim installed"
    info "Setup .vim folders"
    mkdir -p "${HOME}/.vim" "${HOME}/.vim/autoload" "${HOME}/.vim/backup" "${HOME}/.vim/colors" "${HOME}/.vim/plugged"
    info "Get colorscheme"
    curl -o "${HOME}/.vim/colors/solarized8_high.vim" https://raw.githubusercontent.com/lifepillar/vim-solarized8/master/colors/solarized8_high.vim
    info "Prepare for init.lua"
    mkdir -p "${HOME}/.config/nvim"
    info "Install Plug"
    curl -fLo "${HOME}/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  else
    note "$(nvim --version | grep "NVIM") is already installed"
  fi

  if ! command -v starship &> /dev/null
  then
    info "Installing starship..."
    brew install starship
    info "Starship installed"

    info "Symlink Starship config"
    ln -sf "${DOTFILES_DIR}/dotfiles/config/starship.toml" "${HOME}/.config/starship.toml"

  else
    note "$(starship --version | grep "starship") is already installed"
  fi

  if ! command -v tig &> /dev/null
  then
    info "Installing tig..."
    brew install tig
    info "tig installed"
  else
    note "$(tig --version | grep "tig") is already installed"
  fi

  info "Symlink .zshrc"
  ln -sf "${DOTFILES_DIR}/dotfiles/zshrc" "${HOME}/.zshrc"

  info "Symlink z folder jumper"
  ln -sf "${DOTFILES_DIR}/dotfiles/z.sh" "${HOME}/z.sh"

  if ! command -v hg &> /dev/null
  then
    info "Installing mercurial for gvm..."
    brew install mercurial
  else
    note "$(hg --version | grep "Mercurial") is already installed"
  fi

  if ! command -v go &> /dev/null
  then
    info "Installing go using brew to get around gvm bootstrapping problem..."
    brew install go
  else
    note "$(go version) is already installed"
  fi

  info "Installing tokyonight-storm color theme for iTerm"
  curl -o "${HOME}/Downloads" https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/schemes/tokyonight-storm.itermcolors

  if ! [ -f "${HOME}/Library/Fonts/HackNerdFont-Regular.ttf" ]
  then
    info "Installing Nerd Font"
    brew tap homebrew/cask-fonts
    brew install --cask font-hack-nerd-font
  else
    note "Nerd Font already installed"
  fi

  if ! [ -f "${HOME}/.iterm2_shell_integration.zsh" ]
  then
    info "Installing iTerm2 shell integration"
    curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh
  else
    note "iTerm2 Shell Integration is already installed"
  fi

  echo ""
  note "Open iterm2 profiles > Text and select Hack Nerd Font"
  note "*** --->>> Import iTerm2 settings from Dropbox <<<--- ***"
  echo ""
}
