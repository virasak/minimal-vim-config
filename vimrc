vim9script

# Basic settings
set noswapfile
set nobackup
set autoindent
set smartindent
set tabstop=2
set shiftwidth=2
set expandtab
set smarttab
set number
set hidden
set incsearch
set hlsearch
set termguicolors
set visualbell t_vb=

# UI settings
set t_Co=256
set laststatus=2

# Colors and appearance
set background=dark
if has('gui_running')
  set guifont=JetBrainsMonoNFM-Regular:h14
  set guioptions=
  set columns=145
  colorscheme habamax
else
  colorscheme tokyonight
endif

syntax on

# Plugin configuration
g:plugins = [
  'https://github.com/preservim/nerdtree',
  'https://github.com/tpope/vim-surround',
  'https://github.com/itchyny/lightline.vim',
  'https://github.com/tpope/vim-fugitive'
]

# Key mappings
g:mapleader = ' '

nnoremap <Leader>e :NERDTreeFocus<CR>
nnoremap <Leader>E :NERDTreeFind<CR>
nnoremap <Leader><Leader> :NERDTreeToggle<CR>
