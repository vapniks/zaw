#
# zaw - zsh anything.el-like widget
#
# usage:
#
#   add following line to your .zshrc::
#
#     source /path/to/zaw.zsh
#
#   and type "^X;"

# to create namespace, use anonymous function
function() {

zmodload zsh/parameter
autoload -U is-at-least

local this_file="${funcsourcetrace[1]%:*}"
if is-at-least 4.3.10; then
    # "A" flag (turn a file name into an absolute path with symlink
    # resolution) is only available on 4.3.10 and latter
    local cur_dir="${this_file:A:h}"
else
    local cur_dir="${this_file:h}"
fi
fpath+=("${cur_dir}/functions")

autoload -U filter-select

typeset -g -A zaw_sources
zaw_sources=()

function zaw-register-src() {
    # register zaw source
    #
    # zaw-register-src [-n NAME] SOURCE
    #
    # SOURCE is function name that define (overrite) these variables
    #
    # $candidates        -> array of candidates
    # $cands_assoc       -> assoc array of candidates
    # $cand_descriptions -> (optional) array of candidates descriptions
    # $cand_descriptions_assoc -> (optional) assoc array of candidates descriptions
    # $actions           -> list of callback function names that receive selected item
    # $act_descriptions  -> (optional) list of callback function descriptions
    # $src_opts           -> (optional) array of src_opts passed to filter-select
    #
    # whether one of candidates or cands-assoc is required
    local name func widget_name opts OPTARG OPTIND

    while getopts 'n:' opts; do
        name="${OPTARG}"
    done
    if (( OPTIND > 1 )); then
        shift $(( OPTIND - 1 ))
    fi

    func="$1"

    if [[ -z "${name}" ]]; then
        name="${func}"
    fi

    # TODO: check name duplication
    zaw_sources+=("${name}" "${func}")

    # define shortcut function
    widget_name="zaw-${(L)name// /-}"
    eval "function ${widget_name} { zle zaw ${func} \$@ }"
    eval "zle -N ${widget_name}"
}

function zaw-replace-descriptions-with-action-names() {
    local desc_index="${act_descriptions[(ie)$action_default]}"
    [[ $desc_index -le ${#act_descriptions} ]] && action_default="${actions[$desc_index]}"
    desc_index="${act_descriptions[(ie)$action_alt]}"
    [[ $desc_index -le ${#act_descriptions} ]] && action_alt="${actions[$desc_index]}"
}

function zaw-get-action-defaults() {
    local name func
    func="$1"
    for k in "${(@k)zaw_sources}"; do
        if [[ "${zaw_sources[$k]}" == "$func" ]]; then
            name="$k"
            break
        fi
    done
    zstyle_name="${(L)name// /-}"
    zstyle -s ":zaw:${zstyle_name}" default action_default
    zstyle -s ":zaw:${zstyle_name}" alt action_alt
    zaw-replace-descriptions-with-action-names
    [[ ${actions[(ie)$action_default]} -le ${#actions} ]] || action_default="${actions[1]}"
    [[ ${actions[(ie)$action_alt]} -le ${#actions} ]] || action_alt="${actions[2]}"
}

function zaw() {
    local action ret func
    local -a reply candidates actions act_descriptions src_opts selected cand_descriptions
    local -A cands_assoc

    if [[ $# == 0 ]]; then
        if zle zaw-select-src; then
            func="${reply[2]}"
            reply=()
        else
            return 0
        fi
    else
        func="$1"
        shift
    fi

    zle -R "now loading ..."

    # call source function to generate candidates
    "${func}" "$@"

    ret="$?"
    if [[ "${ret}" != 0 ]]; then
        return 1
    fi

    reply=()

    if (( ${#cand_descriptions} )); then
        src_opts=("-d" "cand_descriptions" "${(@)src_opts}")
    fi
    # TODO: cand_descriptions_assoc

    # call filter-select to allow user select item
    if (( ${#cands_assoc} )); then
        filter-select -e select-action -A cands_assoc "${(@)src_opts}"
    else
        filter-select -e select-action "${(@)src_opts}" -- "${(@)candidates}"
    fi

    if [[ $? == 0 ]]; then
        if (( ${#reply_marked} > 0 )); then
            selected=("${(@)reply_marked}")
        else
            selected=("${reply[2]}")
        fi

        zaw-get-action-defaults "${func}"

        case "${reply[1]}" in
            accept-line)
                action="${action_default}"
                ;;
            accept-search)
                action="${action_alt}"
                ;;
            select-action)
                if [[ ${#actions} -eq 1 ]]; then
                    action="${actions[1]}"
                else
                    act_descriptions[${actions[(ie)$action_default]}]+=" (Enter)"
                    act_descriptions[${actions[(ie)$action_alt]}]+=" (Meta-enter)"
                    reply=()
                    filter-select -e select-action -t "select action for '${(j:', ':)selected}'" -d act_descriptions -- "${(@)actions}"
                    ret=$?

                    if [[ $ret == 0 ]]; then
                        action="${reply[2]}"
                    else
                        return 1
                    fi
                fi
                ;;
        esac

        if [[ -n "${action}" ]]; then
            "${action}" "${(@)selected}"
        fi
    fi
}

zle -N zaw


function zaw-select-src() {
    local name
    local -a cands descs
    cands=()
    descs=()
    for name in "${(@ko)zaw_sources}"; do
        cands+="${zaw_sources[${name}]}"
        descs+="${name}"
    done

    filter-select -e select-action -d descs -- "${(@)cands}"
}

zle -N zaw-select-src


function zaw-print-src() {
    local name func widget_name
    printf '%-16s %s\n' "source name" "shortcut widget name"
    print -- '----------------------------------------'
    for name in "${(@ko)zaw_sources}"; do
        widget_name="zaw-${(L)name// /-}"
        printf '%-16s %s\n' "${name}" "${widget_name}"
    done
}


# common callbacks
function zaw-callback-execute() {
    BUFFER="${(j:; :)@}"
    zle accept-line
}

function zaw-callback-replace-buffer() {
    LBUFFER="${(j:; :)@}"
    RBUFFER=""
}

function zaw-callback-append-to-buffer() {
    LBUFFER="${BUFFER}${(j:; :)@}"
}

function zaw-callback-edit-file() {
    local -a args
    args=("${(@q)@}")

    if [ ! ${ZAW_EDITOR} ]; then
      ZAW_EDITOR=${EDITOR}
    fi

    BUFFER="${ZAW_EDITOR} ${args}"
    zle accept-line
}


# load zaw sources
setopt local_options extended_glob
local src_dir="${cur_dir}/sources" f
if [[ -d "${src_dir}" ]]; then
    for f in "${src_dir}"/^*.zwc; do
        source "${f}"
    done
fi

# dummy function
# only used for exit-zle-widget-name
function select-action() {}; zle -N select-action
filter-select -i
bindkey -M filterselect '^i' select-action

bindkey '^X;' zaw

}
