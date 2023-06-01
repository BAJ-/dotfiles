"                °|██╔╝ ██║██║ ╚═╝ ██║██║  ██║╚██████╗
"                 ╰═══╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝
"               
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Disable compatibility with vi which can cause unexpected issues
set nocompatible

" Copy to clipboard
set clipboard+=unnamedplus

" Enable type file detection
filetype on

" Enable and load plugin for the detected file type
filetype plugin on

" Load an indent file for the detected file type.
filetype indent on

" Turn syntax highlighting on
syntax on

" Add line numbers
set number

" Highlight cursor horizontally
set cursorline

" Set shift width to 2
set shiftwidth=2

" Set tab width to 2
set tabstop=2

" Use space characters instead of tabs
set expandtab

" Do not save backup files
set nobackup

" Do not wrap lines
set nowrap

" Highlight search matches as you type
set incsearch

" Show matching words during a search
set showmatch

" Use highlighting when doing a search
set hlsearch

" Ignore capital letters during search
set ignorecase

" Override the ignorecase option if searching for capital letters
set smartcase

" Show partial command you type in the last line of the screen
set showcmd

" Show the mode you are on the last line.
set showmode

" Set command history
set history=1000

" Nvim tree
let g:nvim_tree_indent_markers = 1 "0 by default, this option shows indent markers when folders are open
let g:nvim_tree_git_hl = 1 "0 by default, will enable file highlight for git attributes (can be used without the icons).
let g:nvim_tree_highlight_opened_files = 1 "0 by default, will enable folder and file icon highlight for opened files/directories.
let g:nvim_tree_root_folder_modifier = ':~' "This is the default. See :help filename-modifiers for more options
let g:nvim_tree_add_trailing = 1 "0 by default, append a trailing slash to folder names
let g:nvim_tree_group_empty = 1 " 0 by default, compact folders that only contain a single folder into one node in the file tree
let g:nvim_tree_icon_padding = ' ' "one space by default, used for rendering the space between the icon and the filename. Use with caution, it could break rendering if you set an empty string depending on your font.
let g:nvim_tree_symlink_arrow = ' >> ' " defaults to ' ➛ '. used as a separator between symlinks' source and target.
let g:nvim_tree_respect_buf_cwd = 1 "0 by default, will change cwd of nvim-tree to that of new buffer's when opening nvim-tree.
let g:nvim_tree_create_in_closed_folder = 1 "0 by default, When creating files, sets the path of a file when cursor is on a closed folder to the parent folder when 0, and inside the folder when 1.
let g:nvim_tree_special_files = { 'README.md': 1, 'Makefile': 1, 'MAKEFILE': 1 } " List of filenames that gets highlighted with NvimTreeSpecialFile
let g:nvim_tree_show_icons = {
    \ 'git': 1,
    \ 'folders': 1,
    \ 'files': 0,
    \ 'folder_arrows': 1,
    \ }
"If 0, do not show the icons for one of 'git' 'folder' and 'files'
"1 by default, notice that if 'files' is 1, it will only display
"if nvim-web-devicons is installed and on your runtimepath.
"if folder is 1, you can also tell folder_arrows 1 to show small arrows next to the folder icons.
"but this will not work when you set indent_markers (because of UI conflict)

" default will show icon by default if no icon is provided
" default shows no icon by default
let g:nvim_tree_icons = {
    \ 'default': "",
    \ 'symlink': "",
    \ 'git': {
    \   'unstaged': "✗",
    \   'staged': "✓",
    \   'unmerged': "",
    \   'renamed': "➜",
    \   'untracked': "★",
    \   'deleted': "",
    \   'ignored': "◌"
    \   },
    \ 'folder': {
    \   'arrow_open': "",
    \   'arrow_closed': "",
    \   'default': "",
    \   'open': "",
    \   'empty': "",
    \   'empty_open': "",
    \   'symlink': "",
    \   'symlink_open': "",
    \   }
    \ }

" highlight NvimTreeFolderIcon guibg=blue

" More natural split with vsp and sp
set splitbelow
set splitright

" Auto save when switching buffers
:set autowriteall
:au FocusLost * silent! wa

" When insetting comments, align them to the left
let g:NERDDefaultAlign = 'left'

" PLUGINS ---------------------------------------------------------------- {{{

" Install Plug if it's not already
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

Plug 'preservim/nerdtree'
" Linting while you type
Plug 'dense-analysis/ale'
" Better syntax highlighting
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
" Lua functions and required for telescoep.nvim to work
Plug 'nvim-lua/plenary.nvim'
" Fuzzy finder
Plug 'nvim-telescope/telescope.nvim'
" Nvim tree with icons
Plug 'kyazdani42/nvim-web-devicons' " for file icons
Plug 'kyazdani42/nvim-tree.lua'
" Jump to any part of the file
Plug 'phaazon/hop.nvim'
" Go plugin
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
" Mason, portalbe package manager for NVIM
Plug 'williamboman/mason.nvim'
" Mason Nvim Dap bridge
Plug 'mfussenegger/nvim-dap'
Plug 'jay-babu/mason-nvim-dap.nvim'
" Nice debugging UI
Plug 'rcarriga/nvim-dap-ui'
" Notify, a nice tool to send notifications in Nvim
Plug 'rcarriga/nvim-notify'
" Nvim Dap VSCode for good frontend debugging
Plug 'mxsdev/nvim-dap-vscode-js'
" NERD Comment
Plug 'preservim/nerdcommenter'
" Copilot
Plug 'github/copilot.vim'
" Color
Plug 'folke/tokyonight.nvim'

call plug#end()

let NERDTreeShowHidden=1

" }}}


" MAPPINGS --------------------------------------------------------------- {{{
" Set the backslash as the leader key.
let mapleader = ","

" Split mapping
nnoremap <leader>sv <cmd>vsp<cr>
nnoremap <leader>sh <cmd>sp<cr>

" Panel navigation mappings
nnoremap <leader>j <C-W><C-J>
nnoremap <leader>k <C-W><C-K>
nnoremap <leader>l <C-W><C-L>
nnoremap <leader>h <C-W><C-H>

" Type jj quickly to exit insert  mode
inoremap jj <Esc>

" Pres the space bare to type the : character in command mode
nnoremap <space> :

" Center the cursor vertically when moving to the next word during search
nnoremap n nzz
nnoremap N Nzz

" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" Nvim tree mappings
nnoremap <leader>tt :NvimTreeToggle<CR>
nnoremap <leader>r :NvimTreeRefresh<CR>
nnoremap <leader>n :NvimTreeFindFile<CR>

" Terminal
nnoremap <leader>t :terminal<CR>
nnoremap <leader>th :hide<CR>
:tnoremap <Esc> <C-\><C-n>

" Hop mappings
nnoremap <leader>ja :HopAnywhere<CR>
nnoremap <leader>jw :HopWord<CR>

" Buffer mappings
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bl :ls<CR>

" Tabs
nnoremap <leader>tc :tabnew<CR>
nnoremap <leader>tn :tabnext<CR>
nnoremap <leader>tp :tabprev<CR>
" }}}



" VIMSCRIPT -------------------------------------------------------------- {{{

" This will enable code folding.
" Use the marker method of folding.
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END


" }}}


" STATUS LINE ------------------------------------------------------------ {{{

" Status bar code goes here.

" }}}
