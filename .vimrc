call plug#begin()
Plug 'tpope/vim-sensible'
Plug 'morhetz/gruvbox'
Plug 'jiangmiao/auto-pairs'
Plug 'horosphere/formatgen'
Plug 'scrooloose/syntastic'
call plug#end()

colorscheme gruvbox
set background=dark
set exrc
set secure
set hidden
set number
set mouse=a
syntax on
set tabstop=4
set shiftwidth=4
set expandtab
set noexpandtab
set colorcolumn=110
highlight ColorColumn ctermbg=darkgray
augroup project
    autocmd!
    autocmd BufRead,BufNewFile *.h,*.c,*.cpp filetype=c.doxygen
augroup END

let &path.="src/include,/usr/include/AL,"
set includeexpr=substitute(v:frame,'\\.','/','g')
set makeprg=make\ -C\ ../build\ -j9
nnoremap <F4> :make!<cr>
nnoremap <F5> :!./my_great_program<cr>
