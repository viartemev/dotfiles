export PATH="/usr/local/bin:$PATH"

export PS1="\u@\W ⌗ "

source ~/.aliases
source ~/.functions

# Add tab completion for many Bash commands
#if [ -f $(brew --prefix)/etc/bash_completion ]; then
#. $(brew --prefix)/etc/bash_completion
#fi
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion


# Add tab completion for git
if [ -f $(brew --prefix)/etc/bash_completion.d/git-completion.bash ]; then
  . $(brew --prefix)/etc/bash_completion.d/git-completion.bash
fi

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

