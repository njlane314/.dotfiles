set nomore

function! s:assert(condition, message) abort
  if !a:condition
    echom 'Vim Codeforces check failed: ' . a:message
    cquit 1
  endif
endfunction

call s:assert(index(['yes', 'yes:2'], &signcolumn) >= 0,
      \ 'the sign column is not persistent')
call s:assert(maparg('jk', 'i') ==# '', 'jk still leaves insert mode')
call s:assert(g:ctrlp_map ==# '<leader>p', 'CtrlP mapping is not plugin-owned')
call s:assert(
      \ g:ctrlp_user_command
      \ ==# ['.git', 'cd %s && git ls-files -co --exclude-standard'],
      \ 'CtrlP does not use the Git-aware file list')
call s:assert(&undodir ==# $XDG_STATE_HOME . '/vim/undo//',
      \ 'persistent undo escaped XDG_STATE_HOME')
call s:assert(&backupdir ==# $XDG_CACHE_HOME . '/vim/backup//',
      \ 'backup files escaped XDG_CACHE_HOME')
call s:assert(&directory ==# $XDG_CACHE_HOME . '/vim/swap//',
      \ 'swap files escaped XDG_CACHE_HOME')
call s:assert($PATH ==# $DOTFILES_ORIGINAL_PATH,
      \ 'Vim changed the global PATH')

let s:clangd = executable('/opt/homebrew/opt/llvm/bin/clangd')
      \ ? '/opt/homebrew/opt/llvm/bin/clangd'
      \ : executable('/usr/local/opt/llvm/bin/clangd')
      \ ? '/usr/local/opt/llvm/bin/clangd'
      \ : executable('/home/linuxbrew/.linuxbrew/opt/llvm/bin/clangd')
      \ ? '/home/linuxbrew/.linuxbrew/opt/llvm/bin/clangd'
      \ : 'clangd'
let s:clang_format = executable('/opt/homebrew/opt/llvm/bin/clang-format')
      \ ? '/opt/homebrew/opt/llvm/bin/clang-format'
      \ : executable('/usr/local/opt/llvm/bin/clang-format')
      \ ? '/usr/local/opt/llvm/bin/clang-format'
      \ : executable('/home/linuxbrew/.linuxbrew/opt/llvm/bin/clang-format')
      \ ? '/home/linuxbrew/.linuxbrew/opt/llvm/bin/clang-format'
      \ : 'clang-format'
call s:assert(g:ale_c_clangd_executable ==# s:clangd,
      \ 'ALE C clangd executable is wrong')
call s:assert(g:ale_cpp_clangd_executable ==# s:clangd,
      \ 'ALE C++ clangd executable is wrong')
call s:assert(g:ale_c_clangformat_executable ==# s:clang_format,
      \ 'ALE clang-format executable is wrong')
call s:assert(g:ale_c_clangformat_use_global,
      \ 'ALE may ignore the configured clang-format executable')
call s:assert(maparg(' rn', 'n') ==# ':ALERename<CR>',
      \ 'ALE rename is not mapped to <leader>rn')

execute 'edit ' . fnameescape($DOTFILES_CF_ROOT
      \ . '/problems/cf/71/A/solution.cpp')
call s:assert(get(b:, 'current_compiler', '') ==# 'gcc',
      \ 'C++ did not load :compiler gcc')
call s:assert(maparg(' b', 'n') ==# '',
      \ 'generic single-file build leaked into a solution buffer')
call s:assert(&l:makeprg =~# '/bin/probs', 'makeprg does not use probs')
silent make
call s:assert(v:shell_error == 0, ':make failed')

call append('$', '// update must save this line')
call feedkeys("\<Space>r", 'xt')
call s:assert(v:shell_error == 0, '<leader>r failed')
call s:assert(!&modified, '<leader>r did not update the buffer')
call feedkeys("\<Space>R", 'xt')
call s:assert(v:shell_error == 0, '<leader>R failed')
call feedkeys("\<Space>B", 'xt')
call s:assert(v:shell_error == 0, '<leader>B failed')

let $DOTFILES_CF_FAIL = '1'
call feedkeys("\<Space>r", 'xt')
call s:assert(v:shell_error == 7,
      \ '<leader>r masked the repository command failure')
let $DOTFILES_CF_FAIL = '0'

set filetype=text
call s:assert(maparg(' r', 'n') ==# '',
      \ 'Codeforces mapping leaked after changing filetype')
call s:assert(!exists('b:probs_executable'),
      \ 'probs executable leaked after changing filetype')
call s:assert(!exists('b:dotfiles_compile_cmd'),
      \ 'generic compiler command leaked after changing filetype')
call s:assert(&l:textwidth == 0,
      \ 'C++ textwidth leaked after changing filetype')
execute 'edit ' . fnameescape($DOTFILES_CF_ROOT . '/solutions/B.72.cpp')
call feedkeys("\<Space>r", 'xt')
call s:assert(v:shell_error == 0, 'legacy <leader>r failed')

execute 'edit ' . fnameescape($DOTFILES_CF_ROOT . '/tools/utility.cpp')
call s:assert(maparg(' r', 'n') ==# '',
      \ 'workbench implementation source received probs mappings')
call s:assert(&l:makeprg ==# 'make',
      \ 'generic C++ makeprg was replaced by probs')

qall!
