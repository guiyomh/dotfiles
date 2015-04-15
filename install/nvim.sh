#!/usr/bin/env bash



echo -e "\\n\\nnvim Plugin"
echo "====================="

#cd ~/.vim/bundle/YouCompleteMe
#git submodule update --init --recursive
#python3 install.py --system-libclang --clang-completer --go-completer --js-completer --rust-completer

nvim +PlugInstall +qall