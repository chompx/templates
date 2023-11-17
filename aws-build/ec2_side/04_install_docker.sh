#
#  Installing docker
#

#  https://stackoverflow.com/questions/53918841/how-to-install-docker-on-amazon-linux2

sudo yum update -y
sudo yum -y install docker

sudo usermod -a -G docker ec2-user
sudo chmod 666 /var/run/docker.sock
docker version
