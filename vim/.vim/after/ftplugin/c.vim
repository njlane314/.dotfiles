" ~/.vim/after/ftplugin/c.vim

setlocal tabstop=4
setlocal shiftwidth=4
setlocal softtabstop=4
setlocal expandtab

setlocal cindent
setlocal colorcolumn=100
setlocal textwidth=100

setlocal makeprg=make
setlocal errorformat=%f:%l:%c:\ %m,%f:%l:\ %m

" C-specific compiler flags for quick single-file builds.
let b:compile_cmd = 'cc -std=c17 -Wall -Wextra -Wpedantic -Wconversion -Wshadow -O2'

function! s:build_current_file() abort
  let l:source = expand('%:p')
  let l:output = fnamemodify(l:source, ':r')
  execute '!' . b:compile_cmd . ' ' . shellescape(l:source, 1) . ' -o ' . shellescape(l:output, 1)
endfunction

function! s:run_current_file() abort
  execute '!' . shellescape(fnamemodify(expand('%:p'), ':r'), 1)
endfunction

command! -buffer DotfilesBuild call <SID>build_current_file()
command! -buffer DotfilesRun call <SID>run_current_file()

nnoremap <buffer> <leader>m :make<CR>
nnoremap <buffer> <leader>b :DotfilesBuild<CR>
nnoremap <buffer> <leader>x :DotfilesRun<CR>
