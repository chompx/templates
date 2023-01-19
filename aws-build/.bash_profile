# .bash_profile

#  template to replace initial .bash_profile

#  includes updates to
#
#  extend PATH with
#         $HOME, $HOME/.local/bin, $HOME/bin          --
#         $HOME/.pyenv/bin                            -- for pyenv


# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/.local/bin:$HOME/bin

export PATH
export PATH="~/.local/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
