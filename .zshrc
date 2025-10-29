# Aliases
alias ls='ls --color=auto'
alias ll='ls -alsp --color=auto'

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
unsetopt beep
bindkey -v
# End of lines configured by zsh-newuser-install

# The following lines were added by compinstall
zstyle :compinstall filename '$HOME/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# Plugins
ZPLUGINDIR=$HOME/.zsh/plugins

if [[ ! -d $ZPLUGINDIR/zsh-syntax-highlighting ]]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
            $ZPLUGINDIR/zsh-syntax-highlighting
fi
source $ZPLUGINDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if [[ ! -d $ZPLUGINDIR/zsh-autosuggestions ]]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions \
            $ZPLUGINDIR/zsh-autosuggestions
fi
source $ZPLUGINDIR/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh

if [[ ! -d $ZPLUGINDIR/zsh-vi-mode ]]; then
  git clone https://github.com/jeffreytse/zsh-vi-mode \
            $ZPLUGINDIR/zsh-vi-mode
fi
source $ZPLUGINDIR/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# Prompt
function parse_git_dirty {
  git diff --quiet --ignore-submodules HEAD 2>/dev/null || echo "*"
}
function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/ (\1$(parse_git_dirty))/"
}
function virtualenv_info { 
    [ $VIRTUAL_ENV ] && echo '('`basename $VIRTUAL_ENV`') '
}
function update_prompt {
  PS1="%n@%m %~$(parse_git_branch) $(virtualenv_info)$ "
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd update_prompt
update_prompt

# add bob to the PATH
export PATH=$PATH:"$HOME/.local/share/bob/nvim-bin"

# add mason to the PATH
export PATH=$PATH:"$HOME/.local/share/nvim/mason/bin"

# add go to the PATH
export PATH="$PATH:/usr/local/go/bin"
export PATH=$PATH:"$HOME/go/bin"

# setup cargo
. "$HOME/.cargo/env"

# setup fnm
eval "$(fnm env --use-on-cd --shell zsh)"

# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit

