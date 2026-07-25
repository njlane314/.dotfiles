" ~/.vim/after/ftplugin/cpp.vim

setlocal tabstop=4
setlocal shiftwidth=4
setlocal softtabstop=4
setlocal expandtab

setlocal cindent
setlocal colorcolumn=100
setlocal textwidth=100

setlocal makeprg=make
setlocal errorformat=%f:%l:%c:\ %m,%f:%l:\ %m

" C++-specific compiler flags for quick single-file builds.
let b:compile_cmd = 'c++ -std=c++20 -Wall -Wextra -Wpedantic -Wconversion -Wshadow -O2'

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

function! s:find_problem_root(path) abort
  let l:dir = fnamemodify(a:path, ':p:h')

  while !empty(l:dir)
    if filereadable(l:dir . '/bin/run')
          \ && filereadable(l:dir . '/bin/bundle')
          \ && filereadable(l:dir . '/template.cpp')
      return l:dir
    endif

    let l:parent = fnamemodify(l:dir, ':h')
    if l:parent ==# l:dir
      break
    endif
    let l:dir = l:parent
  endwhile

  return ''
endfunction

let s:current_file = expand('%:p')
let s:problem_root = s:find_problem_root(s:current_file)

let s:is_cf_buffer = !empty(s:problem_root)
      \ && stridx(s:current_file, s:problem_root . '/') == 0

if s:is_cf_buffer
  let b:problem_root = s:problem_root
  let b:ale_linters = ['clangd']
  let b:ale_c_build_dir = b:problem_root . '/build'
  let b:ale_cpp_clangd_options = '--enable-config'
  setlocal colorcolumn=
  execute 'setlocal makeprg=' . fnameescape(b:problem_root . '/bin/run') . '\ %:p'

  nnoremap <buffer> <silent> <leader>r :write<CR>:execute '!' . shellescape(b:problem_root . '/bin/run') . ' ' . shellescape(expand('%:p'))<CR>
  nnoremap <buffer> <silent> <leader>b :write<CR>:execute '!' . shellescape(b:problem_root . '/bin/bundle') . ' ' . shellescape(expand('%:p'))<CR>
  nnoremap <buffer> <leader>m :write<CR>:make<CR>
endif
