# RedHat-style prompt
#PS1="[%n@%m %1~]%(#.#.$) "
autoload -U promptinit
promptinit
prompt redhat

autoload colors
colors
autoload -U compinit
compinit -C

zstyle ':completion:*' menu yes select
zstyle ':completion:*:(ssh|scp):*:users' ignored-patterns `cat /etc/passwd | awk -F ":" '{ if($3<1000) print $1 }'`
zstyle ':completion:*:processes' command 'ps xua'
zstyle ':completion:*:processes' sort false
zstyle ':completion:*:processes-names' command 'ps xho command'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
eval `dircolors`
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

setopt autocd
setopt extended_glob
setopt correct
unsetopt nomatch

# Key bindings

if [[ "$TERM" == "xterm" ]]; then
    export TERM=xterm-256color
fi

#autoload zkbd
#[[ ! -f ~/.zkbd/$TERM-${DISPLAY:-$VENDOR-$OSTYPE} ]] && zkbd
#source ~/.zkbd/$TERM-${DISPLAY:-$VENDOR-$OSTYPE}

source ~/.zsh/keyboard.sh

bindkey -e

[[ -n ${key[Backspace]} ]] && bindkey "${key[Backspace]}" backward-delete-char
[[ -n ${key[Insert]} ]] && bindkey "${key[Insert]}" overwrite-mode
[[ -n ${key[Home]} ]] && bindkey "${key[Home]}" beginning-of-line
[[ -n ${key[PageUp]} ]] && bindkey "${key[PageUp]}" up-line-or-history
[[ -n ${key[Delete]} ]] && bindkey "${key[Delete]}" delete-char
[[ -n ${key[End]} ]] && bindkey "${key[End]}" end-of-line
[[ -n ${key[PageDown]} ]] && bindkey "${key[PageDown]}" down-line-or-history
[[ -n ${key[Up]} ]] && bindkey "${key[Up]}" up-line-or-search
[[ -n ${key[Left]} ]] && bindkey "${key[Left]}" backward-char
[[ -n ${key[Down]} ]] && bindkey "${key[Down]}" down-line-or-search
[[ -n ${key[Right]} ]] && bindkey "${key[Right]}" forward-char

# Ctrl-left/right
bindkey '^[[5D' emacs-backward-word
bindkey '^[[5C' emacs-forward-word
# screen
bindkey '^[[1;5D' emacs-backward-word
bindkey '^[[1;5C' emacs-forward-word

function up-local-history () {
    zle set-local-history 1
    zle up-history
    zle set-local-history 0
}
function down-local-history () {
    zle set-local-history 1
    zle down-history
    zle set-local-history 0
}
zle -N up-local-history
zle -N down-local-history
# Alt-up/down
bindkey '^[[3A' up-local-history
bindkey '^[[3B' down-local-history
# screen
bindkey '^[[1;3A' up-local-history
bindkey '^[[1;3B' down-local-history

### Это очень интересные штуки
setopt share_history

setopt autocd
setopt automenu
setopt autopushd
setopt autoresume
setopt complete_in_word
setopt extended_glob

setopt list_types
setopt mailwarning
setopt no_flowcontrol
setopt no_hup
setopt no_notify
setopt printexitvalue
setopt pushd_ignoredups
setopt pushd_silent
##########

### Настройка журнала команд
export HISTFILE=$HOME/.zsh_history
export HISTSIZE=18192
export SAVEHIST=18192

#--------------------------------------------------#
# Игнорировать все повторения команд
setopt HIST_IGNORE_ALL_DUPS
# Игнорировать лишние пробелы
setopt HIST_IGNORE_SPACE

setopt EXTENDED_HISTORY

# User specific environment and startup programs

PATH=$PATH:$HOME/bin
export PATH

export EDITOR=vim
export MAKEOPTS="-j5"
export OPENSSL_CONF=~/CA/caconfig.cnf

export MANSECT=1:1p:8:2:3:3p:4:5:6:7:9:0p:n:l:p:o:1x:2x:3x:4x:5x:6x:7x:8x:Cg:CgFX

# Qemu audio presets
#export QEMU_AUDIO_DRV=alsa
##export QEMU_AUDIO_DAC_FIXED_FREQ=48000
##export QEMU_AUDIO_ADC_FIXED_FREQ=48000
##export QEMU_ALSA_DAC_BUFFER_SIZE=4096
#export QEMU_ALSA_DAC_PERIOD_SIZE=1024

# RPM Fusion config
export PLAGUE_CLIENT_CONFIG=~/.plague-client-rpmfusion.cfg

export GREP_OPTIONS='--color=auto'
export GREP_COLOR='1;32'

export MPD_HOST=localhost

# User specific aliases and functions

alias bc='bc -l'
alias kojirf='koji -c ~/.koji/rf-config'
alias mount="mount | grep -v 'cgroup\|systemd'"
alias psc='ps xawf -eo pid,user,cgroup,args'
alias pv='pv -tpreb'

