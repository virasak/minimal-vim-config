" vim-plug: Vim plugin manager
" ============================
"
" 1. Download plug.vim and put it in 'autoload' directory
"
"   # Vim
"   curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"
"   # Neovim
"   sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
"     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
"
" 2. Add a vim-plug section to your ~/.vimrc (or ~/.config/nvim/init.vim for Neovim)
"
"   call plug#begin()
"
"   " List your plugins here
"   Plug 'tpope/vim-sensible'
"
"   call plug#end()
"
" 3. Reload the file or restart Vim, then you can,
"
"     :PlugInstall to install plugins
"     :PlugUpdate  to update plugins
"     :PlugDiff    to review the changes from the last update
"     :PlugClean   to remove plugins no longer in the list
"
" For more information, see https://github.com/junegunn/vim-plug
"
"
" Copyright (c) 2024 Junegunn Choi
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

if exists('g:loaded_plug')
  finish
endif
let g:loaded_plug = 1

let s:cpo_save = &cpo
set cpo&vim

" vim-plug now requires Vim 9.0+ or Neovim 0.9+ and Git 2.0+ on Unix-like systems

let s:plug_src = 'https://github.com/junegunn/vim-plug.git'
let s:plug_tab = get(s:, 'plug_tab', -1)
let s:plug_buf = get(s:, 'plug_buf', -1)
let s:mac_gui = has('gui_macvim') && has('gui_running')
let s:me = resolve(expand('<sfile>:p'))
let s:base_spec = { 'branch': '', 'frozen': 0 }
let s:TYPE = {
\   'string':  type(''),
\   'list':    type([]),
\   'dict':    type({}),
\   'funcref': type(function('call'))
\ }
let s:loaded = get(s:, 'loaded', {})
let s:triggers = get(s:, 'triggers', {})

function! s:isabsolute(dir) abort
  return a:dir =~# '^/'
endfunction

function! s:plug_call(fn, ...)
  return call(a:fn, a:000)
endfunction

function! s:plug_getcwd()
  return s:plug_call('getcwd')
endfunction

function! s:plug_fnamemodify(fname, mods)
  return s:plug_call('fnamemodify', a:fname, a:mods)
endfunction

function! s:plug_expand(fmt)
  return s:plug_call('expand', a:fmt, 1)
endfunction

function! s:plug_tempname()
  return s:plug_call('tempname')
endfunction

function! plug#begin(...)
  if a:0 > 0
    let home = s:path(s:plug_fnamemodify(s:plug_expand(a:1), ':p'))
  elseif exists('g:plug_home')
    let home = s:path(g:plug_home)
  elseif !empty(&rtp)
    let home = s:path(split(&rtp, ',')[0]) . '/plugged'
  else
    return s:err('Unable to determine plug home. Try calling plug#begin() with a path argument.')
  endif
  if s:plug_fnamemodify(home, ':t') ==# 'plugin' && s:plug_fnamemodify(home, ':h') ==# s:first_rtp
    return s:err('Invalid plug home. '.home.' is a standard Vim runtime path and is not allowed.')
  endif

  let g:plug_home = home
  let g:plugs = {}
  let g:plugs_order = []
  let s:triggers = {}

  call s:define_commands()
  return 1
endfunction

function! s:define_commands()
  command! -nargs=+ -bar Plug call plug#(<args>)
  if !executable('git')
    return s:err('`git` executable not found. Most commands will not be available. To suppress this message, prepend `silent!` to `call plug#begin(...)`.')
  endif
  command! -nargs=* -bar -bang -complete=customlist,s:names PlugInstall call s:install(<bang>0, [<f-args>])
  command! -nargs=* -bar -bang -complete=customlist,s:names PlugUpdate  call s:update(<bang>0, [<f-args>])
  command! -nargs=0 -bar -bang PlugClean call s:clean(<bang>0)
  command! -nargs=0 -bar PlugUpgrade if s:upgrade() | execute 'source' s:esc(s:me) | endif
  command! -nargs=0 -bar PlugStatus  call s:status()
  command! -nargs=0 -bar PlugDiff    call s:diff()
  command! -nargs=? -bar -bang -complete=file PlugSnapshot call s:snapshot(<bang>0, <f-args>)
endfunction

function! s:to_a(v)
  return type(a:v) == s:TYPE.list ? a:v : [a:v]
endfunction

function! s:to_s(v)
  return type(a:v) == s:TYPE.string ? a:v : join(a:v, "\n") . "\n"
endfunction

function! s:glob(from, pattern)
  return s:lines(globpath(a:from, a:pattern))
endfunction

function! s:source(from, ...)
  let found = 0
  for pattern in a:000
    for vim in s:glob(a:from, pattern)
      execute 'source' s:esc(vim)
      let found = 1
    endfor
  endfor
  return found
endfunction

function! s:assoc(dict, key, val)
  let a:dict[a:key] = add(get(a:dict, a:key, []), a:val)
endfunction

function! s:ask(message, ...)
  call inputsave()
  echohl WarningMsg
  let answer = input(a:message.(a:0 ? ' (y/N/a) ' : ' (y/N) '))
  echohl None
  call inputrestore()
  echo "\r"
  return (a:0 && answer =~? '^a') ? 2 : (answer =~? '^y') ? 1 : 0
endfunction

function! s:ask_no_interrupt(...)
  try
    return call('s:ask', a:000)
  catch
    return 0
  endtry
endfunction

function! s:lazy(plug, opt)
  return has_key(a:plug, a:opt) &&
        \ (empty(s:to_a(a:plug[a:opt]))         ||
        \  !isdirectory(a:plug.dir)             ||
        \  len(s:glob(s:rtp(a:plug), 'plugin')) ||
        \  len(s:glob(s:rtp(a:plug), 'after/plugin')))
endfunction

function! plug#end()
  if !exists('g:plugs')
    return s:err('plug#end() called without calling plug#begin() first')
  endif

  if exists('#PlugLOD')
    augroup PlugLOD
      autocmd!
    augroup END
    augroup! PlugLOD
  endif
  let lod = { 'ft': {}, 'map': {}, 'cmd': {} }

  if get(g:, 'did_load_filetypes', 0)
    filetype off
  endif
  for name in g:plugs_order
    if !has_key(g:plugs, name)
      continue
    endif
    let plug = g:plugs[name]
    if get(s:loaded, name, 0) || !s:lazy(plug, 'on') && !s:lazy(plug, 'for')
      let s:loaded[name] = 1
      continue
    endif

    if has_key(plug, 'on')
      let s:triggers[name] = { 'map': [], 'cmd': [] }
      for cmd in s:to_a(plug.on)
        if cmd =~? '^<Plug>.\+'
          if empty(mapcheck(cmd)) && empty(mapcheck(cmd, 'i'))
            call s:assoc(lod.map, cmd, name)
          endif
          call add(s:triggers[name].map, cmd)
        elseif cmd =~# '^[A-Z]'
          let cmd = substitute(cmd, '!*$', '', '')
          if exists(':'.cmd) != 2
            call s:assoc(lod.cmd, cmd, name)
          endif
          call add(s:triggers[name].cmd, cmd)
        else
          call s:err('Invalid `on` option: '.cmd.
          \ '. Should start with an uppercase letter or `<Plug>`.')
        endif
      endfor
    endif

    if has_key(plug, 'for')
      let types = s:to_a(plug.for)
      if !empty(types)
        augroup filetypedetect
        call s:source(s:rtp(plug), 'ftdetect/**/*.vim', 'after/ftdetect/**/*.vim')
        " Lua support removed - Neovim not supported
        augroup END
      endif
      for type in types
        call s:assoc(lod.ft, type, name)
      endfor
    endif
  endfor

  for [cmd, names] in items(lod.cmd)
    execute printf(
    \ 'command! -nargs=* -range -bang -complete=file %s call s:lod_cmd(%s, "<bang>", <line1>, <line2>, <q-args>, <q-mods> ,%s)',
    \ cmd, string(cmd), string(names))
  endfor

  for [map, names] in items(lod.map)
    for [mode, map_prefix, key_prefix] in
          \ [['i', '<C-\><C-O>', ''], ['n', '', ''], ['v', '', 'gv'], ['o', '', '']]
      execute printf(
      \ '%snoremap <silent> %s %s:<C-U>call <SID>lod_map(%s, %s, %s, "%s")<CR>',
      \ mode, map, map_prefix, string(map), string(names), mode != 'i', key_prefix)
    endfor
  endfor

  for [ft, names] in items(lod.ft)
    augroup PlugLOD
      execute printf('autocmd FileType %s call <SID>lod_ft(%s, %s)',
            \ ft, string(ft), string(names))
    augroup END
  endfor

  call s:reorg_rtp()
  filetype plugin indent on
  if has('vim_starting')
    if has('syntax') && !exists('g:syntax_on')
      syntax enable
    end
  else
    call s:reload_plugins()
  endif
endfunction

function! s:loaded_names()
  return filter(copy(g:plugs_order), 'get(s:loaded, v:val, 0)')
endfunction

function! s:load_plugin(spec)
  call s:source(s:rtp(a:spec), 'plugin/**/*.vim', 'after/plugin/**/*.vim')
  " Lua support removed - Neovim not supported
endfunction

function! s:reload_plugins()
  for name in s:loaded_names()
    call s:load_plugin(g:plugs[name])
  endfor
endfunction

function! s:trim(str)
  return substitute(a:str, '[\/]\+$', '', '')
endfunction

function! s:version_requirement(val, min)
  for idx in range(0, len(a:min) - 1)
    let v = get(a:val, idx, 0)
    if     v < a:min[idx] | return 0
    elseif v > a:min[idx] | return 1
    endif
  endfor
  return 1
endfunction

function! s:progress_opt(base)
  return a:base ? '--progress' : ''
endfunction

function! s:rtp(spec)
  return s:path(a:spec.dir . get(a:spec, 'rtp', ''))
endfunction

function! s:path(path)
  return s:trim(a:path)
endfunction

function! s:dirpath(path)
  return substitute(a:path, '[/\\]*$', '/', '')
endfunction

function! s:is_local_plug(repo)
  return a:repo[0] =~ '[/$~]'
endfunction

function! s:err(msg)
  echohl ErrorMsg
  echom '[vim-plug] '.a:msg
  echohl None
endfunction

function! s:warn(cmd, msg)
  echohl WarningMsg
  execute a:cmd 'a:msg'
  echohl None
endfunction

function! s:esc(path)
  return escape(a:path, ' ')
endfunction

function! s:escrtp(path)
  return escape(a:path, ' ,')
endfunction

function! s:remove_rtp()
  for name in s:loaded_names()
    let rtp = s:rtp(g:plugs[name])
    execute 'set rtp-='.s:escrtp(rtp)
    let after = globpath(rtp, 'after')
    if isdirectory(after)
      execute 'set rtp-='.s:escrtp(after)
    endif
  endfor
endfunction

function! s:reorg_rtp()
  if !empty(s:first_rtp)
    execute 'set rtp-='.s:first_rtp
    execute 'set rtp-='.s:last_rtp
  endif

  " &rtp is modified from outside
  if exists('s:prtp') && s:prtp !=# &rtp
    call s:remove_rtp()
    unlet! s:middle
  endif

  let s:middle = get(s:, 'middle', &rtp)
  let rtps     = map(s:loaded_names(), 's:rtp(g:plugs[v:val])')
  let afters   = filter(map(copy(rtps), 'globpath(v:val, "after")'), '!empty(v:val)')
  let rtp      = join(map(rtps, 'escape(v:val, ",")'), ',')
                 \ . ','.s:middle.','
                 \ . join(map(afters, 'escape(v:val, ",")'), ',')
  let &rtp     = substitute(substitute(rtp, ',,*', ',', 'g'), '^,\|,$', '', 'g')
  let s:prtp   = &rtp

  if !empty(s:first_rtp)
    execute 'set rtp^='.s:first_rtp
    execute 'set rtp+='.s:last_rtp
  endif
endfunction

function! s:doautocmd(...)
  if exists('#'.join(a:000, '#'))
    execute 'doautocmd <nomodeline>' join(a:000)
  endif
endfunction

function! s:dobufread(names)
  for name in a:names
    let path = s:rtp(g:plugs[name])
    for dir in ['ftdetect', 'ftplugin', 'after/ftdetect', 'after/ftplugin']
      if len(finddir(dir, path))
        if exists('#BufRead')
          doautocmd BufRead
        endif
        return
      endif
    endfor
  endfor
endfunction

function! plug#load(...)
  if a:0 == 0
    return s:err('Argument missing: plugin name(s) required')
  endif
  if !exists('g:plugs')
    return s:err('plug#begin was not called')
  endif
  let names = a:0 == 1 && type(a:1) == s:TYPE.list ? a:1 : a:000
  let unknowns = filter(copy(names), '!has_key(g:plugs, v:val)')
  if !empty(unknowns)
    let s = len(unknowns) > 1 ? 's' : ''
    return s:err(printf('Unknown plugin%s: %s', s, join(unknowns, ', ')))
  end
  let unloaded = filter(copy(names), '!get(s:loaded, v:val, 0)')
  if !empty(unloaded)
    for name in unloaded
      call s:lod([name], ['ftdetect', 'after/ftdetect', 'plugin', 'after/plugin'])
    endfor
    call s:dobufread(unloaded)
    return 1
  end
  return 0
endfunction

function! s:remove_triggers(name)
  if !has_key(s:triggers, a:name)
    return
  endif
  for cmd in s:triggers[a:name].cmd
    execute 'silent! delc' cmd
  endfor
  for map in s:triggers[a:name].map
    execute 'silent! unmap' map
    execute 'silent! iunmap' map
  endfor
  call remove(s:triggers, a:name)
endfunction

function! s:lod(names, types, ...)
  for name in a:names
    call s:remove_triggers(name)
    let s:loaded[name] = 1
  endfor
  call s:reorg_rtp()

  for name in a:names
    let rtp = s:rtp(g:plugs[name])
    for dir in a:types
      call s:source(rtp, dir.'/**/*.vim')
      " Lua support removed - Neovim not supported
    endfor
    if a:0
      if !s:source(rtp, a:1) && !empty(s:glob(rtp, a:2))
        execute 'runtime' a:1
      endif
      call s:source(rtp, a:2)
    endif
    call s:doautocmd('User', name)
  endfor
endfunction

function! s:lod_ft(pat, names)
  let syn = 'syntax/'.a:pat.'.vim'
  call s:lod(a:names, ['plugin', 'after/plugin'], syn, 'after/'.syn)
  execute 'autocmd! PlugLOD FileType' a:pat
  call s:doautocmd('filetypeplugin', 'FileType')
  call s:doautocmd('filetypeindent', 'FileType')
endfunction

function! s:lod_cmd(cmd, bang, l1, l2, args, mods, names)
  call s:lod(a:names, ['ftdetect', 'after/ftdetect', 'plugin', 'after/plugin'])
  call s:dobufread(a:names)
  execute printf('%s %s%s%s %s', a:mods, (a:l1 == a:l2 ? '' : (a:l1.','.a:l2)), a:cmd, a:bang, a:args)
endfunction

function! s:lod_map(map, names, with_prefix, prefix)
  call s:lod(a:names, ['ftdetect', 'after/ftdetect', 'plugin', 'after/plugin'])
  call s:dobufread(a:names)
  let extra = ''
  while 1
    let c = getchar(0)
    if c == 0
      break
    endif
    let extra .= nr2char(c)
  endwhile

  if a:with_prefix
    let prefix = v:count ? v:count : ''
    let prefix .= '"'.v:register.a:prefix
    if mode(1) == 'no'
      if v:operator == 'c'
        let prefix = "\<esc>" . prefix
      endif
      let prefix .= v:operator
    endif
    call feedkeys(prefix, 'n')
  endif
  call feedkeys(substitute(a:map, '^<Plug>', "\<Plug>", '') . extra)
endfunction

function! plug#(repo, ...)
  if a:0 > 1
    return s:err('Invalid number of arguments (1..2)')
  endif

  try
    let repo = s:trim(a:repo)
    let opts = a:0 == 1 ? s:parse_options(a:1) : s:base_spec
    let name = get(opts, 'as', s:plug_fnamemodify(repo, ':t:s?\.git$??'))
    let spec = extend(s:infer_properties(name, repo), opts)
    if !has_key(g:plugs, name)
      call add(g:plugs_order, name)
    endif
    let g:plugs[name] = spec
    let s:loaded[name] = get(s:loaded, name, 0)
  catch
    return s:err(repo . ' ' . v:exception)
  endtry
endfunction

function! s:parse_options(arg)
  let opts = copy(s:base_spec)
  let type = type(a:arg)
  let opt_errfmt = 'Invalid argument for "%s" option of :Plug (expected: %s)'
  if type == s:TYPE.string
    if empty(a:arg)
      throw printf(opt_errfmt, 'tag', 'string')
    endif
    let opts.tag = a:arg
  elseif type == s:TYPE.dict
    for opt in ['branch', 'tag', 'commit', 'rtp', 'dir', 'as']
      if has_key(a:arg, opt)
      \ && (type(a:arg[opt]) != s:TYPE.string || empty(a:arg[opt]))
        throw printf(opt_errfmt, opt, 'string')
      endif
    endfor
    for opt in ['on', 'for']
      if has_key(a:arg, opt)
      \ && type(a:arg[opt]) != s:TYPE.list
      \ && (type(a:arg[opt]) != s:TYPE.string || empty(a:arg[opt]))
        throw printf(opt_errfmt, opt, 'string or list')
      endif
    endfor
    if has_key(a:arg, 'do')
      \ && type(a:arg.do) != s:TYPE.funcref
      \ && (type(a:arg.do) != s:TYPE.string || empty(a:arg.do))
        throw printf(opt_errfmt, 'do', 'string or funcref')
    endif
    call extend(opts, a:arg)
    if has_key(opts, 'dir')
      let opts.dir = s:dirpath(s:plug_expand(opts.dir))
    endif
  else
    throw 'Invalid argument type (expected: string or dictionary)'
  endif
  return opts
endfunction

function! s:infer_properties(name, repo)
  let repo = a:repo
  if s:is_local_plug(repo)
    return { 'dir': s:dirpath(s:plug_expand(repo)) }
  else
    if repo =~ ':'
      let uri = repo
    else
      if repo !~ '/'
        throw printf('Invalid argument: %s (implicit `vim-scripts'' expansion is deprecated)', repo)
      endif
      let fmt = get(g:, 'plug_url_format', 'https://git::@github.com/%s.git')
      let uri = printf(fmt, repo)
    endif
    return { 'dir': s:dirpath(g:plug_home.'/'.a:name), 'uri': uri }
  endif
endfunction

function! s:install(force, names)
  call s:update_impl(0, a:force, a:names)
endfunction

function! s:update(force, names)
  call s:update_impl(1, a:force, a:names)
endfunction

function! plug#helptags()
  if !exists('g:plugs')
    return s:err('plug#begin was not called')
  endif
  for spec in values(g:plugs)
    let docd = join([s:rtp(spec), 'doc'], '/')
    if isdirectory(docd)
      silent! execute 'helptags' s:esc(docd)
    endif
  endfor
  return 1
endfunction

" Syntax function is now in syntax/vim-plug.vim

" Function removed - only used for buffer UI

function! s:lines(msg)
  return split(a:msg, "[\r\n]")
endfunction

function! s:lastline(msg)
  return get(s:lines(a:msg), -1, '')
endfunction

function! s:new_window()
  execute get(g:, 'plug_window', '-tabnew')
endfunction

function! s:plug_window_exists()
  let buflist = tabpagebuflist(s:plug_tab)
  return !empty(buflist) && index(buflist, s:plug_buf) >= 0
endfunction

function! s:switch_in()
  if !s:plug_window_exists()
    return 0
  endif

  if winbufnr(0) != s:plug_buf
    let s:pos = [tabpagenr(), winnr(), winsaveview()]
    execute 'normal!' s:plug_tab.'gt'
    let winnr = bufwinnr(s:plug_buf)
    execute winnr.'wincmd w'
    call add(s:pos, winsaveview())
  else
    let s:pos = [winsaveview()]
  endif

  setlocal modifiable
  return 1
endfunction

function! s:switch_out(...)
  call winrestview(s:pos[-1])
  setlocal nomodifiable
  if a:0 > 0
    execute a:1
  endif

  if len(s:pos) > 1
    execute 'normal!' s:pos[0].'gt'
    execute s:pos[1] 'wincmd w'
    call winrestview(s:pos[2])
  endif
endfunction

function! s:finish_bindings()
  " Key mappings are now in ftplugin/vim-plug.vim
endfunction

function! s:prepare(...)
  if empty(s:plug_getcwd())
    throw 'Invalid current working directory. Cannot proceed.'
  endif

  for evar in ['$GIT_DIR', '$GIT_WORK_TREE']
    if exists(evar)
      throw evar.' detected. Cannot proceed.'
    endif
  endfor

  call s:job_abort(0)

  " Use dialog UI
  return 1
endfunction

function! s:close_pane()
  if b:plug_preview == 1
    pc
    let b:plug_preview = -1
  elseif exists('s:jobs') && !empty(s:jobs)
    call s:job_abort(1)
  else
    bd
  endif
endfunction

function! s:assign_name()
  " Assign buffer name
  let prefix = '[Plugins]'
  let name   = prefix
  let idx    = 2
  while bufexists(name)
    let name = printf('%s (%s)', prefix, idx)
    let idx = idx + 1
  endwhile
  silent! execute 'f' fnameescape(name)
endfunction

function! s:chsh(swap)
  let prev = [&shell, &shellcmdflag, &shellredir]
  set shell=sh
  if a:swap
    set shellredir=>%s\ 2>&1
  endif
  return prev
endfunction

function! s:bang(cmd, ...)
  try
    let [sh, shellcmdflag, shrd] = s:chsh(a:0)
    let cmd = a:0 ? s:with_cd(a:cmd, a:1) : a:cmd
    let g:_plug_bang = '!'.escape(cmd, '#!%')
    execute "normal! :execute g:_plug_bang\<cr>\<cr>"
  finally
    unlet g:_plug_bang
    let [&shell, &shellcmdflag, &shellredir] = [sh, shellcmdflag, shrd]
  endtry
  return v:shell_error ? 'Exit status: ' . v:shell_error : ''
endfunction

" Function removed - only used for buffer UI

" Git functions moved to autoload/plug/git.vim

function! s:do(pull, force, todo)
  for [name, spec] in items(a:todo)
    if !isdirectory(spec.dir)
      continue
    endif
    let installed = has_key(s:update.new, name)
    let updated = installed ? 0 :
      \ (a:pull && index(s:update.errors, name) < 0 && s:is_updated(spec.dir))
    if a:force || installed || updated
      execute 'cd' s:esc(spec.dir)
      call append(3, '- Post-update hook for '. name .' ... ')
      let error = ''
      let type = type(spec.do)
      if type == s:TYPE.string
        if spec.do[0] == ':'
          if !get(s:loaded, name, 0)
            let s:loaded[name] = 1
            call s:reorg_rtp()
          endif
          call s:load_plugin(spec)
          try
            execute spec.do[1:]
          catch
            let error = v:exception
          endtry
          if !s:plug_window_exists()
            cd -
            throw 'Warning: vim-plug was terminated by the post-update hook of '.name
          endif
        else
          let error = s:bang(spec.do)
        endif
      elseif type == s:TYPE.funcref
        try
          call s:load_plugin(spec)
          let status = installed ? 'installed' : (updated ? 'updated' : 'unchanged')
          call spec.do({ 'name': name, 'status': status, 'force': a:force })
        catch
          let error = v:exception
        endtry
      else
        let error = 'Invalid hook type'
      endif
      " Check if we're using dialog UI
      if exists('*popup_create') && plug#dialog#is_open()
        " Update the dialog
        let status = empty(error) ? 'done' : 'error'
        let message = empty(error) ? 'Post-update hook: OK' : 'Post-update hook: ' . error
        call plug#dialog#update_plugin(name, status, message)
      else
        " Fall back to buffer UI
        call s:switch_in()
        call setline(4, empty(error) ? (getline(4) . 'OK')
                                   \ : ('x' . getline(4)[1:] . error))
      endif

      if !empty(error)
        call add(s:update.errors, name)
      endif
      cd -
    endif
  endfor
endfunction

" Git functions moved to autoload/plug/git.vim

function! s:finish(pull)
  let new_frozen = len(filter(keys(s:update.new), 'g:plugs[v:val].frozen'))
  if new_frozen
    let s = new_frozen > 1 ? 's' : ''
    call append(3, printf('- Installed %d frozen plugin%s', new_frozen, s))
  endif
  call append(3, '- Finishing ... ') | 4
  redraw
  call plug#helptags()
  call plug#end()
  call setline(4, getline(4) . 'Done!')
  redraw
  let msgs = []
  if !empty(s:update.errors)
    call add(msgs, "Press 'R' to retry.")
  endif
  if a:pull && len(s:update.new) < len(filter(getline(5, '$'),
                \ "v:val =~ '^- ' && v:val !~# 'Already up.to.date'"))
    call add(msgs, "Press 'D' to see the updated changes.")
  endif
  echo join(msgs, ' ')
  call s:finish_bindings()
endfunction

function! s:retry()
  if empty(s:update.errors)
    return
  endif
  echo
  call s:update_impl(s:update.pull, s:update.force,
        \ extend(copy(s:update.errors), [s:update.threads]))
endfunction

function! plug#retry()
  call s:retry()
endfunction

function! s:is_managed(name)
  return has_key(g:plugs[a:name], 'uri')
endfunction

function! s:names(...)
  return sort(filter(keys(g:plugs), 'stridx(v:val, a:1) == 0 && s:is_managed(v:val)'))
endfunction

function! s:update_impl(pull, force, args) abort
  let sync = index(a:args, '--sync') >= 0 || has('vim_starting')
  let args = filter(copy(a:args), 'v:val != "--sync"')
  let threads = (len(args) > 0 && args[-1] =~ '^[1-9][0-9]*$') ?
                  \ remove(args, -1) : get(g:, 'plug_threads', 16)

  let managed = filter(deepcopy(g:plugs), 's:is_managed(v:key)')
  let todo = empty(args) ? filter(managed, '!v:val.frozen || !isdirectory(v:val.dir)') :
                         \ filter(managed, 'index(args, v:key) >= 0')

  if empty(todo)
    return s:warn('echo', 'No plugin to '. (a:pull ? 'update' : 'install'))
  endif

  let s:git_terminal_prompt = exists('$GIT_TERMINAL_PROMPT') ? $GIT_TERMINAL_PROMPT : ''
  let $GIT_TERMINAL_PROMPT = 0
  for plug in values(todo)
    let plug.uri = substitute(plug.uri,
          \ '^https://git::@github\.com', 'https://github.com', '')
  endfor

  if !isdirectory(g:plug_home)
    try
      call mkdir(g:plug_home, 'p')
    catch
      return s:err(printf('Invalid plug directory: %s. '.
              \ 'Try to call plug#begin with a valid directory', g:plug_home))
    endtry
  endif


  let s:update = {
    \ 'start':   reltime(),
    \ 'all':     todo,
    \ 'todo':    copy(todo),
    \ 'errors':  [],
    \ 'pull':    a:pull,
    \ 'force':   a:force,
    \ 'new':     {},
    \ 'threads': min([len(todo), threads]),
    \ 'bar':     '',
    \ 'fin':     0
  \ }

  " Prepare for update - this now returns 1 for dialog UI
  if s:prepare(1)
    " Create dialog UI
    let title = a:pull ? 'Updating Plugins' : 'Installing Plugins'
    call plug#dialog#new(title, a:pull ? 'update' : 'install', todo, function('s:dialog_finished'))
  endif

  " Set remote name, overriding a possible user git config's clone.defaultRemoteName
  let s:clone_opt = ['--origin', 'origin']
  if get(g:, 'plug_shallow', 1)
    call extend(s:clone_opt, ['--depth', '1'])
    call add(s:clone_opt, '--no-single-branch')
  endif

  if has('win32unix') || has('wsl')
    call extend(s:clone_opt, ['-c', 'core.eol=lf', '-c', 'core.autocrlf=input'])
  endif

  let s:submodule_opt = ' --jobs='.threads

  " Start the update process
  call s:update_vim()

  " For synchronous updates with buffer UI, wait for completion
  if sync && !exists('*popup_create')
    while !s:update.fin
      sleep 100m
    endwhile
  endif
endfunction

" Callback when dialog is finished
function! s:dialog_finished(result)
  " Handle any cleanup needed after dialog is closed
  if exists('s:git_terminal_prompt')
    let $GIT_TERMINAL_PROMPT = s:git_terminal_prompt
  endif

  " Show summary if needed
  let elapsed = split(reltimestr(reltime(s:update.start)))[0]
  let message = 'Finished. Elapsed time: ' . elapsed . ' sec.'

  if !empty(s:update.errors)
    let message .= ' Errors: ' . len(s:update.errors)
  endif

  " Show a notification popup for a more modern UI experience
  let notify_type = !empty(s:update.errors) ? 'error' : 'normal'
  call plug#dialog#notify(message, notify_type)

  " Schedule a command to be executed after this function returns
  " This prevents the message from leaking into the current buffer
  call timer_start(10, {-> execute('echomsg "[vim-plug] ' . escape(message, '"') . '"', '')})

  if exists('#PlugPost')
    doautocmd PlugPost
  endif
endfunction

" Function removed - only used for buffer UI

function! s:update_finish()
  if exists('s:git_terminal_prompt')
    let $GIT_TERMINAL_PROMPT = s:git_terminal_prompt
  endif

  " Check if we're using dialog UI
  if exists('*popup_create') && plug#dialog#is_open()
    " Process any remaining tasks in dialog UI
    for [name, spec] in items(filter(copy(s:update.all), 'index(s:update.errors, v:key) < 0 && (s:update.force || s:update.pull || has_key(s:update.new, v:key))'))
      let out = ''
      let error = 0
      if has_key(spec, 'commit')
        call plug#dialog#update_plugin(name, 'update', 'Checking out '.spec.commit)
        let [out, error] = s:checkout(spec)
      elseif has_key(spec, 'tag')
        let tag = spec.tag
        if tag =~ '\*'
          let tags = s:lines(s:system('git tag --list '.plug#shellescape(tag).' --sort -version:refname 2>&1', spec.dir))
          if !v:shell_error && !empty(tags)
            let tag = tags[0]
            call plug#dialog#update_plugin(name, 'update', printf('Latest tag for %s -> %s', spec.tag, tag))
          endif
        endif
        call plug#dialog#update_plugin(name, 'update', 'Checking out '.tag)
        let out = s:system('git checkout -q '.plug#shellescape(tag).' -- 2>&1', spec.dir)
        let error = v:shell_error
      endif
      if !error && filereadable(spec.dir.'/.gitmodules') &&
            \ (s:update.force || has_key(s:update.new, name) || s:is_updated(spec.dir))
        call plug#dialog#update_plugin(name, 'update', 'Updating submodules. This may take a while.')
        let out .= s:bang('git submodule update --init --recursive'.s:submodule_opt.' 2>&1', spec.dir)
        let error = v:shell_error
      endif

      " Update status in dialog
      let status = error ? 'error' : 'done'
      let message = error ? out : (!empty(out) ? s:lastline(out) : 'Done')
      call plug#dialog#update_plugin(name, status, message)

      if error
        call add(s:update.errors, name)
      endif
    endfor

    try
      call s:do(s:update.pull, s:update.force, filter(copy(s:update.all), 'index(s:update.errors, v:key) < 0 && has_key(v:val, "do")'))
    catch
      call timer_start(10, {-> execute('echomsg "[vim-plug] '.escape(v:exception, '"').'"', '')})
      return
    endtry

    " Mark as finished
    let s:update.fin = 1
    return
  endif

  " Fall back to buffer UI
  if s:switch_in()
    call append(3, '- Updating ...') | 4
    for [name, spec] in items(filter(copy(s:update.all), 'index(s:update.errors, v:key) < 0 && (s:update.force || s:update.pull || has_key(s:update.new, v:key))'))
      let [pos, _] = s:logpos(name)
      if !pos
        continue
      endif
      let out = ''
      let error = 0
      if has_key(spec, 'commit')
        call s:log4(name, 'Checking out '.spec.commit)
        let [out, error] = s:checkout(spec)
      elseif has_key(spec, 'tag')
        let tag = spec.tag
        if tag =~ '\*'
          let tags = s:lines(s:system('git tag --list '.plug#shellescape(tag).' --sort -version:refname 2>&1', spec.dir))
          if !v:shell_error && !empty(tags)
            let tag = tags[0]
            call s:log4(name, printf('Latest tag for %s -> %s', spec.tag, tag))
            call append(3, '')
          endif
        endif
        call s:log4(name, 'Checking out '.tag)
        let out = s:system('git checkout -q '.plug#shellescape(tag).' -- 2>&1', spec.dir)
        let error = v:shell_error
      endif
      if !error && filereadable(spec.dir.'/.gitmodules') &&
            \ (s:update.force || has_key(s:update.new, name) || s:is_updated(spec.dir))
        call s:log4(name, 'Updating submodules. This may take a while.')
        let out .= s:bang('git submodule update --init --recursive'.s:submodule_opt.' 2>&1', spec.dir)
        let error = v:shell_error
      endif
      let msg = s:format_message(v:shell_error ? 'x': '-', name, out)
      if error
        call add(s:update.errors, name)
        call s:regress_bar()
        silent execute pos 'd _'
        call append(4, msg) | 4
      elseif !empty(out)
        call setline(pos, msg[0])
      endif
      redraw
    endfor
    silent 4 d _
    try
      call s:do(s:update.pull, s:update.force, filter(copy(s:update.all), 'index(s:update.errors, v:key) < 0 && has_key(v:val, "do")'))
    catch
      call s:warn('echom', v:exception)
      call s:warn('echo', '')
      return
    endtry
    call s:finish(s:update.pull)
    call setline(1, 'Updated. Elapsed time: ' . split(reltimestr(reltime(s:update.start)))[0] . ' sec.')
    call s:switch_out('normal! gg')
  endif
endfunction

function! s:mark_aborted(name, message)
  let attrs = { 'running': 0, 'error': 1, 'abort': 1, 'lines': [a:message] }
  let s:jobs[a:name] = extend(get(s:jobs, a:name, {}), attrs)
endfunction

function! s:job_abort(cancel)
  if !exists('s:jobs')
    let s:jobs = {}
  endif

  for [name, j] in items(s:jobs)
    silent! call job_stop(j.jobid)
    if j.new
      call s:rm_rf(g:plugs[name].dir)
    endif
    if a:cancel
      call s:mark_aborted(name, 'Aborted')
    endif
  endfor

  if a:cancel
    for todo in values(s:update.todo)
      let todo.abort = 1
    endfor
  else
    let s:jobs = {}
  endif
endfunction

function! s:last_non_empty_line(lines)
  let len = len(a:lines)
  for idx in range(len)
    let line = a:lines[len-idx-1]
    if !empty(line)
      return line
    endif
  endfor
  return ''
endfunction

function! s:bullet_for(job, ...)
  if a:job.running
    return a:job.new ? '+' : '*'
  endif
  if get(a:job, 'abort', 0)
    return '~'
  endif
  return a:job.error ? 'x' : get(a:000, 0, '-')
endfunction

function! s:job_out_cb(self, data) abort
  let self = a:self
  let data = remove(self.lines, -1) . a:data
  let lines = map(split(data, "\n", 1), 'split(v:val, "\r", 1)[-1]')
  call extend(self.lines, lines)
  " To reduce the number of buffer updates
  let self.tick = get(self, 'tick', -1) + 1
  if !self.running || self.tick % len(s:jobs) == 0
    let result = self.error ? join(self.lines, "\n") : s:last_non_empty_line(self.lines)
    if len(result)
      call s:log(s:bullet_for(self), self.name, result)
    endif
  endif
endfunction

function! s:job_exit_cb(self, data) abort
  let a:self.running = 0
  let a:self.error = a:data != 0
  call s:reap(a:self.name)
  call s:tick()
endfunction

function! s:plug_window_exists()
  " Check if dialog UI is being used
  if exists('*popup_create') && plug#dialog#is_open()
    return 1
  endif

  " Check if buffer UI is being used
  return s:plug_buf != -1 && bufexists(s:plug_buf)
endfunction

function! s:job_cb(fn, job, ch, data)
  if !s:plug_window_exists() " plug window closed
    return s:job_abort(0)
  endif
  call call(a:fn, [a:job, a:data])
endfunction

" Neovim callback removed

function! s:spawn(name, spec, queue, opts)
  let job = { 'name': a:name, 'spec': a:spec, 'running': 1, 'error': 0, 'lines': [''],
            \ 'new': get(a:opts, 'new', 0), 'queue': copy(a:queue) }
  let Item = remove(job.queue, 0)
  let argv = type(Item) == s:TYPE.funcref ? call(Item, [a:spec]) : Item
  let s:jobs[a:name] = job

  let cmd = join(map(copy(argv), 'plug#shellescape(v:val, {"script": 0})'))
  if has_key(a:opts, 'dir')
    let cmd = s:with_cd(cmd, a:opts.dir, 0)
  endif
  let argv = ['sh', '-c', cmd]
  let jid = job_start(argv, {
  \ 'out_cb':   function('s:job_cb', ['s:job_out_cb',  job]),
  \ 'err_cb':   function('s:job_cb', ['s:job_out_cb',  job]),
  \ 'exit_cb':  function('s:job_cb', ['s:job_exit_cb', job]),
  \ 'err_mode': 'raw',
  \ 'out_mode': 'raw'
  \})

  if job_status(jid) == 'run'
    let job.jobid = jid
  else
    let job.running = 0
    let job.error   = 1
    let job.lines   = ['Failed to start job']
  endif
endfunction

function! s:reap(name)
  let job = remove(s:jobs, a:name)
  if job.error
    call add(s:update.errors, a:name)
  elseif get(job, 'new', 0)
    let s:update.new[a:name] = 1
  endif

  let more = len(get(job, 'queue', []))
  let result = job.error ? join(job.lines, "\n") : s:last_non_empty_line(job.lines)
  if len(result)
    call s:log(s:bullet_for(job), a:name, result)
  endif

  if !job.error && more
    let job.spec.queue = job.queue
    let s:update.todo[a:name] = job.spec
  else
    let s:update.bar .= s:bullet_for(job, '=')
    call s:bar()
  endif
endfunction

function! s:bar()
  " Check if we're using dialog UI
  if exists('*popup_create') && plug#dialog#is_open()
    " Update progress in dialog
    call plug#dialog#update_progress(len(s:update.bar))
    return
  endif

  " Fall back to buffer UI
  if s:switch_in()
    let total = len(s:update.all)
    call setline(1, (s:update.pull ? 'Updating' : 'Installing').
          \ ' plugins ('.len(s:update.bar).'/'.total.')')
    call s:progress_bar(2, s:update.bar, total)
    call s:switch_out()
  endif
endfunction

function! s:logpos(name)
  let max = line('$')
  for i in range(4, max > 4 ? max : 4)
    if getline(i) =~# '^[-+x*] '.a:name.':'
      for j in range(i + 1, max > 5 ? max : 5)
        if getline(j) !~ '^ '
          return [i, j - 1]
        endif
      endfor
      return [i, i]
    endif
  endfor
  return [0, 0]
endfunction

function! s:log(bullet, name, lines)
  " Check if we're using dialog UI
  if exists('*popup_create') && plug#dialog#is_open()
    " Determine status based on bullet
    let status = a:bullet == 'x' ? 'error' :
               \ a:bullet == '+' ? 'install' :
               \ a:bullet == '*' ? 'update' : 'done'

    " Get the message
    let message = type(a:lines) == s:TYPE.string ? a:lines : s:lastline(a:lines)

    " Update the dialog
    call plug#dialog#update_plugin(a:name, status, message)
    return
  endif

  " Fall back to buffer UI
  if s:switch_in()
    let [b, e] = s:logpos(a:name)
    if b > 0
      silent execute printf('%d,%d d _', b, e)
      if b > winheight('.')
        let b = 4
      endif
    else
      let b = 4
    endif
    " FIXME For some reason, nomodifiable is set after :d in vim8
    setlocal modifiable
    call append(b - 1, s:format_message(a:bullet, a:name, a:lines))
    call s:switch_out()
  endif
endfunction

function! s:update_vim()
  let s:jobs = {}

  call s:bar()
  call s:tick()
endfunction

" Git functions moved to autoload/plug/git.vim

function! s:tick()
  let pull = s:update.pull
  let prog = s:progress_opt(1)
while 1 " Without TCO, Vim stack is bound to explode
  if empty(s:update.todo)
    if empty(s:jobs) && !s:update.fin
      call s:update_finish()
      let s:update.fin = 1
    endif
    return
  endif

  let name = keys(s:update.todo)[0]
  let spec = remove(s:update.todo, name)
  if get(spec, 'abort', 0)
    call s:mark_aborted(name, 'Skipped')
    call s:reap(name)
    continue
  endif

  let queue = get(spec, 'queue', [])
  let new = empty(globpath(spec.dir, '.git', 1))

  if empty(queue)
    call s:log(new ? '+' : '*', name, pull ? 'Updating ...' : 'Installing ...')
    redraw
  endif

  let has_tag = has_key(spec, 'tag')
  if len(queue)
    call s:spawn(name, spec, queue, { 'dir': spec.dir })
  elseif !new
    let [error, _] = plug#git#validate(spec, 0)
    if empty(error)
      if pull
        let cmd = plug#git#disable_credential_helper() ? ['git', '-c', 'credential.helper=', 'fetch'] : ['git', 'fetch']
        if has_tag && !empty(globpath(spec.dir, '.git/shallow'))
          call extend(cmd, ['--depth', '99999999'])
        endif
        if !empty(prog)
          call add(cmd, prog)
        endif
        let queue = [cmd, split('git remote set-head origin -a')]
        if !has_tag && !has_key(spec, 'commit')
          call extend(queue, [function('plug#git#checkout_command'), function('plug#git#merge_command')])
        endif
        call s:spawn(name, spec, queue, { 'dir': spec.dir })
      else
        let s:jobs[name] = { 'running': 0, 'lines': ['Already installed'], 'error': 0 }
      endif
    else
      let s:jobs[name] = { 'running': 0, 'lines': s:lines(error), 'error': 1 }
    endif
  else
    let cmd = ['git', 'clone']
    if !has_tag
      call extend(cmd, s:clone_opt)
    endif
    if !empty(prog)
      call add(cmd, prog)
    endif
    call s:spawn(name, spec, [extend(cmd, [spec.uri, s:trim(spec.dir)]), function('plug#git#checkout_command'), function('plug#git#merge_command')], { 'new': 1 })
  endif

  if !s:jobs[name].running
    call s:reap(name)
  endif
  if len(s:jobs) >= s:update.threads
    break
  endif
endwhile
endfunction

function! s:shellesc_cmd(arg, script)
  let escaped = substitute('"'.a:arg.'"', '[&|<>()@^!"]', '^&', 'g')
  return substitute(escaped, '%', (a:script ? '%' : '^') . '&', 'g')
endfunction

function! s:shellesc_ps1(arg)
  return "'".substitute(escape(a:arg, '\"'), "'", "''", 'g')."'"
endfunction

function! s:shellesc_sh(arg)
  return "'".substitute(a:arg, "'", "'\\\\''", 'g')."'"
endfunction

" Escape the shell argument based on the shell.
" Vim and Neovim's shellescape() are insufficient.
" 1. shellslash determines whether to use single/double quotes.
"    Double-quote escaping is fragile for cmd.exe.
" 2. It does not work for powershell.
" 3. It does not work for *sh shells if the command is executed
"    via cmd.exe (ie. cmd.exe /c sh -c command command_args)
" 4. It does not support batchfile syntax.
"
" Accepts an optional dictionary with the following keys:
" - shell: same as Vim/Neovim 'shell' option.
"          If unset, fallback to 'cmd.exe' on Windows or 'sh'.
" - script: If truthy and shell is cmd.exe, escape for batchfile syntax.
function! plug#shellescape(arg, ...)
  if a:arg =~# '^[A-Za-z0-9_/:.-]\+$'
    return a:arg
  endif
  let opts = a:0 > 0 && type(a:1) == s:TYPE.dict ? a:1 : {}
  let shell = get(opts, 'shell', 'sh')
  let script = get(opts, 'script', 1)
  return s:shellesc_sh(a:arg)
endfunction

function! s:glob_dir(path)
  return map(filter(s:glob(a:path, '**'), 'isdirectory(v:val)'), 's:dirpath(v:val)')
endfunction

" Function removed - only used for buffer UI

function! s:compare_git_uri(a, b)
  " See `git help clone'
  " https:// [user@] github.com[:port] / junegunn/vim-plug [.git]
  "          [git@]  github.com[:port] : junegunn/vim-plug [.git]
  " file://                            / junegunn/vim-plug        [/]
  "                                    / junegunn/vim-plug        [/]
  let pat = '^\%(\w\+://\)\='.'\%([^@/]*@\)\='.'\([^:/]*\%(:[0-9]*\)\=\)'.'[:/]'.'\(.\{-}\)'.'\%(\.git\)\=/\?$'
  let ma = matchlist(a:a, pat)
  let mb = matchlist(a:b, pat)
  return ma[1:2] ==# mb[1:2]
endfunction

function! s:format_message(bullet, name, message)
  if a:bullet != 'x'
    return [printf('%s %s: %s', a:bullet, a:name, s:lastline(a:message))]
  else
    let lines = map(s:lines(a:message), '"    ".v:val')
    return extend([printf('x %s:', a:name)], lines)
  endif
endfunction

function! s:with_cd(cmd, dir, ...)
  let script = a:0 > 0 ? a:1 : 1
  return printf('cd %s && %s', plug#shellescape(a:dir, {'script': script, 'shell': &shell}), a:cmd)
endfunction

function! s:system(cmd, ...)
  try
    let [sh, shellcmdflag, shrd] = s:chsh(1)
    if type(a:cmd) == s:TYPE.list
      let cmd = join(map(copy(a:cmd), 'plug#shellescape(v:val, {"shell": &shell, "script": 0})'))
    else
      let cmd = a:cmd
    endif
    if a:0 > 0
      let cmd = s:with_cd(cmd, a:1, type(a:cmd) != s:TYPE.list)
    endif
    return system(cmd)
  finally
    let [&shell, &shellcmdflag, &shellredir] = [sh, shellcmdflag, shrd]
  endtry
endfunction

function! s:system_chomp(...)
  let ret = call('s:system', a:000)
  return v:shell_error ? '' : substitute(ret, '\n$', '', '')
endfunction

" Git functions moved to autoload/plug/git.vim

function! s:rm_rf(dir)
  if isdirectory(a:dir)
    return s:system(['rm', '-rf', a:dir])
  endif
endfunction

function! s:clean(force)
  call s:prepare()
  call append(0, 'Searching for invalid plugins in '.g:plug_home)
  call append(1, '')

  " List of valid directories
  let dirs = []
  let errs = {}
  let [cnt, total] = [0, len(g:plugs)]
  for [name, spec] in items(g:plugs)
    if !s:is_managed(name) || get(spec, 'frozen', 0)
      call add(dirs, spec.dir)
    else
      let [err, clean] = plug#git#validate(spec, 1)
      if clean
        let errs[spec.dir] = s:lines(err)[0]
      else
        call add(dirs, spec.dir)
      endif
    endif
    let cnt += 1
    call s:progress_bar(2, repeat('=', cnt), total)
    normal! 2G
    redraw
  endfor

  let allowed = {}
  for dir in dirs
    let allowed[s:dirpath(s:plug_fnamemodify(dir, ':h:h'))] = 1
    let allowed[dir] = 1
    for child in s:glob_dir(dir)
      let allowed[child] = 1
    endfor
  endfor

  let todo = []
  let found = sort(s:glob_dir(g:plug_home))
  while !empty(found)
    let f = remove(found, 0)
    if !has_key(allowed, f) && isdirectory(f)
      call add(todo, f)
      call append(line('$'), '- ' . f)
      if has_key(errs, f)
        call append(line('$'), '    ' . errs[f])
      endif
      let found = filter(found, 'stridx(v:val, f) != 0')
    end
  endwhile

  4
  redraw
  if empty(todo)
    call append(line('$'), 'Already clean.')
  else
    let s:clean_count = 0
    call append(3, ['Directories to delete:', ''])
    redraw!
    if a:force || s:ask_no_interrupt('Delete all directories?')
      call s:delete([6, line('$')], 1)
    else
      call setline(4, 'Cancelled.')
      nnoremap <silent> <buffer> d :set opfunc=<sid>delete_op<cr>g@
      nmap     <silent> <buffer> dd d_
      xnoremap <silent> <buffer> d :<c-u>call <sid>delete_op(visualmode(), 1)<cr>
      echo 'Delete the lines (d{motion}) to delete the corresponding directories'
    endif
  endif
  4
  setlocal nomodifiable
endfunction

function! s:delete_op(type, ...)
  call s:delete(a:0 ? [line("'<"), line("'>")] : [line("'["), line("']")], 0)
endfunction

function! s:delete(range, force)
  let [l1, l2] = a:range
  let force = a:force
  let err_count = 0
  while l1 <= l2
    let line = getline(l1)
    if line =~ '^- ' && isdirectory(line[2:])
      execute l1
      redraw!
      let answer = force ? 1 : s:ask('Delete '.line[2:].'?', 1)
      let force = force || answer > 1
      if answer
        let err = s:rm_rf(line[2:])
        setlocal modifiable
        if empty(err)
          call setline(l1, '~'.line[1:])
          let s:clean_count += 1
        else
          delete _
          call append(l1 - 1, s:format_message('x', line[1:], err))
          let l2 += len(s:lines(err))
          let err_count += 1
        endif
        let msg = printf('Removed %d directories.', s:clean_count)
        if err_count > 0
          let msg .= printf(' Failed to remove %d directories.', err_count)
        endif
        call setline(4, msg)
        setlocal nomodifiable
      endif
    endif
    let l1 += 1
  endwhile
endfunction

function! s:upgrade()
  echo 'Downloading the latest version of vim-plug'
  redraw
  let tmp = s:plug_tempname()
  let new = tmp . '/plug.vim'

  try
    let out = s:system(['git', 'clone', '--depth', '1', s:plug_src, tmp])
    if v:shell_error
      return s:err('Error upgrading vim-plug: '. out)
    endif

    if readfile(s:me) ==# readfile(new)
      echo 'vim-plug is already up-to-date'
      return 0
    else
      call rename(s:me, s:me . '.old')
      call rename(new, s:me)
      unlet g:loaded_plug
      echo 'vim-plug has been upgraded'
      return 1
    endif
  finally
    silent! call s:rm_rf(tmp)
  endtry
endfunction

function! s:upgrade_specs()
  for spec in values(g:plugs)
    let spec.frozen = get(spec, 'frozen', 0)
  endfor
endfunction

function! s:status()
  call s:prepare()
  call append(0, 'Checking plugins')
  call append(1, '')

  let ecnt = 0
  let unloaded = 0
  let [cnt, total] = [0, len(g:plugs)]
  for [name, spec] in items(g:plugs)
    let is_dir = isdirectory(spec.dir)
    if has_key(spec, 'uri')
      if is_dir
        let [err, _] = plug#git#validate(spec, 1)
        let [valid, msg] = [empty(err), empty(err) ? 'OK' : err]
      else
        let [valid, msg] = [0, 'Not found. Try PlugInstall.']
      endif
    else
      if is_dir
        let [valid, msg] = [1, 'OK']
      else
        let [valid, msg] = [0, 'Not found.']
      endif
    endif
    let cnt += 1
    let ecnt += !valid
    " `s:loaded` entry can be missing if PlugUpgraded
    if is_dir && get(s:loaded, name, -1) == 0
      let unloaded = 1
      let msg .= ' (not loaded)'
    endif
    call s:progress_bar(2, repeat('=', cnt), total)
    call append(3, s:format_message(valid ? '-' : 'x', name, msg))
    normal! 2G
    redraw
  endfor
  call setline(1, 'Finished. '.ecnt.' error(s).')
  normal! gg
  setlocal nomodifiable
  if unloaded
    echo "Press 'L' on each line to load plugin, or 'U' to update"
    nnoremap <silent> <buffer> L :call <SID>status_load(line('.'))<cr>
    xnoremap <silent> <buffer> L :call <SID>status_load(line('.'))<cr>
  end
endfunction

function! s:extract_name(str, prefix, suffix)
  return matchstr(a:str, '^'.a:prefix.' \zs[^:]\+\ze:.*'.a:suffix.'$')
endfunction

function! s:status_load(lnum)
  let line = getline(a:lnum)
  let name = s:extract_name(line, '-', '(not loaded)')
  if !empty(name)
    call plug#load(name)
    setlocal modifiable
    call setline(a:lnum, substitute(line, ' (not loaded)$', '', ''))
    setlocal nomodifiable
  endif
endfunction

function! s:status_update() range
  let lines = getline(a:firstline, a:lastline)
  let names = filter(map(lines, 's:extract_name(v:val, "[x-]", "")'), '!empty(v:val)')
  if !empty(names)
    echo
    execute 'PlugUpdate' join(names)
  endif
endfunction

function! plug#status_update() range
  call s:status_update()
endfunction

function! s:is_preview_window_open()
  silent! wincmd P
  if &previewwindow
    wincmd p
    return 1
  endif
endfunction

function! s:find_name(lnum)
  for lnum in reverse(range(1, a:lnum))
    let line = getline(lnum)
    if empty(line)
      return ''
    endif
    let name = s:extract_name(line, '-', '')
    if !empty(name)
      return name
    endif
  endfor
  return ''
endfunction

function! s:preview_commit()
  if b:plug_preview < 0
    let b:plug_preview = !s:is_preview_window_open()
  endif

  let sha = matchstr(getline('.'), '^  \X*\zs[0-9a-f]\{7,9}')
  if empty(sha)
    let name = matchstr(getline('.'), '^- \zs[^:]*\ze:$')
    if empty(name)
      return
    endif
    let title = 'HEAD@{1}..'
    let command = 'git diff --no-color HEAD@{1}'
  else
    let title = sha
    let command = 'git show --no-color --pretty=medium '.sha
    let name = s:find_name(line('.'))
  endif

  if empty(name) || !has_key(g:plugs, name) || !isdirectory(g:plugs[name].dir)
    return
  endif

  if !s:is_preview_window_open()
    execute get(g:, 'plug_pwindow', 'vertical rightbelow new')
    execute 'e' title
  else
    execute 'pedit' title
    wincmd P
  endif
  setlocal previewwindow filetype=git buftype=nofile bufhidden=wipe nobuflisted modifiable
  try
    let [sh, shellcmdflag, shrd] = s:chsh(1)
    let cmd = 'cd '.plug#shellescape(g:plugs[name].dir).' && '.command
    execute 'silent %!' cmd
  finally
    let [&shell, &shellcmdflag, &shellredir] = [sh, shellcmdflag, shrd]
  endtry
  setlocal nomodifiable
  nnoremap <silent> <buffer> q :q<cr>
  wincmd p
endfunction

function! s:section(flags)
  call search('\(^[x-] \)\@<=[^:]\+:', a:flags)
endfunction

function! plug#section(flags)
  call s:section(a:flags)
endfunction

" Git functions moved to autoload/plug/git.vim

function! s:append_ul(lnum, text)
  call append(a:lnum, ['', a:text, repeat('-', len(a:text))])
endfunction

function! s:diff()
  call s:prepare()
  call append(0, ['Collecting changes ...', ''])
  let cnts = [0, 0]
  let bar = ''
  let total = filter(copy(g:plugs), 's:is_managed(v:key) && isdirectory(v:val.dir)')
  call s:progress_bar(2, bar, len(total))
  for origin in [1, 0]
    let plugs = reverse(sort(items(filter(copy(total), (origin ? '' : '!').'(has_key(v:val, "commit") || has_key(v:val, "tag"))'))))
    if empty(plugs)
      continue
    endif
    call s:append_ul(2, origin ? 'Pending updates:' : 'Last update:')
    for [k, v] in plugs
      let branch = plug#git#origin_branch(v)
      if len(branch)
        let range = origin ? '..origin/'.branch : 'HEAD@{1}..'
        let cmd = ['git', 'log', '--graph', '--color=never', '--no-show-signature']
        call extend(cmd, ['--pretty=format:%x01%h%x01%d%x01%s%x01%cr', range])
        if has_key(v, 'rtp')
          call extend(cmd, ['--', v.rtp])
        endif
        let diff = s:system_chomp(cmd, v.dir)
        if !empty(diff)
          let ref = has_key(v, 'tag') ? (' (tag: '.v.tag.')') : has_key(v, 'commit') ? (' '.v.commit) : ''
          call append(5, extend(['', '- '.k.':'.ref], map(s:lines(diff), 'plug#git#format_git_log(v:val)')))
          let cnts[origin] += 1
        endif
      endif
      let bar .= '='
      call s:progress_bar(2, bar, len(total))
      normal! 2G
      redraw
    endfor
    if !cnts[origin]
      call append(5, ['', 'N/A'])
    endif
  endfor
  call setline(1, printf('%d plugin(s) updated.', cnts[0])
        \ . (cnts[1] ? printf(' %d plugin(s) have pending updates.', cnts[1]) : ''))

  if cnts[0] || cnts[1]
    nnoremap <silent> <buffer> <plug>(plug-preview) :silent! call <SID>preview_commit()<cr>
    if empty(maparg("\<cr>", 'n'))
      nmap <buffer> <cr> <plug>(plug-preview)
    endif
    if empty(maparg('o', 'n'))
      nmap <buffer> o <plug>(plug-preview)
    endif
  endif
  if cnts[0]
    nnoremap <silent> <buffer> X :call <SID>revert()<cr>
    echo "Press 'X' on each block to revert the update"
  endif
  normal! gg
  setlocal nomodifiable
endfunction

function! s:revert()
  if search('^Pending updates', 'bnW')
    return
  endif

  let name = s:find_name(line('.'))
  if empty(name) || !has_key(g:plugs, name) ||
    \ input(printf('Revert the update of %s? (y/N) ', name)) !~? '^y'
    return
  endif

  call s:system('git reset --hard HEAD@{1} && git checkout '.plug#shellescape(g:plugs[name].branch).' --', g:plugs[name].dir)
  setlocal modifiable
  normal! "_dap
  setlocal nomodifiable
  echo 'Reverted'
endfunction

function! s:snapshot(force, ...) abort
  call s:prepare()
  setf vim
  call append(0, ['" Generated by vim-plug',
                \ '" '.strftime("%c"),
                \ '" :source this file in vim to restore the snapshot',
                \ '" or execute: vim -S snapshot.vim',
                \ '', '', 'PlugUpdate!'])
  1
  let anchor = line('$') - 3
  let names = sort(keys(filter(copy(g:plugs),
        \'has_key(v:val, "uri") && isdirectory(v:val.dir)')))
  for name in reverse(names)
    let sha = has_key(g:plugs[name], 'commit') ? g:plugs[name].commit : plug#git#revision(g:plugs[name].dir)
    if !empty(sha)
      call append(anchor, printf("silent! let g:plugs['%s'].commit = '%s'", name, sha))
      redraw
    endif
  endfor

  if a:0 > 0
    let fn = s:plug_expand(a:1)
    if filereadable(fn) && !(a:force || s:ask(a:1.' already exists. Overwrite?'))
      return
    endif
    call writefile(getline(1, '$'), fn)
    echo 'Saved as '.a:1
    silent execute 'e' s:esc(fn)
    setf vim
  endif
endfunction

function! s:split_rtp()
  return split(&rtp, '\\\@<!,')
endfunction

let s:first_rtp = s:escrtp(get(s:split_rtp(), 0, ''))
let s:last_rtp  = s:escrtp(get(s:split_rtp(), -1, ''))

if exists('g:plugs')
  let g:plugs_order = get(g:, 'plugs_order', keys(g:plugs))
  call s:upgrade_specs()
  call s:define_commands()
endif

let &cpo = s:cpo_save
unlet s:cpo_save
