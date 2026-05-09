" ~/.vimrc

set nocompatible

let mapleader = " "

" ------------------------------------------------------------------
" Tool paths
" ------------------------------------------------------------------
for s:tool_dir in ['/opt/homebrew/opt/llvm/bin', '/usr/local/opt/llvm/bin']
  if isdirectory(s:tool_dir) && stridx(':' . $PATH . ':', ':' . s:tool_dir . ':') < 0
    let $PATH = s:tool_dir . ':' . $PATH
  endif
endfor
unlet! s:tool_dir

" ------------------------------------------------------------------
" Plugins
" ------------------------------------------------------------------
let s:vim_plug = expand('~/.vim/autoload/plug.vim')

if filereadable(s:vim_plug)
  call plug#begin('~/.vim/plugged')

  Plug 'tpope/vim-sensible'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-commentary'
  Plug 'airblade/vim-gitgutter'
  Plug 'ctrlpvim/ctrlp.vim'
  Plug 'dense-analysis/ale'

  call plug#end()
endif

" ------------------------------------------------------------------
" Core
" ------------------------------------------------------------------
filetype plugin indent on
syntax enable

set encoding=utf-8
set hidden
set mouse=a

set number
set relativenumber
set ruler
set showcmd
set laststatus=2

set splitright
set splitbelow
set scrolloff=8
set sidescrolloff=8
set signcolumn=yes

set wildmenu
set wildmode=longest:full,full

if exists('+termguicolors')
  set termguicolors
endif

" ------------------------------------------------------------------
" Search
" ------------------------------------------------------------------
set ignorecase
set smartcase
set incsearch
set hlsearch

nnoremap <silent> <leader><space> :nohlsearch<CR>

" ------------------------------------------------------------------
" Indentation defaults
" ------------------------------------------------------------------
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smartindent

" ------------------------------------------------------------------
" Undo, backup, swap
" ------------------------------------------------------------------
set undofile
set undodir=~/.vim/undo//

set backup
set backupdir=~/.vim/backup//

set directory=~/.vim/swap//

" ------------------------------------------------------------------
" Clipboard
" ------------------------------------------------------------------
if has('clipboard')
  set clipboard^=unnamedplus
endif

" ------------------------------------------------------------------
" Completion
" ------------------------------------------------------------------
set completeopt=menuone,noselect

" ------------------------------------------------------------------
" Mappings
" ------------------------------------------------------------------
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <leader>e :Explore<CR>
nnoremap <leader>p :CtrlP<CR>

nnoremap <leader>n :cnext<CR>
nnoremap <leader>N :cprevious<CR>
nnoremap <leader>c :copen<CR>

inoremap jk <Esc>

nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" ------------------------------------------------------------------
" ALE: C / C++ linting, LSP, and formatting
" ------------------------------------------------------------------
let g:ale_linters_explicit = 1

let g:ale_linters = {
\   'c': ['clangd'],
\   'cpp': ['clangd'],
\}

let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'c': ['clang-format'],
\   'cpp': ['clang-format'],
\}

let g:ale_fix_on_save = 0

let g:ale_completion_enabled = 1
let g:ale_completion_autoimport = 1

let g:ale_c_clangd_options = '--enable-config'
let g:ale_cpp_clangd_options = '--enable-config'

let g:ale_c_clangtidy_options = '--extra-arg=-std=c17'
let g:ale_cpp_clangtidy_options = '--extra-arg=-std=c++20'

" Diagnostics navigation
nnoremap <leader>d :ALEDetail<CR>
nnoremap <leader>f :ALEFix<CR>
nnoremap <leader>r :ALERename<CR>
nnoremap <leader>a :ALECodeAction<CR>
nnoremap <leader>gd :ALEGoToDefinition<CR>
nnoremap <leader>gr :ALEFindReferences<CR>
nnoremap <leader>gh :ALEHover<CR>
nnoremap [d :ALEPrevious<CR>
nnoremap ]d :ALENext<CR>
