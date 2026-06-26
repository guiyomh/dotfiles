# dotfiles

Personal macOS (Apple Silicon) configuration files, managed with plain symlinks.

The repo mirrors the layout of `$HOME`, so each tracked path is symlinked back into
its expected location (`~/.config/*` and `~/.gitconfig`).

## Contents

| Path                       | Tool      | Notes                                                              |
| -------------------------- | --------- | ------------------------------------------------------------------ |
| `.config/fish/`            | Fish      | Shell config, completions, functions, `fisher` plugins             |
| `.config/nvim/`            | Neovim    | [LazyVim](https://www.lazyvim.org/)-based setup                    |
| `.config/ghostty/`         | Ghostty   | Primary terminal (font, opacity/blur, keybinds)                    |
| `.config/kitty/`           | Kitty     | Secondary terminal (cyberdream transparent theme)                  |
| `.config/starship.toml`    | Starship  | Prompt                                                             |
| `.config/yazi/`            | Yazi      | TUI file manager (placeholder)                                     |
| `.gitconfig`               | Git       | Global git config (GPG signing, aliases, URL rewrites)             |

## Prerequisites

Install [Homebrew](https://brew.sh/), then the tools used by these configs:

```sh
brew install fish starship neovim eza fzf fnm gnupg
brew install --cask ghostty kitty
```

Optional, referenced by the Fish config when present: `rbenv`, `rustup`, `pnpm`,
[OrbStack](https://orbstack.dev/).

Set Fish as the default shell:

```sh
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish
```

## Installation

Clone the repo (the examples assume `~/workspace/perso/dotfiles`, adjust if needed):

```sh
git clone <repo-url> ~/workspace/perso/dotfiles
cd ~/workspace/perso/dotfiles
```

Symlink each config into place. Back up anything you already have at these paths first.

```sh
DOTFILES="$HOME/workspace/perso/dotfiles"

mkdir -p ~/.config

ln -sfn "$DOTFILES/.config/fish"          ~/.config/fish
ln -sfn "$DOTFILES/.config/nvim"          ~/.config/nvim
ln -sfn "$DOTFILES/.config/ghostty"       ~/.config/ghostty
ln -sfn "$DOTFILES/.config/kitty"         ~/.config/kitty
ln -sfn "$DOTFILES/.config/yazi"          ~/.config/yazi
ln -sf  "$DOTFILES/.config/starship.toml" ~/.config/starship.toml
ln -sf  "$DOTFILES/.gitconfig"            ~/.gitconfig
```

> `ln -sfn` replaces an existing symlinked directory cleanly instead of nesting the
> link inside it. Run it only after confirming the target isn't a real directory you
> want to keep.

### Fish plugins

Plugins are declared in `.config/fish/fish_plugins` and managed by
[fisher](https://github.com/jorgebucaran/fisher). After linking the Fish config,
open a new shell and run:

```sh
fisher update
```

This installs `jethrokuan/z` (directory jumping) and `patrickf1/fzf.fish`.

### Neovim

LazyVim bootstraps itself on first launch — just open `nvim` and let it sync plugins.

## Secrets

Local secrets are kept out of version control. `.config/fish/conf.d/credentials.fish`
is gitignored; create it locally for any private environment variables, e.g.:

```fish
set -gx SOME_TOKEN "..."
```

## Git signing

`.gitconfig` enables GPG-signed commits. The global identity uses the work key; this
repo overrides it locally with a personal key:

```sh
git config --local user.email  "you@example.com"
git config --local user.signingkey "<KEY_ID>"
```

Make sure the corresponding GPG key exists in your keyring (`gpg --list-secret-keys`).
