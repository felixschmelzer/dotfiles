# Felix Dotfiles

A collection of my personal dotfiles — version-controlled and easy to deploy across systems using GNU Stow.

---

## Prerequisites

This configuration includes setups for:

- `zsh`
- `tmux`
- `tmuxifier`
- `neovim`
- `zoxide`
- `fzf`
- `oh-my-posh`
- `neovim`

  
---

## Cloning the Repository

Make sure to clone the repository **recursively** to also fetch the required submodules (such as the Neovim config):
```bash
git clone --recurse-submodules https://github.com/felixschmelzer/dotfiles.git
```

## Installation Using GNU Stow

To symlink all config files into your home directory, navigate into the repo and run:
```bash
stow .
```

## Tmux Plugin Manager (TPM)

To enable plugin management in tmux, you’ll need to install TPM (Tmux Plugin Manager). Run:
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
Once installed, open a tmux session and press prefix + I (usually Ctrl + b, then I) to install the plugins.


