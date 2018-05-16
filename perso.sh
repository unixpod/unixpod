#!/bin/bash

vimrc() {
	wget https://raw.githubusercontent.com/unixpod/unixpod/master/.vimrc -O ~/.vimrc
}

init() {
	mkdir -p ~/.vim/autoload/
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

}
init
vimrc
