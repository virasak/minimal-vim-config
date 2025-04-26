" vim-plug dialog UI module
" Provides dialog-based UI for vim-plug operations

" Dialog state
let s:dialog = {
  \ 'id': -1,
  \ 'type': '',
  \ 'plugins': {},
  \ 'progress': 0,
  \ 'total': 0,
  \ 'errors': [],
  \ 'content': [],
  \ 'title': '',
  \ 'width': 80,
  \ 'height': 20,
  \ 'callback': 0
\ }

" Create a new dialog
function! plug#dialog#new(title, type, plugins, callback)
  let s:dialog.id = -1
  let s:dialog.type = a:type
  let s:dialog.plugins = a:plugins
  let s:dialog.progress = 0
  let s:dialog.total = len(a:plugins)
  let s:dialog.errors = []
  let s:dialog.title = a:title
  let s:dialog.callback = a:callback

  " Calculate dialog size based on terminal
  let s:dialog.width = min([max([80, &columns - 20]), &columns - 4])
  let s:dialog.height = min([max([20, &lines - 10]), &lines - 4])

  " Initialize content
  let s:dialog.content = []
  call add(s:dialog.content, a:title . ' (' . s:dialog.progress . '/' . s:dialog.total . ')')
  call add(s:dialog.content, s:create_progress_bar(s:dialog.progress, s:dialog.total))
  call add(s:dialog.content, '')

  " Add plugin entries
  for [name, spec] in items(a:plugins)
    call add(s:dialog.content, '- ' . name . ': Pending')
  endfor

  " Create the popup
  call s:create_popup()

  return s:dialog.id
endfunction

" Create the popup window
function! s:create_popup()
  " Close existing popup if any
  call plug#dialog#close()

  " Create new popup
  let options = {
    \ 'title': ' vim-plug ',
    \ 'padding': [1, 1, 1, 1],
    \ 'border': [1, 1, 1, 1],
    \ 'borderchars': ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
    \ 'mapping': 0,
    \ 'callback': function('s:dialog_callback'),
    \ 'close': 'button',
    \ 'highlight': 'Normal',
    \ 'borderhighlight': ['Title'],
    \ 'filter': function('s:dialog_filter')
  \ }

  let s:dialog.id = popup_create(s:dialog.content, options)

  " Add buttons
  call s:add_buttons()

  return s:dialog.id
endfunction

" Add buttons to the dialog
function! s:add_buttons()
  " TODO: Implement buttons when needed
endfunction

" Dialog filter function for handling keypresses
function! s:dialog_filter(id, key)
  if a:key == 'q' || a:key == "\<Esc>"
    call plug#dialog#close()
    return 1
  endif

  return 0
endfunction

" Dialog callback when closed
function! s:dialog_callback(id, result)
  let s:dialog.id = -1
  if s:dialog.callback != 0
    call s:dialog.callback(a:result)
  endif
endfunction

" Close the dialog
function! plug#dialog#close()
  if s:dialog.id != -1
    call popup_close(s:dialog.id)
    let s:dialog.id = -1
  endif
endfunction

" Update plugin status in the dialog
function! plug#dialog#update_plugin(name, status, message)
  if s:dialog.id == -1
    return
  endif

  " Find the plugin line
  let idx = -1
  for i in range(len(s:dialog.content))
    if s:dialog.content[i] =~ '^[-+*x] ' . a:name . ':'
      let idx = i
      break
    endif
  endfor

  " If not found, find a line starting with the plugin name
  if idx == -1
    for i in range(len(s:dialog.content))
      if s:dialog.content[i] =~ '^- ' . a:name . ':'
        let idx = i
        break
      endif
    endfor
  endif

  " If still not found, add a new line
  if idx == -1
    call add(s:dialog.content, '')
    let idx = len(s:dialog.content) - 1
  endif

  " Update the line
  let bullet = ''
  if a:status == 'error'
    let bullet = 'x'
  elseif a:status == 'done'
    let bullet = '*'
  elseif a:status == 'install'
    let bullet = '+'
  else
    let bullet = '-'
  endif

  let s:dialog.content[idx] = bullet . ' ' . a:name . ': ' . a:message

  " If error, add to errors list
  if a:status == 'error' && index(s:dialog.errors, a:name) == -1
    call add(s:dialog.errors, a:name)
  endif

  " Update the popup
  call popup_settext(s:dialog.id, s:dialog.content)
endfunction

" Update progress in the dialog
function! plug#dialog#update_progress(progress)
  if s:dialog.id == -1
    return
  endif

  let s:dialog.progress = a:progress

  " Update title line
  let s:dialog.content[0] = s:dialog.title . ' (' . s:dialog.progress . '/' . s:dialog.total . ')'

  " Update progress bar
  let s:dialog.content[1] = s:create_progress_bar(s:dialog.progress, s:dialog.total)

  " Update the popup
  call popup_settext(s:dialog.id, s:dialog.content)
endfunction

" Create a progress bar string
function! s:create_progress_bar(current, total)
  let width = s:dialog.width - 10
  let filled = a:current * width / max([a:total, 1])
  let empty = width - filled

  return '[' . repeat('=', filled) . repeat(' ', empty) . ']'
endfunction

" Add a message to the dialog
function! plug#dialog#add_message(message)
  if s:dialog.id == -1
    return
  endif

  call add(s:dialog.content, a:message)
  call popup_settext(s:dialog.id, s:dialog.content)
endfunction

" Get dialog status
function! plug#dialog#is_open()
  return s:dialog.id != -1
endfunction

" Get dialog errors
function! plug#dialog#get_errors()
  return s:dialog.errors
endfunction

" Show a notification popup
function! plug#dialog#notify(message, type)
  if !exists('*popup_notification')
    return
  endif

  let options = {
    \ 'pos': 'topright',
    \ 'time': 3000,
    \ 'tabpage': 0,
    \ 'padding': [0, 1, 0, 1],
    \ 'border': [1, 1, 1, 1],
    \ 'borderchars': ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
    \ 'borderhighlight': ['Title']
  \ }

  if a:type == 'error'
    let options.highlight = 'ErrorMsg'
  elseif a:type == 'warning'
    let options.highlight = 'WarningMsg'
  else
    let options.highlight = 'Normal'
  endif

  call popup_notification([' vim-plug ', '', ' ' . a:message . ' '], options)
endfunction
