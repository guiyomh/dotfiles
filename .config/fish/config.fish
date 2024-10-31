if status is-interactive
    # Commands to run in interactive sessions can go here
end
eval "$(/opt/homebrew/bin/brew shellenv)"
starship init fish | source

alias ls="eza"
alias ll="eza -l"
alias la="eza -la"

set -x EDITOR nvim

# Github
set -x GH_EDITOR nvim

# devfactory
set -x DEVFACTORY_PATH /Users/guillaume/workspace/ornikar/devfactory
set -x ONK_PATH /Users/guillaume/workspace/ornikar/onk
# end devfactory

# pnpm
set -gx PNPM_HOME /Users/guillaume/Library/pnpm
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# rust
source "$HOME/.cargo/env.fish"
# end rust

# GPG #
set -x GPG_TTY (tty)
# end GPG#

# neofetch
# keep this at the end of the file
# neofetch
# end neofetch
