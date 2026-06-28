# macsetup

Personal macOS bootstrap for a new Mac.

This installs Homebrew, applies the packages in `Brewfile`, copies this repo's `.zshrc` into `~/.zshrc` with a timestamped backup when needed, and applies common macOS defaults.

## New Mac One-Liner

```sh
/bin/bash -c 'set -euo pipefail; tmp="$(mktemp -d)"; curl -fsSL https://github.com/techluma/macsetup/archive/refs/heads/main.tar.gz | tar -xz -C "$tmp" --strip-components=1; cd "$tmp"; ./bootstrap.sh'
```

That one-liner downloads the repo into a temporary directory and runs `bootstrap.sh` from there, so `Brewfile` and `.zshrc` are available next to the script. The script installs Homebrew if needed, runs `brew bundle`, installs the shell config, and applies macOS defaults.

## Safer Clone-And-Run Option

```sh
git clone https://github.com/techluma/macsetup.git ~/Documents/macsetup
cd ~/Documents/macsetup
./bootstrap.sh
```

## Create This Repo On GitHub

From this directory:

```sh
git init
git add Brewfile bootstrap.sh .zshrc README.md
git commit -m "Initial mac setup"
gh repo create macsetup --private --source=. --remote=origin --push
```

Use `--public` instead of `--private` if you want the repo public.

## What It Installs

Core CLI tools include Git, GitHub CLI, Python, Node, tmux, ripgrep, fd, jq, wget, tree, fzf, bat, eza, zoxide, watch, uv, and just.

It also installs Docker/Colima tooling, the Mac App Store CLI helper, and common GUI apps such as Visual Studio Code, iTerm2, Rectangle, Raycast, Google Chrome, Bitwarden, AnyDesk, ChatGPT, Codex, Synology Drive, and Stats.

## Shell Setup

The included `.zshrc` configures Homebrew paths, completions, history, `fzf`, `zoxide`, macOS helpers, and aliases for the installed tools.

Notable aliases:

```sh
cat      # bat --paging=never
ls       # eza
ll       # eza long listing with git status
find     # fd
grep     # rg
dc       # docker compose
j        # just
t        # tmux
```
