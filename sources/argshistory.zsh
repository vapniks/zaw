zmodload zsh/parameter

# This plugin produces a list of command-line arguments extracted from the history.
# You can set the number of history lines to search with the args_numlines style
# like this: zstyle ':filter-select:*' args_numlines 100
# The default value is 200

function zaw-src-argshistory() {
    typeset -L numlines 
    zstyle -s ':filter-select:*' args_numlines numlines
    typeset -aU args=("${(Z:C:)$(fc -nl -${numlines:-200} -1)}")
    args=(${args:#(?|??|*$'\n'*)})
    local -a keys=($(seq 1 $#args))
    cands_assoc=(${keys:^args})
    # have filter-select reverse the order (back to latest command first).
    # somehow, `cands_assoc` gets reversed while `candidates` doesn't. 
    src_opts=("-r" "-m")
    actions=("zaw-callback-append-to-buffer")
    act_descriptions=("append to edit buffer")
}

zaw-register-src -n argshistory zaw-src-argshistory
