# ENVIRONMENT VARIABLES

[[ ! "${PATH}" =~ "${SYC_GLOBALCONFIG}/bin" ]] && {
  export PATH="${SYC_GLOBALCONFIG}/bin:${PATH}"
}
[[ ! "${PATH}" =~ "${HOME}/.local/bin" ]] && {
  export PATH="${HOME}/.local/bin:${PATH}"
}

# ALIASES AND FUNCTIONS

# system aliases and functions
alias refresh='exec zsh'
alias showpath='tr ":" "\n" <<< ${PATH}'
alias less='less -r'
alias timestamp='date "+%Y%m%d-%H%M%S"'

alias ls='ls -F --color=auto --show-control-chars --group-directories-first'
alias lsa='ls --almost-all'
alias ll='ls -l --human-readable'
alias lla='ll --almost-all'

function lt { tree --charset UTF-8 --noreport --dirsfirst -I ".git" -C -L 3 "$@" | less; }
alias lta='lt -a'
alias ltd='lt -d'
alias ltda='ltd -a'

alias duh='du -h -s'
alias dul='du -h -d 1'
function dul-sort { dul "$@" | sort -hr; }

function diff { command diff --color=always --strip-trailing-cr "$@" | less; }
alias sdiff='diff --side-by-side --suppress-common-lines'

alias rsync-get='rsync -vi -rzut'
alias rsync-diff='rsync -vi -rzut -n'

alias ssh='ssh -o AddKeysToAgent=yes'


# application aliases and functions
alias gs='git status'
alias gl='git log --oneline --graph --decorate --exclude=refs/stash --all'
