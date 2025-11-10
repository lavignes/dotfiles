set nocompatible
set encoding=utf-8

call plug#begin('~/.vim/plugged')
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'itchyny/lightline.vim'
Plug 'preservim/nerdtree'

Plug 'ntpeters/vim-better-whitespace'
Plug 'dhruvasagar/vim-table-mode'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'mg979/vim-visual-multi', { 'branch': 'master' }
Plug 'fidian/hexmode'

Plug 'kamykn/spelunker.vim'
Plug 'kamykn/popup-menu.nvim'

Plug 'github/copilot.vim'
Plug 'DanBradbury/copilot-chat.vim'

" languages
Plug 'bfrg/vim-cpp-modern'
Plug 'lavignes/smasm', { 'rtp': 'vim' }
Plug 'lavignes/snesgame', { 'rtp': 'tools/asm/vim' }
Plug 'jgm/djot', { 'rtp': 'editors/vim' }
Plug 'kylelaker/riscv.vim'
Plug 'DingDean/wgsl.vim'

" colorschemes
Plug 'rafi/awesome-vim-colorschemes'
Plug 'lmintmate/blue-mood-vim'
Plug 'sainnhe/everforest'
Plug 'mcchrish/zenbones.nvim'
Plug 'mswift42/vim-themes'
call plug#end()

" Coc Settings
" ensure vim and nvim use the same coc-config
let g:coc_config_home = '~/.vim/'

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

" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" enable :Termdebug
packadd! termdebug
let g:termdebug_wide=1
autocmd FileType rust let termdebugger="rust-gdb"
autocmd FileType c let termdebugger="gdb"

" enable :Man command
runtime! ftplugin/man.vim

" make tables markdown-compatible
let g:table_mode_corner='|'

" vim-cpp-modern settings
let g:cpp_member_highlight=1
autocmd BufRead,BufNewFile *.h,*.c set filetype=c

" use bytes in Hexmode
let g:hexmode_xxd_options='-g 1'

" F1 toggles NERDTree
nnoremap <F1> :NERDTreeMirror<CR>:NERDTreeToggle<CR>
" Close vim if NERDTree is the only thing open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree")
      \ && b:NERDTree.isTabTree()) | q | endif
let NERDTreeMinimalUI=1
let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'
let NERDTreeIgnore=['\.o$', '\.d$', '\.tst$'] " ignore certain files

" Copilot settings
inoremap <silent><script><expr> <F9> copilot#Next()
inoremap <silent><script><expr> <F11> copilot#AcceptWord("\<CR>")
inoremap <silent><script><expr> <F12> copilot#Accept("\<CR>")
let g:copilot_no_tab_map = 1

if (hostname() != "desky")
  let g:copilot_filetypes = {
      \ '*': v:false,
      \ }
endif

" spelunker settings
let g:enable_spelunker_vim = 0
command! -nargs=0 SpellToggle :call spelunker#toggle()
command! -nargs=0 Spell :call spelunker#correct_from_list()

" Sane tabs
nnoremap <S-Tab> <<
inoremap <S-Tab> <C-d>
nnoremap <Tab> >>
inoremap <Tab> <C-I>

" Clipboard
vnoremap <C-c> :w !xclip -sel clipboard<CR><CR>

" On first-run the colorscheme doesn't exist yet :-)
set background=dark
silent! colorscheme madrid

" force style on some items
hi Comment cterm=italic
hi PreProc cterm=bold,italic

" Set visual-multi colorscheme
autocmd VimEnter * :VMTheme nord

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

" Scroll to last edit position when switching buffers
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" don't use colors from terminal
set termguicolors
set noswapfile
set nohidden
set updatetime=300
set nowrap
set linebreak
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
set colorcolumn=80
set expandtab
set shiftwidth=4
set tabstop=4
set cursorline
set guicursor=n-v-c-i:block
