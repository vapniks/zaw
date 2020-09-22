#
# zaw-dirs
#
# zaw source for selecting a directory/file using cdargs & fasd bookmarks.
# Order fasd bookmarks by score (higher scores before lower scores).
#

function zaw-src-dirs() {
    local root parent d f
    setopt local_options null_glob

    if (( $# == 0 )); then
	# get candidates from ~/.cdargs & fasd
	local -A cdargs
	local -a fasd
	if [[ -r ~/.cdargs ]]; then
	    set -A cdargs $(cat ~/.cdargs)
	fi
	if [[ $(command -v fasd) ]]; then
	    fasd=($(fasd -sR|sort -k1 -rn|awk '{print $2}'))
	fi
	candidates=("${(@)fasd}" "${(@v)cdargs}")
	cand_descriptions=("${(@)fasd}" "${(@k)cdargs}")
	#options=( "-t" "Press Enter to insert, or Alt+Enter to navigate" )
    else
        root="$1"
	parent="${root:h}"
	if [[ "${parent}" != */ ]]; then
            parent="${parent}/"
	fi
	candidates+=("${parent}")
	cand_descriptions+=("../")
	# TODO: symlink to directory
	for d in "${root%/}"/*(/); do
            candidates+=("${d}/")
            cand_descriptions+=("${d:t}/")
	done
	for f in "${root%/}"/*(^/); do
            candidates+=("${f}")
            cand_descriptions+=("${f:t}")
	done
	#options=( "-t" "${root}" )
    fi

    if zmodload -e zsh/regex && [[ "$LBUFFER" =~ "\w" ]]; then
	actions=( "zaw-callback-append-to-buffer" "zaw-callback-cdargs" )
	act_descriptions=( "append to edit buffer" "open file or directory" )
    else
	actions=( "zaw-callback-cdargs-cd" "zaw-callback-cdargs" "zaw-callback-append-to-buffer" )
	act_descriptions=( "change directory" "open file or directory" "append to edit buffer" )
    fi
    
}

zaw-register-src -n dirs zaw-src-dirs

function zaw-callback-dirs() {
    if [[ -d "$1" ]]; then
        zaw zaw-src-dirs "$1"
    else
	zaw zaw-callback-append-to-buffer "$1"
    fi
}

function zaw-callback-dirs-cd() {
    if [[ -d "$1" ]]; then
	pushd -q $1; pwd
	reset-prompt
    else
	zaw zaw-callback-append-to-buffer "$1"
    fi
}
