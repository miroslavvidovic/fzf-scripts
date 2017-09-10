#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Info:
#   author:    Miroslav Vidovic
#   file:      fbookie.sh
#   created:   08.09.2017.-12:52:49
#   revision:
#   version:   1.0
# -----------------------------------------------------------------------------
# Requirements:
#  bookie, fzf
# Description:
# 
# Usage:
#
# -----------------------------------------------------------------------------
# Script:

# Path to bookie
BOOKIE=~/Projekti/Github/bookie/src/bookie

main() {
  url=$($BOOKIE -l \
    | tr -d '\)' \
    | fzf --ansi --preview="$BOOKIE -b  {1}" --preview-window=down:8)

  xdg-open "$(echo "$url" | awk '{print $2}')"
}

main

exit 0
