" git.vim - Git functionality for vim-plug
" Maintainer: Junegunn Choi

if exists('g:autoloaded_plug_git')
  finish
endif
let g:autoloaded_plug_git = 1

let s:cpo_save = &cpo
set cpo&vim

" Utility functions
function! s:trim(str)
  return substitute(a:str, '[\/]\+$', '', '')
endfunction

function! s:isabsolute(dir) abort
  return a:dir =~# '^/'
endfunction

function! s:lines(msg)
  return split(a:msg, "[\r\n]")
endfunction

function! s:lastline(msg)
  return get(s:lines(a:msg), -1, '')
endfunction

function! s:system(cmd, ...)
  try
    let [sh, shellcmdflag, shrd] = s:chsh(1)
    if type(a:cmd) == type([])
      let cmd = join(map(copy(a:cmd), 'plug#shellescape(v:val, {"shell": &shell, "script": 0})'))
    else
      let cmd = a:cmd
    endif
    if a:0 > 0
      let cmd = s:with_cd(cmd, a:1, type(a:cmd) != type([]))
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

function! s:chsh(swap)
  let prev = [&shell, &shellcmdflag, &shellredir]
  set shell=sh
  if a:swap
    set shellredir=>%s\ 2>&1
  endif
  return prev
endfunction

function! s:with_cd(cmd, dir, ...)
  let script = a:0 > 0 ? a:1 : 1
  return printf('cd %s && %s', plug#shellescape(a:dir, {'script': script, 'shell': &shell}), a:cmd)
endfunction

" Git functions
function! plug#git#dir(dir) abort
  let gitdir = s:trim(a:dir) . '/.git'
  if isdirectory(gitdir)
    return gitdir
  endif
  if !filereadable(gitdir)
    return ''
  endif
  let gitdir = matchstr(get(readfile(gitdir), 0, ''), '^gitdir: \zs.*')
  if len(gitdir) && !s:isabsolute(gitdir)
    let gitdir = a:dir . '/' . gitdir
  endif
  return isdirectory(gitdir) ? gitdir : ''
endfunction

function! plug#git#origin_url(dir) abort
  let gitdir = plug#git#dir(a:dir)
  let config = gitdir . '/config'
  if empty(gitdir) || !filereadable(config)
    return ''
  endif
  return matchstr(join(readfile(config)), '\[remote "origin"\].\{-}url\s*=\s*\zs\S*\ze')
endfunction

function! plug#git#revision(dir) abort
  let gitdir = plug#git#dir(a:dir)
  let head = gitdir . '/HEAD'
  if empty(gitdir) || !filereadable(head)
    return ''
  endif

  let line = get(readfile(head), 0, '')
  let ref = matchstr(line, '^ref: \zs.*')
  if empty(ref)
    return line
  endif

  if filereadable(gitdir . '/' . ref)
    return get(readfile(gitdir . '/' . ref), 0, '')
  endif

  if filereadable(gitdir . '/packed-refs')
    for line in readfile(gitdir . '/packed-refs')
      if line =~# ' ' . ref
        return matchstr(line, '^[0-9a-f]*')
      endif
    endfor
  endif

  return ''
endfunction

function! plug#git#local_branch(dir) abort
  let gitdir = plug#git#dir(a:dir)
  let head = gitdir . '/HEAD'
  if empty(gitdir) || !filereadable(head)
    return ''
  endif
  let branch = matchstr(get(readfile(head), 0, ''), '^ref: refs/heads/\zs.*')
  return len(branch) ? branch : 'HEAD'
endfunction

function! plug#git#origin_branch(spec)
  if len(a:spec.branch)
    return a:spec.branch
  endif

  " The file may not be present if this is a local repository
  let gitdir = plug#git#dir(a:spec.dir)
  let origin_head = gitdir.'/refs/remotes/origin/HEAD'
  if len(gitdir) && filereadable(origin_head)
    return matchstr(get(readfile(origin_head), 0, ''),
                  \ '^ref: refs/remotes/origin/\zs.*')
  endif

  " The command may not return the name of a branch in detached HEAD state
  let result = s:lines(s:system('git symbolic-ref --short HEAD', a:spec.dir))
  return v:shell_error ? '' : result[-1]
endfunction

function! plug#git#hash_match(a, b)
  return stridx(a:a, a:b) == 0 || stridx(a:b, a:a) == 0
endfunction

function! plug#git#disable_credential_helper()
  return get(g:, 'plug_disable_credential_helper', 1)
endfunction

function! plug#git#checkout(spec)
  let sha = a:spec.commit
  let output = plug#git#revision(a:spec.dir)
  let error = 0
  if !empty(output) && !plug#git#hash_match(sha, s:lines(output)[0])
    let credential_helper = plug#git#disable_credential_helper() ? '-c credential.helper= ' : ''
    let output = s:system(
          \ 'git '.credential_helper.'fetch --depth 999999 && git checkout '.plug#shellescape(sha).' --', a:spec.dir)
    let error = v:shell_error
  endif
  return [output, error]
endfunction

function! plug#git#checkout_command(spec)
  let a:spec.branch = plug#git#origin_branch(a:spec)
  return ['git', 'checkout', '-q', a:spec.branch, '--']
endfunction

function! plug#git#merge_command(spec)
  let a:spec.branch = plug#git#origin_branch(a:spec)
  return ['git', 'merge', '--ff-only', 'origin/'.a:spec.branch]
endfunction

function! plug#git#is_updated(dir)
  return !empty(s:system_chomp(['git', 'log', '--pretty=format:%h', 'HEAD...HEAD@{1}'], a:dir))
endfunction

function! plug#git#compare_git_uri(a, b)
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

function! plug#git#format_git_log(line)
  let indent = '  '
  let tokens = split(a:line, nr2char(1))
  if len(tokens) != 5
    return indent.substitute(a:line, '\s*$', '', '')
  endif
  let [graph, sha, refs, subject, date] = tokens
  let tag = matchstr(refs, 'tag: [^,)]\+')
  let tag = empty(tag) ? ' ' : ' ('.tag.') '
  return printf('%s%s%s%s%s (%s)', indent, graph, sha, tag, subject, date)
endfunction

function! plug#git#validate(spec, check_branch)
  let err = ''
  if isdirectory(a:spec.dir)
    let result = [plug#git#local_branch(a:spec.dir), plug#git#origin_url(a:spec.dir)]
    let remote = result[-1]
    if empty(remote)
      let err = join([remote, 'PlugClean required.'], "\n")
    elseif !plug#git#compare_git_uri(remote, a:spec.uri)
      let err = join(['Invalid URI: '.remote,
                    \ 'Expected:    '.a:spec.uri,
                    \ 'PlugClean required.'], "\n")
    elseif a:check_branch && has_key(a:spec, 'commit')
      let sha = plug#git#revision(a:spec.dir)
      if empty(sha)
        let err = join(add(result, 'PlugClean required.'), "\n")
      elseif !plug#git#hash_match(sha, a:spec.commit)
        let err = join([printf('Invalid HEAD (expected: %s, actual: %s)',
                              \ a:spec.commit[:6], sha[:6]),
                      \ 'PlugUpdate required.'], "\n")
      endif
    elseif a:check_branch
      let current_branch = result[0]
      " Check tag
      let origin_branch = plug#git#origin_branch(a:spec)
      if has_key(a:spec, 'tag')
        let tag = s:system_chomp('git describe --exact-match --tags HEAD 2>&1', a:spec.dir)
        if a:spec.tag !=# tag && a:spec.tag !~ '\*'
          let err = printf('Invalid tag: %s (expected: %s). Try PlugUpdate.',
                \ (empty(tag) ? 'N/A' : tag), a:spec.tag)
        endif
      " Check branch
      elseif origin_branch !=# current_branch
        let err = printf('Invalid branch: %s (expected: %s). Try PlugUpdate.',
              \ current_branch, origin_branch)
      endif
      if empty(err)
        let ahead_behind = split(s:lastline(s:system([
          \ 'git', 'rev-list', '--count', '--left-right',
          \ printf('HEAD...origin/%s', origin_branch)
          \ ], a:spec.dir)), '\t')
        if v:shell_error || len(ahead_behind) != 2
          let err = "Failed to compare with the origin. The default branch might have changed.\nPlugClean required."
        else
          let [ahead, behind] = ahead_behind
          if ahead && behind
            " Only mention PlugClean if diverged, otherwise it's likely to be
            " pushable (and probably not that messed up).
            let err = printf(
                  \ "Diverged from origin/%s (%d commit(s) ahead and %d commit(s) behind!\n"
                  \ .'Backup local changes and run PlugClean and PlugUpdate to reinstall it.', origin_branch, ahead, behind)
          elseif ahead
            let err = printf("Ahead of origin/%s by %d commit(s).\n"
                  \ .'Cannot update until local changes are pushed.',
                  \ origin_branch, ahead)
          endif
        endif
      endif
    endif
  else
    let err = 'Not found'
  endif
  return [err, err =~# 'PlugClean']
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
