# dotfiles

This repo contains all my configs I use.

Based on [this repository](https://github.com/maxhu08/dotfiles/tree/master).

## getting-started

My dotfiles are managed with `stow`, which manages symlinks so that the files in this dotfiles repo are synced with the actual configs.

To get started with using my dotfiles run these commmands:

```shell
# arch
sudo pacman -S stow

# gentoo
doas emerge -av app-admin/stow

git clone https://github.com/Sobaka9/dotfiles
cd dotfiles
```

After that, you just need to run the stow command to symlink the dotfiles you want.

```shell
# you can stow multiple things in one command!
stow alacritty fish nvim picom tmux vscode
```

## install-packages

Make sure to install the programs, stow just symlinks the configs. You still need to install the programs!
