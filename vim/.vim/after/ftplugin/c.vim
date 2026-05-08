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

nnoremap <buffer> <leader>m :make<CR>
nnoremap <buffer> <leader>b :execute '!'.b:compile_cmd.' % -o %:r'<CR>
nnoremap <buffer> <leader>x :execute '!./%:r'<CR>
