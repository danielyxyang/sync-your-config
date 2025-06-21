# source SYC commands
source "$HOME/.config/syc/sync-your-config.zsh"

# source oh-my-zsh configurations
_syc_bootstrap ".zshrc-omz"
# source oh-my-zsh
[[ -z $ZSH ]] || _syc_source $ZSH/oh-my-zsh.sh
# source powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || _syc_source ~/.p10k.zsh
# source profile
_syc_bootstrap ".zshrc"
