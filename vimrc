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

" More natural split with vsp and sp
set splitbelow
set splitright

" Auto save when switching buffers
:set autowriteall
:au FocusLost * silent! wa

" When insetting comments, align them to the left
let g:NERDDefaultAlign = 'left'

" PLUGINS ---------------------------------------------------------------- {{{
" ALE linting settings
let g:ale_linters = {
\  'json': ['jq'],
\  'javascript': ['eslint', 'tsserver'],
\  'javascriptreact': ['eslint', 'tsserver'],
\  'typescript': ['eslint', 'tsserver'],
\  'typescriptreact': ['eslint', 'tsserver'],
\}
let g:ale_json_jq_executable = 'jq'
let g:ale_json_jq_options = '.'
let g:ale_fixers = {
\  'javascript': ['prettier', 'eslint'],
\  'javascriptreact': ['prettier', 'eslint'],
\  'typescript': ['prettier', 'eslint'],
\  'typescriptreact': ['prettier', 'eslint'],
\}
" Auto fix on save
let g:ale_fix_on_save = 1

" Install Plug if it's not already
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" Linting while you type
Plug 'dense-analysis/ale'
" Better syntax highlighting
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
" Lua functions and required for telescoep.nvim to work
Plug 'nvim-lua/plenary.nvim'
" Fuzzy finder
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-live-grep-args.nvim'
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
Plug 'rebelot/kanagawa.nvim'
" Neotest
" Plug 'nvim-lua/plenary.nvim'
" Plug 'nvim-treesitter/nvim-treesitter'
Plug 'antoinemadec/FixCursorHold.nvim'
Plug 'nvim-neotest/nvim-nio'
Plug 'nvim-neotest/neotest'
" Neotest-jest
Plug 'nvim-neotest/neotest-jest'

call plug#end()

" }}}


" MAPPINGS --------------------------------------------------------------- {{{
" Set comma as the leader key.
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
" nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>fr <cmd>Telescope resume<cr>

" Nvim tree mappings
nnoremap <leader>tt :NvimTreeToggle<CR>
nnoremap <leader>r :NvimTreeRefresh<CR>
nnoremap <leader>n :NvimTreeFindFile<CR>

" Terminal
nnoremap <leader>tm :terminal<CR>
:tnoremap <Esc> <C-\><C-n>

" Hop mappings
nnoremap <leader>ja :HopAnywhere<CR>
nnoremap <leader>jw :HopWord<CR>

" Buffer mappings
nnoremap <leader>bk :bp\|bd! #<CR>
nnoremap <leader>bh :hide<CR>

" Tabs
nnoremap <leader>tc :tabnew<CR>
nnoremap <leader>tn :tabnext<CR>
nnoremap <leader>tp :tabprev<CR>
" }}}

" ALE Linting
nnoremap <leader>en :ALENextWrap<CR>zz
nnoremap <leader>ep :ALEPreviousWrap<CR>zz
nnoremap <leader>ed :ALEDetail<CR>
" ALE code
nnoremap <leader>cr :ALEFindReferences -relative<CR>
nnoremap <leader>cd :ALEGoToDefinition<CR>
nnoremap <leader>ct :ALEGoToTypeDefinition<CR>

nnoremap <leader>fn :let @+ = expand('%:t')<CR>

"Remove all trailing whitespace by pressing F5
nnoremap <F5> :let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar><CR>
" VIMSCRIPT -------------------------------------------------------------- {{{

" This will enable code folding.
" Use the marker method of folding.
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END


" }}}

