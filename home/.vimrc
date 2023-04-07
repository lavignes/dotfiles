set nocompatible
set encoding=utf-8

call plug#begin('~/.vim/plugged')
Plug 'itchyny/lightline.vim'
Plug 'preservim/nerdtree'
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'mg979/vim-visual-multi', { 'branch': 'master' }
Plug 'rafi/awesome-vim-colorschemes'
Plug 'wfxr/minimap.vim', { 'do': ':!cargo install --locked code-minimap' }
Plug 'lavignes/az65-vim'
Plug 'ntpeters/vim-better-whitespace'
Plug 'kylelaker/riscv.vim'
Plug 'dhruvasagar/vim-table-mode'
Plug 'lmintmate/blue-mood-vim'
Plug 'puremourning/vimspector'
call plug#end()

packadd! termdebug
let g:termdebug_wide=1
autocmd FileType rust let termdebugger="rust-gdb"

" make tables markdown-compatible
let g:table_mode_corner='|'

" ctrl+p to fzf
nmap <C-P> :FZF<CR>

" F1 toggles NERDTree
nnoremap <F1> :NERDTreeMirror<CR>:NERDTreeToggle<CR>
" Close vim if NERDTree is the only thing open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree")
      \ && b:NERDTree.isTabTree()) | q | endif
let NERDTreeMinimalUI=1
let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'

command! -nargs=0 Rename :call CocActionAsync('rename')
command! -nargs=0 Fmt :call CocAction('format')
command! -nargs=0 Doc :call <SID>show_documentation()
command! -nargs=0 Def :call CocAction('jumpDefinition')
command! -nargs=0 Used :call CocAction('jumpUsed')

command! -nargs=0 Action :call CocActionAsync('codeLensAction')

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"


" Sane tabs
nnoremap <S-Tab> <<
inoremap <S-Tab> <C-d>
nnoremap <Tab> >>
inoremap <Tab> <C-I>

" xclip
vnoremap <C-y> :'<,'>w !xclip -selection clipboard<Cr><Cr>

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

let g:lightline = {
	\ 'colorscheme': 'blue_mood',
	\ 'active': {
	\   'left': [ [ 'mode', 'paste' ],
	\             [ 'cocstatus', 'readonly', 'filename', 'modified' ] ]
	\ },
	\ 'component_function': {
	\   'cocstatus': 'coc#status'
	\ },
	\ }

" Use autocmd to force lightline update.
autocmd User CocStatusChange,CocDiagnosticChange call lightline#update()

function! ExitNormalMode()
    unmap <buffer> <silent> <RightMouse>
    call feedkeys("a")
endfunction

function! EnterNormalMode()
    if &buftype == 'terminal' && mode('') == 't'
        call feedkeys("\<c-w>N")
        call feedkeys("\<c-y>")
        map <buffer> <silent> <RightMouse> :call ExitNormalMode()<CR>
    endif
endfunction

" Automatically enter normal mode in terminal with scroll wheel
tmap <silent> <ScrollWheelUp> <c-w>:call EnterNormalMode()<CR>

" On first-run the colorscheme doesn't exist yet :-)
silent! colorscheme blue-mood

" Make popup menu colors not hard to read
hi Pmenu ctermbg=black ctermfg=white

set termguicolors
set noswapfile
set updatetime=300
set nowrap
set laststatus=2
set cmdheight=2
set mouse=a
set ttymouse=sgr
set modeline
set backspace=indent,eol,start
set splitright
set number
set wildmenu
set wildmode=longest,full
set colorcolumn=120
set expandtab
set shiftwidth=4
set tabstop=4
set cursorline
