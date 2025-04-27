vim9script
# pm.vim - Stupidly Simple Vim plugin manager
# Author: Bryce Vandegrift <https://brycevandegrift.xyz>
# Version: 0.7.2

if exists('g:pm_loaded') || &cp || v:version < 900
	finish
endif
g:pm_loaded = 1

if !exists('g:pm_path')
	g:pm_path = trim(system('echo $HOME/.vim/pack/plugins/start/'))
endif

if !isdirectory(g:pm_path)
	silent execute '!mkdir -p ' .. g:pm_path
endif

if !exists('g:plugins')
	g:plugins = []
endif

if !exists('g:post_download_hooks')
	g:post_download_hooks = []
endif

if !exists('g:post_update_hooks')
	g:post_update_hooks = []
endif

# Takes a git url and returns base repo name
def NameFromGit(str: string): string
	var split_url = split(substitute(str, '\.git$', '', ''), '/')
	return split_url[-1]
enddef

# Checks if val is not in list
def NotInList(val: string, list: list<string>): bool
	for item in list
		if match(item, val) != -1
			return false
		endif
	endfor
	return true
enddef

# Runs helptags on doc files
def UpdateDocs(item: string)
	if isdirectory(g:pm_path .. item .. '/doc')
		execute 'helptags ' .. g:pm_path .. item .. '/doc'
		echom 'Adding docs for ' .. item .. '...'
	endif
enddef

def ClonePlugin(url: string)
	echom 'Cloning ' .. url .. '...'
	execute '!git -C ' .. g:pm_path .. ' clone ' .. url
	UpdateDocs(NameFromGit(url))
	echom 'Done!'
enddef

def DownloadPlugins()
	echom 'Downloading plugins...'
	if empty(g:plugins)
		echom 'No plugins defined!'
		return
	endif
	for item in g:plugins
		execute '!git -C ' .. g:pm_path .. ' clone ' .. item
		UpdateDocs(NameFromGit(item))
	endfor
	if !empty(g:post_download_hooks)
		echom 'Running post download hooks...'
		for item in g:post_download_hooks
			execute item
		endfor
	endif
	echom 'Done!'
enddef

def ListPlugins()
	echom 'Installed plugins:'
	var paths = globpath(g:pm_path, '*', 0, 1)
	filter(paths, (_, val) => isdirectory(val))
	map(paths, (_, val) => split(val, '/'))
	map(paths, (_, val) => get(val, -1))
	for item in paths
		echom item
	endfor
enddef

def UpdatePlugins()
	echom 'Updating plugins...'
	var paths = globpath(g:pm_path, '*', 0, 1)
	filter(paths, (_, val) => isdirectory(val))
	for item in paths
		execute '!git -C ' .. item .. ' pull'
	endfor
	if !empty(g:post_update_hooks)
		echom 'Running post update hooks...'
		for item in g:post_update_hooks
			execute item
		endfor
	endif
	echom 'Done!'
enddef

def PurgePlugins()
	echom 'Purging plugins...'
	if empty(g:plugins)
		echom 'No plugins defined!'
		return
	endif
	# Lots of filtering and mapping
	var paths = globpath(g:pm_path, '*', 0, 1)
	filter(paths, (_, val) => isdirectory(val))
	map(paths, (_, val) => split(val, '/'))
	map(paths, (_, val) => get(val, -1))
	var plugs = mapnew(g:plugins[0 : ], (_, val) => NameFromGit(val))
	filter(paths, (_, val) => NotInList(val, plugs))
	for item in paths
		execute '!rm -rf ' .. g:pm_path .. '/' .. item
	endfor
	echom 'Done!'
enddef

command! -nargs=1 ClonePlugin ClonePlugin(<args>)
command! -nargs=0 DownloadPlugins DownloadPlugins()
command! -nargs=0 ListPlugins ListPlugins()
command! -nargs=0 PurgePlugins PurgePlugins()
command! -nargs=0 UpdatePlugins UpdatePlugins()