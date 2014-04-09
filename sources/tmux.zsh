# -*- mode:sh -*-
#
# zaw-src-tmux
#
# select tmux session and attach it
#

function zaw-src-tmux() {
    local session state

    tmux list-sessions | \
        while read session state; do
            candidates+=("${session}")
            cand_descriptions+=("${(r:30:::::)session} ${state}")
        done
        actions=('zaw-callback-tmux-attach')
        act_descriptions=('attach session')
        actions+=('zaw-callback-tmux-dettach')
        act_descriptions+=('detach session')
}

zaw-register-src -n tmux zaw-src-tmux

function zaw-callback-tmux-attach() {
    BUFFER="tmux attach -t ${(q)1}"
    zle accept-line
}

function zaw-callback-tmux-dettach() {
    BUFFER="tmux kill-session -t ${(q)1}"
    zle accept-line
}
