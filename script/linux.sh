source script/log.sh

function setup_linux() {
  # Always use ZSH as default shell
  if [ -f /bin/zsh ]; then
    info "Setting default shell to ZSH"
    # Change default shell to ZSH
    sudo chsh -s /bin/zsh $(whoami)
  else
    info "Installing ZSH..."
    # Install ZSH
    apt-get install -y zsh

    info "Setting default shell to ZSH"
    # Change default shell to ZSH
    chsh -s /bin/zsh $(whoami)
  fi


  if [ -f /usr/local/bin/gh ]; then
    version=$(gh version)
    note "GitHub CLI ${version} is already installed"
  else
    info "Installing GitHub CLI..."
    # Install GitHub CLI
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh
    version=$(gh version)
    info "GitHub CLI ${version} installed"
  fi


  if [ -f /usr/local/bin/nvim ]; then
    version=$(nvim --version | grep "NVIM")
    note "${version} is already installed"
  else
    info "Installing neovim..."
    curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -o nvim.appimage
    chmod u+x nvim.appimage
    ./nvim.appimage --appimage-extract
    sudo ln -s "${DOTFILES_DIR}/dotfiles/squashfs-root/AppRun" "/usr/bin/nvim"
    info "neovim installed"
    info "Setup .vim folders"
    mkdir -p "${HOME}/.vim" "${HOME}/.vim/autoload" "${HOME}/.vim/backup" "${HOME}/.vim/colors" "${HOME}/.vim/plugged"
    info "Get colorscheme"
    curl -o "${HOME}/.vim/colors/solarized8_high.vim" https://raw.githubusercontent.com/lifepillar/vim-solarized8/master/colors/solarized8_high.vim
    info "Prepare for init.lua"
    mkdir -p "${HOME}/.config/nvim"
    info "Symlink init.lua"
    ln -s "${DOTFILES_DIR}/dotfiles/init.lua" "${HOME}/.config/nvim/init.lua"
    info "Symlink .vimrc"
    ln -s "${DOTFILES_DIR}/dotfiles/vimrc" "${HOME}/.vimrc"
    info "Install Plug"
    curl -fLo "${HOME}/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi

  if [ -f /usr/local/bin/starship ]; then
    version=$(starship --version | grep "starship")
    note "${version} is already installed"
  else
    info "Installing starship..."
    # Do something
    info "Starship installed"
  fi

  
  info "Installing less and vim..."
  # Install less and vim
  sudo apt-get install -y less vim
  info "Done installing less and vim"
}
