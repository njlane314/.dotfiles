" ~/.vimrc

set nocompatible

let mapleader = " "

" ------------------------------------------------------------------
" Runtime paths
" ------------------------------------------------------------------
function! s:xdg_home(value, fallback) abort
  return a:value =~# '^/' ? a:value : expand(a:fallback)
endfunction

let s:vim_data_home = s:xdg_home($XDG_DATA_HOME, '~/.local/share')
let s:vim_state_home = s:xdg_home($XDG_STATE_HOME, '~/.local/state')
let s:vim_cache_home = s:xdg_home($XDG_CACHE_HOME, '~/.cache')

let s:vim_data_dir = s:vim_data_home . '/vim'
let s:vim_state_dir = s:vim_state_home . '/vim'
let s:vim_cache_dir = s:vim_cache_home . '/vim'
let s:vim_plug = s:vim_data_dir . '/autoload/plug.vim'
let s:vim_plugin_dir = s:vim_data_dir . '/plugged'

for s:runtime_dir in [
      \ fnamemodify(s:vim_plug, ':h'),
      \ s:vim_plugin_dir,
      \ s:vim_state_dir . '/undo',
      \ s:vim_cache_dir . '/backup',
      \ s:vim_cache_dir . '/swap',
      \]
  if !isdirectory(s:runtime_dir)
    call mkdir(s:runtime_dir, 'p', 0700)
  endif
endfor
unlet! s:runtime_dir

" ------------------------------------------------------------------
" Plugins
" ------------------------------------------------------------------
if filereadable(s:vim_plug)
  execute 'source ' . fnameescape(s:vim_plug)
  call plug#begin(s:vim_plugin_dir)

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
silent! set signcolumn=yes:2
if &signcolumn !=# 'yes:2'
  set signcolumn=yes
endif
set timeoutlen=400
set ttimeoutlen=50

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
let &undodir = s:vim_state_dir . '/undo//'

set backup
let &backupdir = s:vim_cache_dir . '/backup//'

let &directory = s:vim_cache_dir . '/swap//'

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

nnoremap <leader>n :cnext<CR>
nnoremap <leader>N :cprevious<CR>
nnoremap <leader>c :copen<CR>

nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Keep ignored build output out of CtrlP's file list.
let g:ctrlp_map = '<leader>p'
let g:ctrlp_user_command = [
\   '.git',
\   'cd %s && git ls-files -co --exclude-standard',
\]
let g:ctrlp_use_caching = 0

" ------------------------------------------------------------------
" ALE: C / C++ linting, LSP, and formatting
" ------------------------------------------------------------------
function! s:llvm_tool(name) abort
  for l:directory in [
        \ '/opt/homebrew/opt/llvm/bin',
        \ '/usr/local/opt/llvm/bin',
        \ '/home/linuxbrew/.linuxbrew/opt/llvm/bin',
        \]
    let l:candidate = l:directory . '/' . a:name
    if executable(l:candidate)
      return l:candidate
    endif
  endfor

  return a:name
endfunction

let g:ale_linters_explicit = 1
let g:ale_virtualtext_cursor = 'disabled'
let g:ale_hover_cursor = 0

let g:ale_linters = {
\   'c': ['clangd'],
\   'cpp': ['clangd'],
\}

let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'c': ['clang-format'],
\   'cpp': ['clang-format'],
\}

let g:ale_completion_enabled = 1

let g:ale_c_clangd_options = '--enable-config'
let g:ale_cpp_clangd_options = g:ale_c_clangd_options

let g:ale_c_clangd_executable = s:llvm_tool('clangd')
let g:ale_cpp_clangd_executable = g:ale_c_clangd_executable
let g:ale_c_clangformat_executable = s:llvm_tool('clang-format')
let g:ale_c_clangformat_use_global = 1

" Diagnostics navigation
nnoremap <leader>d :ALEDetail<CR>
nnoremap <leader>f :ALEFix<CR>
nnoremap <leader>rn :ALERename<CR>
nnoremap <leader>a :ALECodeAction<CR>
nnoremap <leader>gd :ALEGoToDefinition<CR>
nnoremap <leader>gr :ALEFindReferences<CR>
nnoremap <leader>gh :ALEHover<CR>
nnoremap [d :ALEPrevious<CR>
nnoremap ]d :ALENext<CR>
