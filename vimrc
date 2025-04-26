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

set columns=145
set laststatus=2

set background=dark
if has('gui_running')
  set guifont=JetBrainsMonoNFM-Regular:h14
  set guioptions=
  set t_Co=256
endif

colorschem habamax

call plug#begin()
  Plug 'preservim/nerdtree'
  Plug 'itchyny/lightline.vim'
call plug#end()

let g:mapleader=' '

nnoremap <Leader>e :NERDTreeToggle<CR>
nnoremap <Leader>E :NERDTreeFind<CR>

