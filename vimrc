vim9script

# Basic settings
set nocompatible
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

# UI settings
set columns=145
set laststatus=2

# Colors and appearance
set background=dark
if has('gui_running')
  set guifont=JetBrainsMonoNFM-Regular:h14
  set guioptions=
  set t_Co=256
endif

colorscheme habamax

# Plugin configuration
g:plugins = [
  'https://github.com/preservim/nerdtree',
  'https://github.com/tpope/vim-surround',
  'https://github.com/itchyny/lightline.vim'
]

# Key mappings
g:mapleader = ' '

nnoremap <Leader>e :NERDTreeToggle<CR>
nnoremap <Leader>E :NERDTreeFind<CR>
