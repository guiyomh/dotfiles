#!/bin/sh

sudo apt-get install exuberant-ctags
ln -s vimrc ~/.vimrc
ln -s vim ~/.vim

mkdir -p ~/.fonts/
cp fonts/PowerlineSymbols.otf ~/.fonts/
cp -r fonts/powerline/* ~/.fonts/
fc-cache -vf ~/.fonts
