" ~/.vim/after/ftplugin/cpp.vim

if exists('b:did_dotfiles_cpp_ftplugin')
  finish
endif
let b:did_dotfiles_cpp_ftplugin = 1

function! s:find_solution_root(path) abort
  let l:dir = fnamemodify(a:path, ':p:h')

  while !empty(l:dir)
    if executable(l:dir . '/bin/probs')
          \ && filereadable(l:dir . '/templates/solution.cpp')
      let l:relative = strpart(a:path, strlen(l:dir) + 1)
      return l:relative =~# '^solutions/[A-Za-z][A-Za-z0-9]*\.[0-9]\+\.cpp$'
            \ || l:relative
            \ =~# '^problems/cf/[0-9]\+/[A-Za-z][A-Za-z0-9]*/solution\.cpp$'
            \ ? l:dir : ''
    endif

    let l:parent = fnamemodify(l:dir, ':h')
    if l:parent ==# l:dir
      break
    endif
    let l:dir = l:parent
  endwhile

  return ''
endfunction

function! s:probs_command(arguments, makeprg) abort
  let l:arguments = [b:probs_executable]
        \ + a:arguments
        \ + [expand('%:p')]
  if a:makeprg
    return join(map(l:arguments,
          \ {_, argument -> escape(shellescape(argument), '%#')}), ' ')
  endif
  return join(map(
        \ l:arguments, {_, argument -> shellescape(argument, 1)}), ' ')
endfunction

function! s:run_problem(arguments) abort
  update
  execute '!' . s:probs_command(a:arguments, 0)
endfunction

let s:solution_root = s:find_solution_root(expand('%:p'))

if !empty(s:solution_root)
  let b:probs_executable = s:solution_root . '/bin/probs'
  setlocal colorcolumn=
  let &l:makeprg = s:probs_command(['test'], 1)

  silent! nunmap <buffer> <leader>m
  silent! nunmap <buffer> <leader>b
  silent! nunmap <buffer> <leader>x

  nnoremap <buffer> <silent> <leader>r :call <SID>run_problem(['test'])<CR>
  nnoremap <buffer> <silent> <leader>R :call <SID>run_problem(['test', '--checked'])<CR>
  nnoremap <buffer> <silent> <leader>B :call <SID>run_problem(['bundle'])<CR>

  let b:undo_ftplugin .=
        \ ' | silent! execute "nunmap <buffer> <leader>r"'
        \ . ' | silent! execute "nunmap <buffer> <leader>R"'
        \ . ' | silent! execute "nunmap <buffer> <leader>B"'
        \ . ' | unlet! b:probs_executable'
endif

let b:undo_ftplugin .= ' | unlet! b:did_dotfiles_cpp_ftplugin'
