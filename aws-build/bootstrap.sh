#!/bin/bash

#  = = =   = = =   = = =   = = =   = = =   = = =   = = =   = = =   = = =   
# Bootstrapping script run as a precursor for setting up
# a rasa server
#
# (c) Copyright November, 2020; January 2023

#
# @author  Keith Rosema 
#
#  = = =   = = =   = = =   = = =   = = =   = = =   = = =   = = =   = = =   

#
# set up an Amazon Linux EC2 system with the basics

# !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! 
# Prior to running this script:
#
#   Select a passphrase for your Github key
#   Be prepared with your Github user name
#
# !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! !!! 

#
# some machines need more building than others but this is the first step
#
#  Agenda, in order
#
#  0 - Configuration
#      AWS Profile
#      Github access
#      AMI choice
#
#  1 - general update
#  2 - pyenv
#      2a - python 3.9
#      2b - python 3.10
#  3 - pip
#  4 - pipenv
#  5 - git
#      5a - git key
#      5b - download git repos with some building/bootstrapping tools
#
#  6 - common develoment basics
#
#
#  7 - Environment tools
#      7a - emacs
#      7b - screen
#
#  = = =   = = =   = = =   = = =   = = =   = = =   = = =   = = =   = = =   

# die if we run into an error
set -e

#  - - -    - - -    - - -    - - -    - - -    - - -    - - -    
#    0      Establish endpoints, profile, github access and AMI choice
#  - - -    - - -    - - -    - - -    - - -    - - -    - - -    

# The profile to use for connecting to AWS
AWS_PROFILE_DEFAULT=MVL

# The instance DNS
AWS_TARGET_INSTANCE=""

# The instance keypair
AWS_TARGET_KEYPAIR="~/.ssh/"

# MVL parameters

# !!!! THIS NEEDS TO BE UPDATED !!!!
VPC_ID=vpc-dd1d61a5
SUBNET_ID=subnet-e7e10aad
SECURITY_GROUP_ID=sg-001245cd6abcbd547
INSTANCE_TYPE=t2.medium
DEVICE_NAME=/dev/sda1
VOLUME_SIZE=50
PLACEMENT=us-west-2b
LOGFILE=./aws_launch.log
KP=rasa-ec2
# !!!! ------------------------ !!!!

# = = = = = = = = = = = = = = = = = = = = = = = = 
# AWS Profile choice
# = = = = = = = = = = = = = = = = = = = = = = = = 	    

### function to provide the name of whatever profile we get
#
assign_aws_account_name() {

#   known account numbers
    panko=233452706922
    xolved=727158581858
    mvl=506771723397
    personal=615661624502

    echo "Identifying account for profile $AWS_PROFILE"
    AWS_ACCOUNT_NO=`aws sts get-caller-identity --query "Account" --output text`
    case $AWS_ACCOUNT_NO in
	$panko ) AWS_ACCOUNT_NAME=panko ;;
	$xolved ) AWS_ACCOUNT_NAME=xolved ;;
	$mvl ) AWS_ACCOUNT_NAME=mvl ;;
	$personal) AWS_ACCOUNT_NAME=personal ;;
	* ) AWS_ACCOUNT_NAME=$AWS_ACCOUNT_NO ;;
    esac
}


echo "AWS profiles are described in ~/.aws/config"

read -p "  List ~/.aws/config ? (yes/no) " yn

case $yn in 
	yes ) cat ~/.aws/config ;;
	no ) echo ;;
	* ) echo  ;;
esac

read -p "What is the AWS PROFILE to use? [${AWS_PROFILE_DEFAULT}] " AWS_PROFILE
AWS_PROFILE=${AWS_PROFILE:-$AWS_PROFILE_DEFAULT}
export AWS_PROFILE
assign_aws_account_name

echo "Using account number $AWS_ACCOUNT_NO ($AWS_ACCOUNT_NAME)"

# = = = = = = = = = = = = = = = = = = = = = = = = 
# Launch a new EC2 instance
# = = = = = = = = = = = = = = = = = = = = = = = =

# My test instance          ami-063585f0e06d22308
# Conifer, RasaX instance   ami-0ac73f33a1888c64a
# Node server instance      ami-06e54d05255faf8f6
# R1 instance               ami-07a29e5e945228fa1
#

default_micro=ami-0ceecbb0f30a902a6

ami_options=("$default_micro" "ami-063585f0e06d22308" "ami-0ac73f33a1888c64a" "ami-06e54d05255faf8f6" "ami-07a29e5e945228fa1")

for i in ${!ami_options[@]}; do
  echo "$((i+1)))  ${ami_options[$i]}"
done
read -p "Please select an ami option [1]:  " AMI_CHOICE
AMI_CHOICE=${AMI_CHOICE:-1}
AMI=${ami_options[$((AMI_CHOICE-1))]}
echo $AMI_CHOICE $AMI

read -p "Please enter a name for this instance [Foo]:  " INSTANCE_NAME
INSTANCE_NAME=${INSTANCE_NAME:-Foo}

read -p "Please enter your name for tagging [$USER]:  " CREATEDBY_NAME
CREATEDBY_NAME=${CREATEDBY_NAME:-$USER}

read -p "Please enter the application for this instance [Foo]:  " INSTANCE_APPLICATION_NAME
INSTANCE_NAME=${INSTANCE_APPLICATION_NAME:-Foo}

read -p "Please choose your username [$CREATEDBY_NAME]:  "  USER_NAME
USER_NAME=${USER_NAME:-$CREATEDBY_NAME}

echo "Instance:     ${INSTANCE_NAME}"
echo "created-by:   ${CREATEDBY_NAME}"
echo "application:  ${INSTANCE_APPLICATION_NAME}"
echo "User:  ${USER_NAME}"

exit 99


read -p "Please specify a keypair file [$KP]: " KEY_PAIR
KEY_PAIR=${KEY_PAIR:-$KP}

#
# In the future, can do all of this with a custome AMI and a launch template
#
#   ref:  https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/run-instances.html
#         https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-output.html#cli-usage-output-filter
#
aws ec2 run-instances --image-id $AMI --count 1 --instance-type ${INSTANCE_TYPE} --key-name ${KEY_PAIR} --security-group-ids ${SECURITY_GROU_ID} --subnet-id ${SUBNET_ID} --block-device-mappings "DeviceName=${DEVICE_NAME},Ebs={VolumeSize=${VOLUME_SIZE}}" --placement "AvailabilityZone=${PLACEMENT}" --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]' --output json --query "{ReservationId:ID}"  >> ./reservation_id.log

#  --query "ReservationId:ResID"

exit 99


# = = = = = = = = = = = = = = = = = = = = = = = = 
# Github access
# = = = = = = = = = = = = = = = = = = = = = = = = 

# a private key for configuring git access
#  NOTE - should build a key and store on AWS
GIT_PRIVATE_KEY=~/.ssh/id_rsa_git

# a repo with scripts, etc. to bootstrap construction
GIT_BOOTSTRAP_REPO=git@github.com:chompx/templates.git


# check if the user failed to arrange their github auth token
if [ -z ${GHPPH+"foo"} ];
then
    read -sp "Please enter a pass phrase for the github access key:  " GHPPH
    echo
else echo "GHPPH was set"
     
fi
if [ -z ${GHAuthToken+"foo"} ];
then
    read -sp "Please enter your github auth token:  " GHAuthToken
    echo
else echo "GHAuthToken was set"
fi

export GHPPH
export GHAuthToken

# = = = = = = = = = = = = = = = = = = = = = = = = 
# Directories
# = = = = = = = = = = = = = = = = = = = = = = = = 

# for testing HHOME=/Users/rosema/code/outbound/home

HHOME=$HOME
SSHDIR=$HHOME/.ssh
CONFDIR=$HOME/.outbound
GITDIR=$CONFDIR/GIT

# Files
GHKEYFILE=$SSHDIR/git-deploy-key

if [ -d $HHOME ] 
then
    echo "HHOME directory set to $HHOME" 
echo
else
    echo "Error: HHOME does not exist."
    exit 99                            # barf
fi


aws describe-instance --filters "ReservationId=${RES_ID}"

# ref:  https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-instances.html
aws ec2 describe-instances --filters "Name=instance-type,Values=t2.micro" --query "Reservations[].Instances[].InstanceId"

aws ec2 wait instance-status-ok --instance-ids $RASA_INSTANCE

exit 99

EC2_INSTANCE=`curl http://169.254.169.254/latest/meta-data/instance-id`

# = = = = = = = = = = = = = = = = = = = = = = = = 
#  Configure github access keys
# = = = = = = = = = = = = = = = = = = = = = = = = 

# gh adds command line access to all github api commands, including those needed to
# generate and install a key
#
#   https://cli.github.com/manual/gh
#   https://github.com/cli/cli/blob/trunk/docs/install_linux.md
#
sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
sudo yum install gh

# ensure .ssh/ exists
mkdir -pv $SSHDIR -m 700

ssh-keygen -b 4096 -t rsa -N $GHPPH -C "Github Access Key" -f $GHKEYFILE
chmod 700 $GHKEYFILE
chmod 644 $GHKEYFILE.pub

# Push key to github
echo '{"title":"GH Key for '${EC2_INSTANCE}'", "key":"' > $SSHDIR/key.json
cat  $GHKEYFILE.pub >> $SSHDIR/key.json
echo '"}'  >> $SSHDIR/key.json

curl -H "Authorization: token $GHAuthToken" --data @$SSHDIR/key.json  https://api.github.com/user/keys

rm -f $SSHDIR/key.json

# Do a hacky thing to make this key available without needing the passphrase again
#    !!! TODO chmod and cleanup
#
echo "#!/bin/sh" > $SSHDIR/pp.sh
echo "echo \"$GHPPH\"" >> $SSHDIR/pp.sh

eval "$(ssh-agent -s)"
DISPLAY=1 SSH_ASKPASS="$SSHDIR/pp.sh" ssh-add $GHKEYFILE < /dev/null

# did the key get added?
ssh-add -l

# Cleanup
rm -f $SSHDIR/pp.sh

# Test the connection

ssh -T -o StrictHostKeyChecking=accept-new  -i ~/.ssh/git-deploy-key git@github.com

# Download the rest of the configuration scripts and data from Github


# Execute the rest of it
