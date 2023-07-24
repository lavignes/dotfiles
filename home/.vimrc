set nocompatible
set encoding=utf-8

call plug#begin('~/.vim/plugged')
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'itchyny/lightline.vim'
Plug 'preservim/nerdtree'
Plug 'puremourning/vimspector'

Plug 'ntpeters/vim-better-whitespace'
Plug 'dhruvasagar/vim-table-mode'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'mg979/vim-visual-multi', { 'branch': 'master' }

" languages
Plug 'lavignes/az65-vim'
Plug 'lavignes/pasm.vim'
Plug 'kylelaker/riscv.vim'
Plug 'DingDean/wgsl.vim'

" colorschemes
Plug 'rafi/awesome-vim-colorschemes'
Plug 'lmintmate/blue-mood-vim'
Plug 'sainnhe/everforest'
call plug#end()

" ensure vim and nvim use the same coc-config
let g:coc_config_home = '~/.vim/'

packadd! termdebug
let g:termdebug_wide=1
autocmd FileType rust let termdebugger="rust-gdb"

sign define vimspectorBP text=o             texthl=WarningMsg
sign define vimspectorBPCond text=o?        texthl=WarningMsg
sign define vimspectorBPLog text=!!         texthl=SpellRare
sign define vimspectorBPDisabled text=o!    texthl=LineNr
sign define vimspectorPC text=\ >           texthl=MatchParen
sign define vimspectorPCBP text=o>          texthl=MatchParen
sign define vimspectorCurrentThread text=>  texthl=MatchParen
sign define vimspectorCurrentFrame text=>   texthl=Special

let g:vimspector_enable_mappings = 'HUMAN'
let g:vimspector_configurations = {
    \ 'rust': {
    \   'adapter': 'CodeLLDB',
    \   'filetypes': [ 'rust' ],
    \   'configuration': {
    \     'type': 'lldb',
    \     'request': 'launch',
    \     'program': '${Executable}',
    \     'args': [ '*${Args}' ],
    \     'sourceLanguages': [ 'rust' ],
    \     'breakpoints': {
    \       'exception': {
    \         'cpp_throw': 'Y',
    \         'cpp_catch': 'N',
    \       },
    \     },
    \   },
    \ },
    \ }

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
vnoremap <C-c> :w !xclip -sel clipboard<CR><CR>

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

set background=dark
" On first-run the colorscheme doesn't exist yet :-)
silent! colorscheme jellybeans

" Set visual-multi colorscheme
autocmd VimEnter * :VMTheme purplegray

let g:lightline = {
	\ 'colorscheme': 'jellybeans',
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

" Scroll to last edit position when switching buffers
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" Make popup menu colors not hard to read
hi Pmenu ctermbg=black ctermfg=white

set termguicolors
set noswapfile
set updatetime=300
set nowrap
set laststatus=2
set cmdheight=2
set noshowmode
set mouse=a
if !has('nvim')
    set ttymouse=sgr
endif
set modeline
set backspace=indent,eol,start
set splitright
set number
set wildmenu
set wildmode=longest,full
set colorcolumn=100
set expandtab
set shiftwidth=4
set tabstop=4
set cursorline
