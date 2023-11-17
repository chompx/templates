#
#  After launching an EC2 instance that has
#  additional storage devices allocated
#  it will boot with the addtional volumes as raw block storage
#
#  This script formats those additional volumes and mounts
#  them at desired points

#  See end of script for playbook
#

#
# Mount extra drives
#

#
# Manually declare the devices and the desired mount points here
#
#
# declare -a arr_devices=("/dev/xvdb")    # ("element1" "element2" "element3")
# declare -a arr_mounts=("/data")         # You can access these using echo "${arr[0]}", "${arr[1]}" also

#  process inputs as
#  /dev/svdb /data  /dev/svdc /storage ...

declare -a arr_devices=( )  
declare -a arr_mounts=( )

i="0"
for var in "$@"
do
    echo "$var"
    if (( $i % 2 )); then
	arr_mounts+=($var)
    else
	# $i is even
	arr_devices+=($var)
    fi
    i=$[$i+1]
done



## the list of additional (raw) EBS volues

echo "Listing block devices"
lsblk

# Make a temp copy of fstab that we will add the new entries to
#
sudo cp /etc/fstab /etc/fstab.tmp

## now loop through the above array
for i in  "${!arr_devices[@]}"
do
    echo "$i) " "${arr_devices[$i]}" " -> " "${arr_mounts[$i]}"
  
    echo "sudo mkfs -t xfs ${arr_devices[$i]}"
    echo "sudo mkdir ${arr_mounts[$i]}"
    echo "sudo mount ${arr_devices[$i]}  ${arr_mounts[$i]}"
    uuid=$(sudo blkid | grep -Po "${arr_devices[$i]}: UUID=\"([A-Za-z\-0-9]+)\"" | grep -oP '"\K[^"\047]+(?=["\047])')
    echo $uuid
    echo "UUID=$uuid  ${arr_mounts[$i]}  xfs  defaults,nofail  0  2" | sudo tee -a /etc/fstab.tmp
done

echo "Updated fstab"

# sudo cp /etc/fstab /etc/fstab.orig
# sudo mv -v /etc/fstab.tmp /etc/fstab
echo "sudo cp /etc/fstab /etc/fstab.orig"
cat /etc/fstab

# test automount
for i in  "${arr_mounts[@]}"
do
    #  echo "${arr_devices[$i]}" " " "${arr_mounts[$i]}"
    echo "Unmounting $i "
    sudo umount $i
done

echo "Testing fstab mounting"
sudo mount -a

#  We should see all of the new devices mounted here
#
findmnt -t xfs



# The playbook
#  lsblk
#  sudo file -s /dev/xvdb
#  sudo mkfs -t xfs /dev/xvdb
#  sudo mkdir /data
#  sudo mount /dev/xvdb /data
#
#  cat /etc/fstab
#  sudo cp /etc/fstab /etc/fstab.orig
#
#  sudo blkid
#  echo "UUID=4e29b314-4e58-4eeb-8054-2e16075f03a2  /data  xfs  defaults,nofail  0  2" |  tee -a /etc/fstab
#  cat /etc/fstab
#
#  # verify automount
#  sudo umount /data
#  sudo mount -a
#  ln -s /data ~/data
#
