#zdep __begin__
### vim:ft=zsh:foldmethod=marker
#
# The journey towards "the perfect key definitions"[tm].
#
# We'll go about it like this:
#   - if there's zsh/terminfo and $terminfo[] "looks good", use it.
#   - if there's zsh/termcap and $termcap[] "looks good", use it.
#   - if neither is there, fall back to zkbd.
#   - if zkbd fails for some reason, create a setup-file-skeleton
#     for the terminal-OS combination in question.
#
# Slight deviation from the rules, we just established:
#   If the user marks a database entry as broken, directly fall back
#   to zkbd:
# % zstyle ':keyboard:$VENDOR:$OSTYPE:$TERM:*:*' broken (terminfo|termcap|both)
#
#   Also, allow for overwriting key definitions:
# % zstyle ':keyboard:$VENDOR:$OSTYPE:$TERM:terminfo:Home' overwrite $'\e[1~'
#
# Styles *have* to be set *before* sourcing this file.
# Also, this files expects pretty much zsh-mode default options. So,
# set your crazy options *after* sourcing this file.
#
# Note, that this file does *NOT* bind anything for you. It merely
# populates the $key[] hash, which you can later use to bind your keys,
# like this:
#   [[ -n ${key[Home]} ]] && bindkey ${key[Home]} beginning-of-line
#
# Also, this file uses a function called zprintf(), which I use in the
# rest of my setup. zsh doesn't know about it by default, so you'd need
# uncomment the following in order to avoid errors:
#
#ZSHRC_VERBOSE=0
#function zprintf() {
#    local -i level; local format
#    level=$1 ; format=$2; shift; shift
#    (( ZSHRC_VERBOSE < level )) && return 0
#    printf '[%2d] '${format} ${level} "$@"
#}
#

if [[ ${builtins[zmodload]} != 'defined' ]]; then
    printf 'keyboard: zmodload builtin not found, cannot go on.\n'
    return 0
fi

# zrclistkeys() show a list of keysyms strings
function zrclistkeys() {
    for i in ${(kon)key}; do
        printf '%13s: '\''%s'\''\n' ${i} ${(V)${key[$i]}}
    done
}

[[ ${modules[zsh/parameter]} != 'loaded' ]] && zmodload zsh/parameter

typeset -A key
typeset -A kbd_terminfo_map
typeset -A kbd_termcap_map

kbd_terminfo_map=(
    Home        khome
    End         kend
    Insert      kich1
    Delete      kdch1
    Up          kcuu1
    Down        kcud1
    Left        kcub1
    Right       kcuf1
    PageUp      kpp
    PageDown    knp
)

kbd_termcap_map=(
    Home        kh
    End         @7
    Insert      kI
    Delete      dc
    Up          ku
    Down        kd
    Left        kl
    Right       kr
    PageUp      kP
    PageDown    kN
)

mode='(-nothing-)'
if [[ ${modules[zsh/terminfo]} == 'loaded' ]] && [[ ${(t)terminfo} == association-*-special ]]; then
    mode='terminfo'
elif zmodload zsh/terminfo 2> /dev/null && [[ ${modules[zsh/terminfo]} == 'loaded' ]] \
    && [[ ${(t)terminfo} == association-*-special ]]; then
    mode='terminfo'
elif [[ ${modules[zsh/termcap]} == 'loaded' ]] && [[ ${(t)termcap} == association-*-special ]]; then
    mode='termcap'
elif zmodload zsh/termcap 2> /dev/null && [[ ${modules[zsh/termcap]} == 'loaded' ]] \
    && [[ ${(t)termcap} == association-*-special ]]; then
    mode='termcap'
else
    mode='zkbd'
fi

zstyle -s ':keyboard:*' zkbddir zkbddir || zkbddir="${ZDOTDIR:-$HOME}/.zkbd"
kcontext=":keyboard:${VENDOR}:${OSTYPE}:${TERM}:*:*"
zstyle -s ${kcontext} broken broken || broken=''
if [[ ${broken} == 'both' ]] || [[ ${broken} == ${mode} ]]; then
    mode='zkbd'
fi

if [[ ${mode} == 'zkbd' ]]; then
    function Printf_file() {
        [[ -f "$2" ]] && printf "$1" "$2" && return 0
        return 1
    }

    function zrc_printf_termfile() {
        Printf_file '%s' ~/.${zkbddir}/${TERM}-${VENDOR}-${OSTYPE} && return 0
        Printf_file '%s' ~/.${zkbddir}/${TERM}-${DISPLAY}          && return 0
        return 1
    }

    termfile="$(zrc_printf_termfile)"
    if [[ -z "${termfile}" ]] ; then
        zrcautoload zkbd && zkbd
        termfile=$(zrc_printf_termfile)
    fi

    if [[ -f "${termfile}" ]] ; then
        zprintf 1 '  zle: loading %s\n' "${termfile}"
        source "${termfile}"
    else
        zprintf 0 'termfile (%s) not found. zkbd failed.\n' "${termfile}"
        mode='need-manual-skeleton'
    fi
    unfunction Printf_file zrc_printf_termfile
elif [[ ${mode} == 'terminfo' ]]; then
    typeset -A key
    for k in ${(k)kbd_terminfo_map}; do
        key[$k]=${terminfo[${kbd_terminfo_map[$k]}]}
    done
    if [[ -n ${terminfo[smkx]} ]] && [[ -n ${terminfo[rmkx]} ]]; then
        function zle-line-init () {
            echoti smkx
        }
        function zle-line-finish () {
            echoti rmkx
        }
        zle -N zle-line-init
        zle -N zle-line-finish
    fi
else # termcap
    typeset -A key
    for k in ${(k)kbd_termcap_map}; do
        key[$k]=${termcap[${kbd_termcap_map[$k]}]}
    done
    if [[ -n ${termcap[ks]} ]] && [[ -n ${termcap[ke]} ]]; then
        function zle-line-init () {
            echotc ks
        }
        function zle-line-finish () {
            echotc ke
        }
        zle -N zle-line-init
        zle -N zle-line-finish
    fi
fi

if [[ ${mode} == 'need-manual-skeleton' ]]; then
    termfile="${zkbddir}/MANUAL_${TERM}-${VENDOR}-${OSTYPE}"
    if [[ ! -e ${termfile} ]]; then
        printf '%s\n' "echo \"zkbd failed for terminal: ${TERM}-${VENDOR}-${OSTYPE}\"" > ${termfile}
        printf '%s\n' "echo \"This is ${termfile}\";echo" >> ${termfile}
        printf '%s\n' "echo \"Feel free to edit this file and manually insert the right\"" >> ${termfile}
        printf '%s\n\n' "echo \"sequences for the keys you want.\"" >> ${termfile}
        for k in ${(k)kbd_terminfo_map}; do
            printf '#key[%s]=$'\'''\''\n' $k >> ${termfile}
        done
    fi
    source ${termfile}
fi

key[Tab]='^I'
for k in ${(k)key} ; do
    key[Alt-${k}]='^['${key[$k]}
done

function kbd_expand() {
    emulate -L zsh
    setopt braceccl

    for k in {0..9} {a-z} {A-Z} ; do
        for i in Ctrl- Alt- ; do
            case ${i} in
            (Ctrl-)
                [[ ${k} == [A-Z0-9] ]] && continue
                key[${i}${k}]='^'${k}
                ;;
            (Alt-)
                # This might not work everywhere. Oh well...
                key[${i}${k}]='^['${k}
                ;;
            esac
        done
    done
}
kbd_expand

key[Alt-Enter]='^[^M'

case $TERM in
rxvt-unicode)
    key[Ctrl-Delete]="^[[3^"
    key[Ctrl-Up]="^[Oa"
    key[Ctrl-Down]="^[Ob"
    key[Ctrl-Right]="^[Oc"
    key[Ctrl-Left]="^[Od"
    key[Alt-Up]="^[^[[A"
    key[Alt-Down]="^[^[[B"
    key[Alt-Right]="^[^[[C"
    key[Alt-Left]="^[^[[D"
    ;;
xterm*|roxterm|gnome-terminal|screen)
    if [ -z "$TMUX" ]; then
        key[Ctrl-Delete]="^[[3;5~"
        key[Ctrl-Up]="^[[1;5A"
        key[Ctrl-Down]="^[[1;5B"
        key[Ctrl-Right]="^[[1;5C"
        key[Ctrl-Left]="^[[1;5D"
        key[Alt-Up]="^[[1;3A"
        key[Alt-Down]="^[[1;3B"
        key[Alt-Right]="^[[1;3C"
        key[Alt-Left]="^[[1;3D"
    else
        key[Ctrl-Delete]="^[[3^"
        key[Ctrl-Up]="^[OA"
        key[Ctrl-Down]="^[OB"
        key[Ctrl-Right]="^[OC"
        key[Ctrl-Left]="^[OD"
        key[Alt-Up]="^[^[[A"
        key[Alt-Down]="^[^[[B"
        key[Alt-Right]="^[^[[C"
        key[Alt-Left]="^[^[[D"
    fi
    ;;
esac

#for k in ${(k)key}; do
#    printf '"%s": "%s"\n' $k "${(V)key[$k]}"
#done

unset mode kcontext broken kbd_terminfo_map kbd_termcap_map termfile k sequence
unfunction kbd_expand
true
