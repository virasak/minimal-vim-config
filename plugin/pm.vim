vim9script
#=============================================================================
# This is a variation of the original work
# Original work: pm.vim@0.7.2 - Stupidly Simple Vim plugin manager
# Original author: Bryce Vandegrift <https://brycevandegrift.xyz>
#=============================================================================

# Prevent loading twice
if exists('g:pm_loaded') || &cp || v:version < 900
	finish
endif
g:pm_loaded = 1

#=============================================================================
# Configuration
#=============================================================================

# Set default plugin installation path
var pm_path = get(g:, 'pm_path', expand('$HOME/.vim/pack/plugins/start/'))

# Create plugin directory if it doesn't exist
if !isdirectory(pm_path)
	silent execute '!mkdir -p ' .. pm_path
endif

# Initialize plugin list if not defined
var plugins = get(g:, 'plugins', [])

#=============================================================================
# Helper Functions
#=============================================================================

# Extract repository name from a git URL
def NameFromGit(url: string): string
	# Remove .git suffix if present and get the last part of the path
	return fnamemodify(substitute(url, '\.git$', '', ''), ':t')
enddef

# Generate helptags for plugin documentation
def UpdateDocs(plugin_name: string)
	var doc_dir = pm_path .. plugin_name .. '/doc'
	if isdirectory(doc_dir)
		execute 'helptags ' .. doc_dir
		echom 'Adding docs for ' .. plugin_name .. '...'
	endif
enddef

#=============================================================================
# Plugin Management Functions
#=============================================================================

# Clone a single plugin
def ClonePlugin(url: string)
	var plugin_name = NameFromGit(url)

	# Check if plugin already exists
	if isdirectory(pm_path .. plugin_name)
		echom 'Plugin ' .. plugin_name .. ' already installed'
		return
	endif

	echom 'Cloning ' .. url .. '...'
	var cmd = '!git -C ' .. shellescape(pm_path) .. ' clone ' .. shellescape(url)
	execute cmd

	# Generate helptags if documentation exists
	UpdateDocs(plugin_name)
	echom 'Done!'
enddef

# Download all plugins defined in plugins list
def DownloadPlugins()
	echom 'Downloading plugins...'
	if empty(plugins)
		echom 'No plugins defined! Add plugins to g:plugins list.'
		return
	endif

	var count = 0
	for url in plugins
		var plugin_name = NameFromGit(url)

		# Skip if already installed
		if isdirectory(pm_path .. plugin_name)
			echom 'Plugin ' .. plugin_name .. ' already installed, skipping'
			continue
		endif

		execute '!git -C ' .. shellescape(pm_path) .. ' clone ' .. shellescape(url)
		UpdateDocs(plugin_name)
		count += 1
	endfor
enddef

# List all installed plugins
def ListPlugins()
	echom 'Installed plugins:'

	# Get all directories in the plugin path
	var paths = globpath(pm_path, '*', 0, 1)
	filter(paths, (_, val) => isdirectory(val))

	# Extract just the plugin names
	var plugin_names = mapnew(paths, (_, val) => fnamemodify(val, ':t'))

	if empty(plugin_names)
		echom '  No plugins installed'
		return
	endif

	# Display each plugin
	for name in plugin_names
		echom '  - ' .. name
	endfor
enddef

# Update all installed plugins
def UpdatePlugins()
	echom 'Updating plugins...'

	# Get all plugin directories
	var paths = globpath(pm_path, '*', 0, 1)
	filter(paths, (_, val) => isdirectory(val))

	if empty(paths)
		echom 'No plugins installed'
		return
	endif

	var updated_count = 0

	# Update each plugin
	for path in paths
		var plugin_name = fnamemodify(path, ':t')
		echom 'Updating ' .. plugin_name .. '...'

		# Pull latest changes
		execute '!git -C ' .. shellescape(path) .. ' pull'

		# Update helptags
		UpdateDocs(plugin_name)
		updated_count += 1
	endfor

	echom 'Done! ' .. updated_count .. ' plugin(s) updated.'
enddef

# Remove plugins that are not in the plugins list
def PurgePlugins()
	echom 'Purging plugins...'

	if empty(plugins)
		echom 'No plugins defined in g:plugins list!'
		return
	endif

	# Get all installed plugin directories
	var paths = globpath(pm_path, '*', 0, 1)
	filter(paths, (_, val) => isdirectory(val))

	if empty(paths)
		echom 'No plugins installed'
		return
	endif

	# Get names of installed plugins
	var installed_names = mapnew(paths, (_, val) => fnamemodify(val, ':t'))

	# Get names of plugins that should be kept
	var keep_names = mapnew(plugins[0 : ], (_, val) => NameFromGit(val))

	# Find plugins to remove (those not in the keep list)
	var to_remove = []
	var remove_names = []

	for idx in range(len(installed_names))
		if !(installed_names[idx] in keep_names)
			add(to_remove, paths[idx])
			add(remove_names, installed_names[idx])
		endif
	endfor

	# Remove unwanted plugins
	if empty(to_remove)
		echom 'No plugins to purge'
	else
		echom 'Removing plugins: ' .. join(remove_names, ', ')
		for path in to_remove
			execute '!rm -rf ' .. shellescape(path)
		endfor
		echom 'Removed ' .. len(to_remove) .. ' plugin(s)'
	endif

	echom 'Done!'
enddef

#=============================================================================
# Commands
#=============================================================================

command! -nargs=1 -complete=file ClonePlugin ClonePlugin(<args>)
command! -nargs=0 -bar DownloadPlugins DownloadPlugins()
command! -nargs=0 -bar ListPlugins ListPlugins()
command! -nargs=0 -bar PurgePlugins PurgePlugins()
command! -nargs=0 -bar UpdatePlugins UpdatePlugins()
