source script/log.sh

function setup_linux() {
  # Always use ZSH as default shell
  if [ -f /bin/zsh ]; then
    info "Setting default shell to ZSH"
    # Change default shell to ZSH
    chsh -s /bin/zsh $(whoami)
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
    sudo apt-get install -y neovim
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

  
  info "Installing less and vim..."
  # Install less and vim
  sudo apt-get install -y less vim
  info "Done installing less and vim"
}
