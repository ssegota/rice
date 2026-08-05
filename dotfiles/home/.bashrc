# ~/.bashrc: executed by bash(1) for non-login shells.
alias agent='cursor-agent'
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
#HISTSIZE=1000
#HISTFILESIZE=2000

# ============================================================
#  Power-user additions
# ============================================================

# --- History: bigger, deduped, timestamped, shared across tabs ---
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT="%F %T "
shopt -s histappend
PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND}"

# --- shopt niceties ---
shopt -s autocd          # type a dir name to cd into it
shopt -s cdspell         # autocorrect minor cd typos
shopt -s dirspell        # autocorrect during tab-completion
shopt -s globstar        # ** matches recursively
shopt -s no_empty_cmd_completion

# --- Arrow-key prefix history search ---
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# --- fzf: shell keybindings (Ctrl+R, Ctrl+T, Alt+C) ---
# Modern fzf (0.48+):
eval "$(fzf --bash)"
# If the line above errors on an older fzf, comment it out and use:
# source /usr/share/doc/fzf/examples/key-bindings.bash
# source /usr/share/doc/fzf/examples/completion.bash

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview 'bat --color=always --style=numbers --line-range=:300 {}'"

# --- zoxide: smarter cd that learns your habits (z / zi) ---
eval "$(zoxide init bash)"

# --- Colorized man pages via bat ---
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# --- Navigation shortcuts ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# --- Safer file ops ---
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'

# --- Universal archive extractor ---
extract() {
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;  *.tar.gz) tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;  *.tar)    tar xf  "$1" ;;
    *.bz2) bunzip2 "$1" ;;      *.gz)  gunzip "$1" ;;
    *.zip) unzip "$1" ;;        *.7z)  7z x "$1" ;;
    *.rar) unrar x "$1" ;;      *)     echo "Can't extract '$1'" ;;
  esac
}

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/sbs/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/sbs/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/sbs/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/sbs/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export EDITOR="code"
export VISUAL="code"

export PATH="$HOME/.local/bin:$PATH"

# Added by flyctl installer
export FLYCTL_INSTALL="/home/sbs/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"

. "$HOME/.local/share/../bin/env"
alias nethack="TERM=xterm-256color nethack"

# The clean, quick list
alias ls='eza --icons --group-directories-first'

# The ultimate detailed list 
alias ll='eza -la --icons --git --group-directories-first --time-style=long-iso'

# A beautiful visual directory tree
alias lt='eza --tree --level=2 --icons --git-ignore'

# --- 🦇 VISUAL TEXT READER ---
alias cat='bat --paging=never --style=plain'

# --- 🔍 THE SUPER SEARCHER ---
alias preview='fzf --preview="bat --color=always --style=numbers --line-range=:500 {}"'

eval "$(starship init bash)"

