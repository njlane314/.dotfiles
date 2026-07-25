set nomore

function! s:assert(condition, message) abort
  if !a:condition
    echom 'Vim config check failed: ' . a:message
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
call s:assert(g:ale_virtualtext_cursor ==# 'disabled',
      \ 'ALE virtual diagnostic text is enabled')
call s:assert(!g:ale_hover_cursor,
      \ 'ALE hover still appears automatically')

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

execute 'edit ' . fnameescape($DOTFILES_VIM_HOME . '/project/main.cpp')
call s:assert(get(b:, 'current_compiler', '') ==# 'gcc',
      \ 'C++ did not load :compiler gcc')
call s:assert(&l:makeprg ==# 'make', 'C++ makeprg is not make')
call s:assert(maparg(' b', 'n') !=# '',
      \ 'the C++ single-file build mapping is missing')
call s:assert(&l:textwidth == 0,
      \ 'C++ comments are wrapped automatically')
call s:assert(&l:shiftwidth == 4,
      \ 'EditorConfig did not apply the C++ indentation')

set filetype=text
call s:assert(maparg(' b', 'n') ==# '',
      \ 'the C++ build mapping leaked after changing filetype')
call s:assert(!exists('b:dotfiles_compile_cmd'),
      \ 'the C++ compiler command leaked after changing filetype')

execute 'edit ' . fnameescape($DOTFILES_VIM_HOME . '/project/data.json')
call s:assert(&l:expandtab && &l:shiftwidth == 2,
      \ 'EditorConfig did not apply JSON indentation')

execute 'edit ' . fnameescape($DOTFILES_VIM_HOME . '/project/base.mk')
call s:assert(!&l:expandtab,
      \ 'EditorConfig did not preserve Make recipe tabs')

qall!
