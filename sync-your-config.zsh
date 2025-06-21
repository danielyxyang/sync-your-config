# determine platform
if [[ -z "${_SYC_OS}" ]]; then
  case "$(uname -a)" in
    *WSL*)   _SYC_OS="Linux_WSL" ;;
    Linux*)  _SYC_OS="Linux" ;;
    Darwin*) _SYC_OS="Mac" ;;
    MINGW*)  _SYC_OS="Windows" ;;
    *Msys)   _SYC_OS="Windows" ;;
    *)       _SYC_OS="unknown_$(uname)" ;;
  esac
fi

if [[ -z "${_SYC_HOSTNAME}" ]]; then
  if [[ -f "${HOME}/.syc_hostname" ]]; then
    _SYC_HOSTNAME="$(cat ${HOME}/.syc_hostname)"
  else
    _SYC_HOSTNAME="$(hostname)"
  fi
fi

# define environment variables

export SYC="${HOME}/.config/syc"

export SYC_BOOTSTRAPCONFIG="${SYC}/bootstrap"
export SYC_GLOBALCONFIG="${SYC}/global"
export SYC_OSCONFIG="${SYC}/os/${_SYC_OS}"
export SYC_LOCALCONFIG="${SYC}/local/${_SYC_HOSTNAME}-${_SYC_OS}"
export SYC_SHARE="${SYC}/share"

# define general helper commands

# function # _syc_log {
#   echo -n "[syc] " >&2
#   echo $* >&2
# }

function _syc_confirm_prompt {
  read -r -k 1 "REPLY?$1 [y/n] " # BASH use -n 1 -p "PROMPT"
  [[ "${REPLY}" != $'\n' ]] && echo >&1
  case "${REPLY}" in
    [yY]) return 0 ;;
    *)    return 1 ;;
  esac
}

function _syc_funcname {
  local funcname="${funcstack[2]}" # BASH use ${FUNCNAME[1]}
  funcname="${funcname#_}" # remove prefix _
  funcname="${funcname/::/ }" # replace :: with space
  echo "${funcname}"
}

# define SYC helper commands

function _syc_configfolder {
  case "$1" in
    global)   echo "${SYC_GLOBALCONFIG}" ;;
    os)       echo "${SYC_OSCONFIG}" ;;
    local)    echo "${SYC_LOCALCONFIG}" ;;
    *)        echo "Target $1 unknown." >&2; return 1 ;;
  esac
}

function _syc_ln {
  if [[ "${_SYC_OS}" == "Windows" ]]; then
    # https://stackoverflow.com/a/40914277
    MSYS=winsymlinks:nativestrict ln "$@" # requires admin privileges
    (( $? == 0 )) || {
      echo "You require admin privileges to create symbolic links." >&2
      return 1
    }
  else
    ln "$@"
  fi
}

_SYC_SOURCED=()
function _syc_source {
  source "$1"
  _SYC_SOURCED+=("${2:-$1}")
}

function _syc_bootstrap {
  local target target_path
  # source config with increasing specificity
  for target in "global" "os" "local"; do
    target_path="$(_syc_configfolder ${target})/$1"
    if [[ $? == 0 && -f "${target_path}" ]]; then
      _syc_source "${target_path}" "SYC/${target}/$1"
    fi
  done
}

# define SYC CLI

function syc {
  (( $# > 0 )) || {
    _syc::help
    return 1
  }

  local command="$1"
  shift

  # check existence of function
  type "_syc::$command" &>/dev/null || {
    _syc::help
    return 1
  }

  # run command
  _syc::$command "$@"
}

function _syc::help {
  cat >&2 <<EOF
Usage: syc <command> [options]

Available commands:

  help        Print this help message.
  sourced     List all sourced shell config files.

  create      Create a config file within the scope.
  show        Show the config file within the scope,
  edit        Edit the config file within the scope.
  list        List all config files within the scope.

  bootstrap   Link the config file to its bootstrapped version.
  link        Link the config file to its scoped version.
  unlink      Replace the link with a copy of the config file.

  status      Show the current sync status.
  sync        Synchronize all config files.

EOF
}

function _syc::sourced {
  printf "%s\n" "${_SYC_SOURCED[@]}"
}

function _syc::create {
  (( $# == 2 )) || {
    echo "Usage: $(_syc_funcname) [global|os|local] <target>"
    return 1
  }
  # set target path
  local target_path
  target_path="$(_syc_configfolder $1)/$2"
  (( $? == 0 )) || return 1
  # create parent folder and config file
  mkdir -p "$(dirname ${target_path})"
  vi "$target_path"
}

function _syc::show {
  (( $# == 2 )) || {
    echo "Usage: $(_syc_funcname) [global|os|local] <target>"
    return 1
  }
  # set target path
  local target_path
  target_path="$(_syc_configfolder $1)/$2"
  (( $? == 0 )) || return 1
  # show config file
  less "$target_path"
}

function _syc::edit {
  (( $# == 2 )) || {
    echo "Usage: $(_syc_funcname) [global|os|local] <target>"
    return 1
  }
  # set target path
  local target_path
  target_path="$(_syc_configfolder $1)/$2"
  (( $? == 0 )) || return 1
  # edit config file
  vi "$target_path"
}

function _syc::list {
  (( $# >= 1 )) || {
    echo "Usage: $(_syc_funcname) [global|os|local]"
    return 1
  }
  # set target path
  local target_folder
  target_folder="$(_syc_configfolder $1)"
  (( $? == 0 )) || return 1
  # list config files in target path
  ls -l -A -h "${target_folder}"
}

function _syc::bootstrap {
  (( $# == 1 )) || {
    echo "Usage: $(_syc_funcname) <source>"
    return 1
  }

  # set source and target path
  local source_path target_path
  source_path=$1
  target_path="${SYC_BOOTSTRAPCONFIG}/$(basename $1)"

  # link to bootstrap file
  if [[ -e "${source_path}" && ! -L "${source_path}" ]]; then
    if _syc_confirm_prompt "Would you like to replace '${source_path}' with symlink?"; then
      # replace config file with symlink (after creating a backup)
      _syc_ln -s --backup "${target_path}" "${source_path}"
      (( $? == 0 )) || return 1
    else
      return 1
    fi
  else
    # replace symlink with new symlink
    _syc_ln -s --force "${target_path}" "${source_path}"
    (( $? == 0 )) || return 1
  fi
  echo "'${source_path}' -> '${target_path}'"
}

function _syc::link {
  (( $# >= 2 )) || {
    echo "Usage: $(_syc_funcname) [global|os|local] <source> {<target>}"
    return 1
  }

  # set source path
  local source_path source_file
  source_path="$2"
  source_file="$(basename $2)"

  # set target path
  local target target_folder target_file target_path
  target="$1"
  target_folder="$(_syc_configfolder $1)"
  (( $? == 0 )) || return 1
  target_file="${3:-${source_file}}"
  target_path="${target_folder}/${target_file}"

  # link config file
  if [[ -e "${source_path}" && ! -L "${source_path}" ]]; then
    if [[ ! -e "${target_path}" ]] || _syc_confirm_prompt "Would you like to replace '${target}/${target_file}' with '${source_path}'?"; then
      # move config file to target folder and create symlink
      mkdir -p "$(dirname ${target_path})"
      mv "${source_path}" "${target_path}"
      _syc_ln -s "${target_path}" "${source_path}"
      (( $? == 0 )) || { mv "${target_path}" "${source_path}"; return 1; }
    elif _syc_confirm_prompt "Would you like to replace '${source_path}' with symlink?"; then
      # replace config file with symlink (after creating a backup)
      _syc_ln -s --backup "${target_path}" "${source_path}"
      (( $? == 0 )) || return 1;
    else
      return 1
    fi
  else
    # replace symlink with new symlink
    _syc_ln -s --force "${target_path}" "${source_path}"
    (( $? == 0 )) || return 1;
  fi
  echo "'${source_path}' -> '${target_path}'"
}

function _syc::unlink {
  (( $# == 1 )) || {
    echo "Usage: $(_syc_funcname) <source>"
    return 1
  }
  # set source and target path
  local source_path target_path
  source_path="$1"
  target_path="$(readlink -n -e $1)"
  [[ -n "${target_path}" ]] || {
    echo "Target file '${target_path}' does not exist."
    return 1
  }
  # replace link with copy of target file
  rm "${source_path}"
  cp "${target_path}" "${source_path}"
  echo "'${source_path}' -/> '${target_path}'"
}

function _syc::status {
  {
    echo "##### Status #####"
    echo
    git -C "${SYC}" -c color.ui=always status
    echo
    echo "##### Changes #####"
    echo
    git -C "${SYC}" -c color.ui=always diff
  } | less
}

function _syc::sync {
  local flag_dirty local_ahead
  [[ -n "$(git -C "${SYC}" status --porcelain)" ]] && flag_dirty=1 || flag_dirty=0
  (( $(git -C "${SYC}" rev-list --count main...origin/main) != 0 )) && local_ahead=1 || local_ahead=0
  # pull remote changes
  local success=1
  echo
  echo "##### Pulling remote changes #####"
  echo
  if (( flag_dirty )); then
    git -C "${SYC}" add . # stage all changes first to avoid non-zero return code when applying stash with only untracked files
    git -C "${SYC}" stash -q
    git -C "${SYC}" pull --rebase || success=0
    git -C "${SYC}" stash apply --index -q || success=0
  else
    git -C "${SYC}" pull --rebase || success=0
  fi
  if (( ! success )); then
    echo
    git -C "${SYC}" status
    echo "CONFLICT: Please resolve the synchronization conflicts."
    return 1
  fi
  echo
  # commit and push local changes
  if (( flag_dirty )) || (( local_ahead )); then
    echo
    echo "##### Pushing local changes #####"
    echo
    git -C "${SYC}" status
    read "REPLY?Commit message [sync]: "
    git -C "${SYC}" commit -m "${REPLY:-sync}"
    git -C "${SYC}" push
    echo
  fi
}
