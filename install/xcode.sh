#!/usr/bin/env bash

UNAME=$(uname | tr '[:upper:]' '[:lower:]')

if [ "${UNAME}" != "darwin" ]; then
    echo "This script is OSX-only. Please do not run it on any other Unix."
    exit 1
fi

 if [ $(xcode-select -p &> /dev/null; printf $?) -ne 0 ]; then
    echo -e "\\n\\nInstalling Xcode"
    echo "=============================="
    xcode-select --install &> /dev/null
    # Wait until the XCode Command Line Tools are installed
    while [ $(xcode-select -p &> /dev/null; printf $?) -ne 0 ]; do
        sleep 5
    done
    xcode-select -p &> /dev/null
    if [ $? -eq 0 ]; then
        # Prompt user to agree to the terms of the Xcode license
        # https://github.com/alrra/dotfiles/issues/10
       sudo xcodebuild -license
   fi
fi
