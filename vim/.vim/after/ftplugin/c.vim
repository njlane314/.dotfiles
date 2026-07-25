" Shared C and C++ buffer settings. Vim's stock C++ ftplugin sources the C
" ftplugin first, so this after-ftplugin is the common configuration point.

if exists('b:did_dotfiles_c_ftplugin')
  finish
endif
let b:did_dotfiles_c_ftplugin = 1

setlocal colorcolumn=100

compiler gcc
setlocal makeprg=make

let b:dotfiles_compile_cmd = (&l:filetype ==# 'cpp'
      \ ? 'c++ -std=gnu++20' : 'cc -std=c17')
      \ . ' -Wall -Wextra -Wpedantic -Wconversion -Wshadow -O2'

function! s:build_current_file() abort
  update
  let l:source = expand('%:p')
  let l:output = fnamemodify(l:source, ':r')
  execute '!' . b:dotfiles_compile_cmd . ' '
        \ . shellescape(l:source, 1) . ' -o ' . shellescape(l:output, 1)
endfunction

nnoremap <buffer> <leader>m :make<CR>
nnoremap <buffer> <leader>b :call <SID>build_current_file()<CR>
nnoremap <buffer> <leader>x :execute '!' . shellescape(fnamemodify(expand('%:p'), ':r'), 1)<CR>

let s:undo = 'setlocal colorcolumn< makeprg< errorformat<'
      \ . ' | silent! execute "nunmap <buffer> <leader>m"'
      \ . ' | silent! execute "nunmap <buffer> <leader>b"'
      \ . ' | silent! execute "nunmap <buffer> <leader>x"'
      \ . ' | unlet! b:current_compiler b:did_dotfiles_c_ftplugin '
      \ . 'b:dotfiles_compile_cmd'
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '')
      \ . (empty(get(b:, 'undo_ftplugin', '')) ? '' : ' | ')
      \ . s:undo
unlet s:undo
