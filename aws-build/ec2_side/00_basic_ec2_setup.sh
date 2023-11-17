#
#  Initial ec2 setup
#

#
# Format and mount extra drives
#

# TODO - right now, describe volumes and mount points in 
bash add_ebs_volumes.sh /dev/xvdb  /data

bash install_tools.sh

bash install_python.sh





