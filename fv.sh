#!/usr/bin/env bash

declare -r esc=$'\033'
declare -r c_reset="${esc}[0m"
declare -r c_red="${esc}[31m"

err() {
  printf "${c_red}%s${c_reset}\n" "$*" >&2
}

die() {
  [[ -n "$1" ]] && err "$1"
  exit 1
}

has() {
  local verbose=0
  if [[ $1 == '-v' ]]; then
    verbose=1
    shift
  fi
  for c; do c="${c%% *}"
    if ! command -v "$c" &> /dev/null; then
      (( verbose > 0 )) && err "$c not found"
      return 1
    fi
  done
}

usage() {
  more <<'HELP'
fv [OPTIONS] [SEARCH]
fuzzy file filtering and command executing

-c    command to execute [defaults to vim]
-a    search all dirs and hidden files (still quirky)
-d    detach from terminal via nohup
HELP
}

set_cmd() {
   if has "$1"; then
    cmd="$1"
  else
    die "$1 is not a valid command"
  fi
}

declare cmd='vim'
declare cmdopts=()
declare search_str=''
declare search_cmd=''
declare search_opts=()
declare allfiles=0

while getopts "hadlc:" opt; do
  case "$opt" in
    h) usage; exit 0        ;;
    a) allfiles=1           ;;
    c) set_cmd "$OPTARG"     ;;
    d) unset detach         ;;
    l) search_opts+=( '-l' ) ;;
  esac
done
shift "$((OPTIND-1))"

has -v 'fzf' || die

for c in 'ag' 'ack' 'grep'; do
  if has "$c"; then
    search_cmd="$c"
    break
  fi
done

if [[ "$search_cmd"  == 'grep' ]]; then
  err 'grep is slow, you should strongly consider installing ag or ack'
  sleep .5
fi

if [[ -n "$1" ]]; then
  if [[ -d "$1" ]]; then
    search_opts+=( "$1" )
  else
    search_str="$1"
  fi
  shift
fi

case "$search_cmd" in
  'ag')
    search_opts+=( '--color' )
    if [[ "$allfiles" == 1 ]]; then
      search_opts+=( '-u' '--hidden' )
    fi
    if [[ "$search_str" == '' ]]; then
      search_opts+=( '-l' )
    fi
    ;;
  'ack')
    if [[ "$search_str" == '' ]]; then
      if [[ "$allfiles" == 0 ]]; then
        search_opts+=( '-g' '^[^\.]' )
      else
        search_opts+=( '-f' )
      fi
    else
      search_opts+=( '-l' )
    #   search_opts+=( '--match' )
    fi
    ;;
  'grep')
    search_opts+=( '-r' '-I' )
    if [[ "$allfiles" == 0 ]]; then
      search_opts+=( '--exclude-dir=bower_components' )
      search_opts+=( '--exclude-dir=node_modules' )
      search_opts+=( '--exclude-dir=jspm_packages' )
      search_opts+=( '--exclude-dir=.cvs' )
      search_opts+=( '--exclude-dir=.git' )
      search_opts+=( '--exclude-dir=.hg' )
      search_opts+=( '--exclude-dir=.svn' )
    fi
    if [[ "$search_str" == '' ]]; then
      search_opts+=( '' )
    fi
    ;;
esac

if [[ "$search_str" != '' ]]; then
  search_opts+=( "$search_str" )
fi

choices=$($search_cmd "${search_opts[@]}" 2> /dev/null |
  fzf --ansi --cycle --multi) || exit 1

if [[ "$search_str" != '' ]]; then
  if [[ $search_cmd == 'ag' ]]; then
    choices=$(cut -d: -f1 <<< "$choices")
  fi
fi

mapfile -t choices <<< "$choices"

$cmd "${cmdopts[*]}" "${choices[@]}"
