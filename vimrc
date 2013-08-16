"
" General behavior
"
set nocompatible " Use vim defaults
filetype off " deactivate filetype for pathogen to load snipmate correctly

"
" Coloration
"
set t_Co=256
"colorscheme jellybeans

" Tabs & Indentation
"
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set autoindent
set smartindent
set list
set listchars=eol:↩,trail:‧,tab:>⁙
if has('gui_running')
    set listchars=eol:↩,trail:‧,tab:>⁙
endif

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"
" PLUGINS CONFIGURATION
"
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


call pathogen#infect()
syntax on

filetype plugin indent on " reactivate filetype as before

set encoding=utf-8
set fileencoding=utf-8

let mapleader="," " Use the comma as leader
set history=1000 " Increase history
set nospell

set showcmd " Display incomplete commands.
set showmode " Display the mode you're in.

set number " Show line numbers.
set ruler " Show cursor position.

set ignorecase " Case-insensitive searching.
set smartcase " But case-sensitive if expression contains a capital letter.
set incsearch " Highlight matches as you type.
set hlsearch " Highlight matches.
set showmatch " Show matching char (like {})

set visualbell " No beeping.

set nobackup " Don't make a backup before overwriting a file.
set nowritebackup " And again.
set noswapfile " Use an SCM instead of swap files


set laststatus=2
let g:airline_theme = "dark"
let g:airline_powerline_fonts=1

let g:symfony_app_console_caller= "php"
let g:symfony_app_console_path= "app/console"

autocmd VimEnter * NERDTree
autocmd VimEnter * Tagbar

" Highlight current line
"set cursorline

"Change line numbers color
autocmd InsertEnter * hi LineNr ctermfg=16 ctermbg=214 guifg=Orange guibg=#151515
autocmd InsertLeave * hi LineNr term=underline ctermfg=59 ctermbg=232 guifg=#605958 guibg=#151515

autocmd BufEnter * hi SpellCap guisp=Orange
autocmd BufEnter * hi Comment gui=NONE

" Remove trailing whitespaces and ^M chars
autocmd FileType php,js,css,html,xml,yaml,vim autocmd BufWritePre <buffer>
:call setline(1,map(getline(1,"$"),'substitute(v:val,"\\s\\+$","","")'))

" Syntastic
let g:syntastic_enable_signs = 1
let g:syntastic_auto_loc_list = 2
let g:syntastic_quiet_warnings = 0
let g:syntastic_enable_balloons = 1

" Disable folding by default
set nofoldenable

"undo
set undolevels=1000 " use many levels of undo
"set noundofile

"activate mouse!
set mouse=a
