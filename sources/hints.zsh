#
# zaw-src-hints
#
# Show hints file stored in $ZSHHINTSDIR using one of the zsh-hints widgets
#

zmodload zsh/system
autoload -U fill-vars-or-accept

ZSHHINTSDIR="${ZSHHINTSDIR:-"${HOME}/.oh-my-zsh/custom/hints"}"

function zaw-src-hints() {
    if [[ -d "${ZSHHINTSDIR}" ]]; then
        candidates=($(print $ZSHHINTSDIR/*.hints(:t:r)))
    fi
    actions=("zaw-hint-show")
    act_descriptions=("show hint")
    options=()
}

for hint in $ZSHHINTSDIR/*.hints(:t:r)
do
    zle -N "zsh-hints-$hint" zsh-hints
done

zaw-register-src -n hints zaw-src-hints


#
# helper functions for hints
#

function zaw-hint-show() {
    local ZSHHINTSWIDGET="zsh-hints-$@"
    eval "zle zsh-hints-$@"
}


