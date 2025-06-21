#!zsh

# find SYC directory (parent folder of this script)
SYC="${0:a:h}" # BASH use "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# source SYC functions
source "${SYC}/sync-your-config.zsh"

# link config files
syc bootstrap ~/.zshrc
syc link global ~/.p10k.zsh
syc link global ~/.gitconfig

# refresh the shell
exec zsh
