#!/usr/bin/env bash

UNAME=$(uname | tr '[:upper:]' '[:lower:]')

if [ "${UNAME}" != "darwin" ]; then
    echo "This script is OSX-only. Please do not run it on any other Unix."
    exit 1
fi


if test ! "$( command -v brew )"; then
    echo -e "\\n\\nInstalling homebrew"
    echo "=============================="
    ruby -e "$( curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install )"
else
    echo -e "\\n\\nUpdating Homebrew Software"
    echo "=============================="
    brew update
fi

echo -e "\\n\\nInstalling homebrew packages..."
echo "=============================="

brew bundle --file Brewfile

# # After the install, setup fzf
# echo -e "\\n\\nRunning fzf install script..."
# echo "=============================="
# /usr/local/opt/fzf/install --all --no-bash --no-fish

# # after the install, install neovim python libraries
# echo -e "\\n\\nRunning Neovim Python install"
# echo "=============================="
# pip3 install --user neovim

# # Change the default shell to zsh
# zsh_path="$( command -v zsh )"
# if ! grep "$zsh_path" /etc/shells; then
#     echo "adding $zsh_path to /etc/shells"
#     echo "$zsh_path" | sudo tee -a /etc/shells
# fi

# if [[ "$SHELL" != "$zsh_path" ]]; then
#     chsh -s "$zsh_path"
#     echo "default shell changed to $zsh_path"
# fi