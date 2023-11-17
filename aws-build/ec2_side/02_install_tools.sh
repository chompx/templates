#
# Install common yum tools
#

# Install common developer tools
#
sudo yum install gcc zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel

# Install git
#
sudo yum install git

# install emacs
# AWS 2023 linux and after don;'t use amazon-linux-extras
# sudo amazon-linux-extras enable emacs

# Emacs without the windowing stuff
sudo yum install emacs-nox
