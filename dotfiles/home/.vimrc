set number
set mouse=a
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set hlsearch
set incsearch
set termguicolors
syntax on
set showmatch
set scrolloff=8
set clipboard=unnamedplus

let mapleader=" "

nnoremap <leader>w :w<CR>
inoremap jk <Esc>

call plug#begin()

Plug 'preservim/nerdtree'
Plug 'tpope/vim-fugitive'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Theme
Plug 'folke/tokyonight.nvim'

call plug#end()

let g:airline_theme='deus'
