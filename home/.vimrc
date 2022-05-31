set nocompatible
set encoding=utf-8

let g:vimspector_enable_mappings = 'HUMAN'

call plug#begin('~/.vim/plugged')
Plug 'itchyny/lightline.vim'
Plug 'preservim/nerdtree'
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'mg979/vim-visual-multi', { 'branch': 'master' }
Plug 'rafi/awesome-vim-colorschemes'
call plug#end()

packadd! termdebug
let g:termdebug_wide=1

" F1 toggles NERDTree
nnoremap <F1> :NERDTreeMirror<CR>:NERDTreeToggle<CR>
" Close vim if NERDTree is the only thing open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") 
      \ && b:NERDTree.isTabTree()) | q | endif

command! -nargs=0 Rename :call CocActionAsync('rename')
command! -nargs=0 Fmt :call CocAction('format')
command! -nargs=0 Doc :call <SID>show_documentation()
command! -nargs=0 Def :call CocAction('jumpDefinition')
command! -nargs=0 Used :call CocAction('jumpUsed')

command! -nargs=0 RustRun CocCommand rust-analyzer.run
command! -nargs=0 RustDebug CocCommand rust-analyzer.debug

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Use tab for trigger completion with characters ahead and navigate.
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

let g:lightline = {
	\ 'colorscheme': 'deus',
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

" swallow warning on first run since we havent installed it yet
silent! colorscheme challenger_deep 

" Make popup menu colors not hard to read
hi Pmenu ctermbg=black ctermfg=white

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
