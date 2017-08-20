#!/usr/bin/env bash

fkill() {
  pid=$(ps -ef | sed 1d | fzf -m --preview="ps -p {2}" --preview-window=down:3 | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    kill -${1:-9} $pid
  fi
}

fkill "$@"
