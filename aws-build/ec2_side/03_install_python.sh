#
#  Installs pyenv, python, pip, pipenv and poetry
#
#  requires install_tools to run before in order to ensure git installed
#

#
# Install pyenv
#
# for managing python installs
#
# install some basic python libraries
#
# set default python
#


sudo yum update -y

git clone https://github.com/pyenv/pyenv.git ~/.pyenv

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bashrc
exec "$SHELL"

pyenv install 3.10
pyenv install 3.11

sudo yum -y install python-pip

pyenv local 3.11.6

