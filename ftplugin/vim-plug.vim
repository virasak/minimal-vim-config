" vim-plug ftplugin file
" Language:     Vim-Plug
" Maintainer:   Junegunn Choi <https://github.com/junegunn>
" Last Change:  2024 May

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

let s:save_cpo = &cpo
set cpo&vim

" Extract plugin name from line
function! s:extract_name(str, prefix, suffix)
  return matchstr(a:str, '^'.a:prefix.' \zs[^:]\+\ze:.*'.a:suffix.'$')
endfunction

" Update selected plugins
function! s:status_update() range
  let lines = getline(a:firstline, a:lastline)
  let names = filter(map(lines, 's:extract_name(v:val, "[x-]", "")'), '!empty(v:val)')
  if !empty(names)
    echo
    execute 'PlugUpdate' join(names)
  endif
endfunction

" Buffer settings
setlocal buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile nowrap cursorline modifiable nospell
if exists('+colorcolumn')
  setlocal colorcolumn=
endif

" Key mappings
nnoremap <silent> <buffer> q :bd<cr>
nnoremap <silent> <buffer> R  :PlugRetry<cr>
nnoremap <silent> <buffer> D  :PlugDiff<cr>
nnoremap <silent> <buffer> S  :PlugStatus<cr>
nnoremap <silent> <buffer> U  :call <SID>status_update()<cr>
xnoremap <silent> <buffer> U  :call <SID>status_update()<cr>
nnoremap <silent> <buffer> ]] :silent! call plug#section('')<cr>
nnoremap <silent> <buffer> [[ :silent! call plug#section('b')<cr>

let &cpo = s:save_cpo
unlet s:save_cpo
