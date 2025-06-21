# ALIASES AND FUNCTIONS

# system aliases and functions
# WSL
function cdw { cd $(wslpath "$1"); }
# Windows
alias e='explorer.exe'
# Linux
alias sudo='sudo ' # https://askubuntu.com/a/22043
alias apthistory='cat /var/log/apt/history.log | grep Commandline'
