#Bind so that the color red is show when in command mode and grey in insert mode.
zle-keymap-select () {
    if [ $TERM = "xterm" ]; then
        if [ $KEYMAP = vicmd ]; then
            echo -ne "\033]12;Red\007"
        else
            echo -ne "\033]12;Grey\007"
        fi
    fi
}
zle -N zle-keymap-select
zle-line-init () {
    zle -K viins
    if [ $TERM = "xterm" ]; then
        echo -ne "\033]12;Grey\007"
    fi
}
zle -N zle-line-init

#Set to vi mode
bindkey -v


# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt appendhistory nomatch notify
unsetopt autocd beep extendedglob
# End of lines configured by zsh-newuser-install


# The following lines were added by compinstall
zstyle :compinstall filename '/home/martin/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall


# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -A key

key[Home]=${terminfo[khome]}

key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}

# setup key accordingly
[[ -n "${key[Home]}"     ]]  && bindkey  "${key[Home]}"     beginning-of-line
[[ -n "${key[End]}"      ]]  && bindkey  "${key[End]}"      end-of-line
[[ -n "${key[Insert]}"   ]]  && bindkey  "${key[Insert]}"   overwrite-mode
[[ -n "${key[Delete]}"   ]]  && bindkey  "${key[Delete]}"   delete-char
[[ -n "${key[Up]}"       ]]  && bindkey  "${key[Up]}"       up-line-or-history
[[ -n "${key[Down]}"     ]]  && bindkey  "${key[Down]}"     down-line-or-history
[[ -n "${key[Left]}"     ]]  && bindkey  "${key[Left]}"     backward-char
[[ -n "${key[Right]}"    ]]  && bindkey  "${key[Right]}"    forward-char
[[ -n "${key[PageUp]}"   ]]  && bindkey  "${key[PageUp]}"   beginning-of-buffer-or-history
[[ -n "${key[PageDown]}" ]]  && bindkey  "${key[PageDown]}" end-of-buffer-or-history

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
    function zle-line-init () {
        printf '%s' "${terminfo[smkx]}"
    }
    function zle-line-finish () {
        printf '%s' "${terminfo[rmkx]}"
    }
    zle -N zle-line-init
    zle -N zle-line-finish
fi


# Auto load the prompt
autoload -U promptinit
promptinit
prompt redhat

#Show available promt themes
#$   promt -p



### ####################################
### Version Control Information
#
#   http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#Version-Control-Information
#   https://github.com/zsh-users/zsh/blob/master/Misc/vcs_info-examples
#   http://www.jukie.net/~bart/conf/zsh/rc/S60_prompt
#   http://stackoverflow.com/questions/1128496/to-get-a-prompt-which-indicates-git-branch-in-zsh
### ####################################

# To be able to use ’${vcs_info_msg_0_}’ directly in your prompt,
# you will need to have the PROMPT_SUBST option enabled.
setopt prompt_subst
autoload -Uz vcs_info

# %b - branchname
# %u - unstagedstr (see below)
# %c - stangedstr (see below)
# %a - action (e.g. rebase-i)
# %R - repository path
# %S - path in the repository

zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr 'C'    #display specified symbol if there are unstaged changes
zstyle ':vcs_info:*' stagedstr 'C'      #display specified symbol if there are staged changes

zstyle ':vcs_info:*' actionformats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{3}|%F{1}%a%F{5}]%f '
zstyle ':vcs_info:*' formats '%F{5}(%f%s%F{5})%F{3}-%F{5}[%F{2}%b%F{5}]%f %u %c'
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'
zstyle ':vcs_info:*' enable git cvs svn

precmd () { vcs_info } # You need to call vcs_info from your precmd function.
                       # Once that is done you need a single quoted ’${vcs_info_msg_0_}’ in your prompt.

# Format the prompt
#PS1='%F{5}[%F{2}%n%F{5}] %F{3}%3~ ${vcs_info_msg_0_}%f%# '
PS1='%F{5}[%F{2}%n%F{5}] %f%# '

# Display the VCS information in the right prompt. The {..:- } is a workaround for Zsh below verion 4.3.9.
#RPROMPT='${vcs_info_msg_0_:- }'
RPROMPT='%F{3}%3~ ${vcs_info_msg_0_:- }'


# Now call the vcs_info_printsys utility from the command line...

