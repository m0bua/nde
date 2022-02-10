if [ -d /var/www ]; then cd /var/www; fi

case $- in
    *i*) ;;
      *) return;;
esac
HISTCONTROL=ignoreboth
HISTSIZE=100
HISTFILESIZE=2000

shopt -s histappend
shopt -s checkwinsize

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]nde-\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -lh'

# enable bash completion in interactive shells
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
