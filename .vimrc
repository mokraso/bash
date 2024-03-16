scriptencoding utf-8

set splitbelow splitright 
set ttimeoutlen=50
" set clipboard^=unnamed,unnamedplus

set wildignore+=*.o,*.obj,*.dylib,*.bin,*.dll,*.exe
set wildignore+=*/.git/*,*/.svn/*,*/__pycache__/*,*/build/**
set wildignore+=*.jpg,*.png,*.jpeg,*.bmp,*.gif,*.tiff,*.svg,*.ico
set wildignore+=*.pyc,*.pkl
set wildignore+=*.DS_Store
set wildignore+=*.aux,*.bbl,*.blg,*.brf,*.fls,*.fdb_latexmk,*.synctex.gz,*.xdv
set wildignorecase  " ignore file and dir name cases in cmd-completion

" General tab settings
set tabstop=4       " number of visual spaces per TAB
set softtabstop=4   " number of spaces in tab when editing
set shiftwidth=4    " number of spaces to use for autoindent
set expandtab       " expand tab to spaces so that tabs are spaces

autocmd Filetype markdown,yml setlocal ts=2 sw=2 softtabstop=2 expandtab
filetype plugin indent on

" Set matching pairs of characters and highlight matching brackets
set matchpairs+=<:>,「:」,『:』,【:】,":",':',《:》

set number relativenumber  " Show line number and relative line number

" Ignore case in general, but become case-sensitive when uppercase is present
set ignorecase smartcase

" File and script encoding settings for vim
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1

" Break line at predefined characters
set linebreak
" Character to show before the lines that have been soft-wrapped
set showbreak=↪

set fileformats=unix,dos  " Fileformats to use for new files

" Ask for confirmation when handling unsaved or read-only files
set confirm

set visualbell noerrorbells  " Do not use visual and errorbells
set history=500  " The number of command and search history to keep

" Use list mode and customized listchars
set list listchars=tab:▸\ ,extends:❯,precedes:❮,nbsp:␣

" Auto-write the file based on some condition
set autowrite

set title


" Completion behaviour
" set completeopt+=noinsert  " Auto select the first completion entry
set completeopt+=menuone  " Show menu even if there is only one item
set completeopt-=preview  " Disable the preview window

set pumheight=10  " Maximum number of items to show in popup menu

" Insert mode key word completion setting
set complete+=kspell complete-=w complete-=b complete-=u complete-=t

set shiftround

set virtualedit=block  " Virtual edit is useful for visual block edit

set formatoptions+=mM

set tildeop

set synmaxcol=200  " Text after this column number is not highlighted
set nostartofline

set termguicolors

set guicursor=n-v-c:block-Cursor/lCursor,i-ci-ve:ver25-Cursor2/lCursor2,r-cr:hor20,o:hor20

" Remove certain character from file name pattern matching
set isfname-==
set isfname-=,

set nowrap  " do no wrap
set autochdir " create file in child folder instead of parent folder
set rtp+=~/.fzf


let mapleader="," 

nnoremap <leader>h :noh<CR> " toggle search highlighting
map <leader>vd :call ToggleThemeMode('dark')<CR>
map <leader>va :call ToggleThemeMode('')<CR>

" Exit terminal mode by C-d
" tnoremap jj <C-\><C-n><CR>
" nnoremap <leader>sp :sp term://cmd<CR> " Add cmd below
" nnoremap <leader>vsp :vsp term://cmd<CR> " Add cmd left

" Toggle Word wrap
nnoremap <A-z> :set wrap!<CR>
 
" Ctrl Backspace to cw
imap <C-BS> <C-W>

" scroll to begin line from previous end line
nnoremap o 0o

" go to start and end line
nnoremap <leader>s 0
nnoremap <leader>e $
vnoremap <leader>s 0
vnoremap <leader>e $


vnoremap y "*y
nnoremap y "*y
nnoremap p "*p
vnoremap p pgvy
nnoremap <leader>p p

" vnoremap c "_c
" vnoremap C "_C
" vnoremap <leader>c c
" vnoremap <leader>C C
" nnoremap c "_c
" nnoremap C "_C
" nnoremap <leader>c c
" nnoremap <leader>C C
" vnoremap d "_d
" vnoremap D "_D
" vnoremap <leader>d d
" vnoremap <leader>D D
" nnoremap d "_d
" nnoremap D "_D
" nnoremap <leader>d d
" nnoremap <leader>D D
" vnoremap x "_x
" vnoremap X "_X
" vnoremap <leader>x x
" vnoremap <leader>X X
" nnoremap x "_x
" nnoremap X "_X
" nnoremap <leader>x x
" nnoremap <leader>X X


" let key_not_cut = ["c", "d", "x"]
" let modes = ['v', 'n']

" for key in key_not_cut
"   for mode in modes
"     " let query = mode.'noremap '.key . ' "_' . key
"     " echo query
"     " execute query
" 
"     execute mode.'noremap '.key . ' "_' . key
"     echo mode.'noremap '.key . ' "_' . key
"     execute mode.'noremap '.toupper(key) . ' "_' . toupper(key)
"     echo mode.'noremap '.toupper(key) . ' "_' . toupper(key)
"     execute mode.'noremap <leader>'.key . ' ' . key 
"     echo mode.'noremap <leader>'.key . ' ' . key 
"     execute mode.'noremap <leader>'.toupper(key) . ' ' . toupper(key)
"     echo mode.'noremap <leader>'.toupper(key) . ' ' . toupper(key)
"     
"   endfor
" endfor


" Backspace to remove tab previous
set backspace=indent,eol,start

"Map jj to ESC" 
inoremap jj <ESC>

inoremap { {}<Esc>ha
inoremap ( ()<Esc>ha
inoremap [ []<Esc>ha
inoremap " ""<Esc>ha
inoremap ' ''<Esc>ha
inoremap ` ``<Esc>ha

" Use ctrl-[hjkl] to select the active split
nnoremap <silent> <C-k> <c-w>k<CR>
nnoremap <silent> <C-j> <c-w>j<CR>
nnoremap <silent> <C-h> <c-w>h<CR>
nnoremap <silent> <C-l> <c-w>l<CR>

nnoremap <silent> <C-u> <C-u>zz<CR>
nnoremap <silent> <C-d> <C-d>zz<CR>

" Toggle NERDTree
" nnoremap <C-b> :NERDTreeToggle<CR>


" [Format Python code in vim](https://www.linuxtut.com/en/4ae1b9ac504567ad4142/)
nmap <leader>f :silent %!autopep8 --ignore=E501 -<CR>

inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

let g:pyindent_open_paren = 'shiftwidth()'
