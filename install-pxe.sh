!/bin/bash

### install-pxe.sh

# automate the installation of a PXE server that can automatically install Xubuntu Desktop 20.04
# other tools to be added later.

### by chaslinux@gmail.com


# CONSTANTS
CODEDIR="/home/$USER/Code"
UNPACKDIR="/home/$USER/UNPACKDIR"
TFTP_DEFAULT="/srv/tftp"
HTTP_DEFAULT="/var/www/html"
JAMMYDESKTOP=xubuntu-22.04.2-desktop-amd64.iso

### first update the system
sudo apt update && sudo apt upgrade -y

# install the base server packages (note: we use pfsense, so no dhcp server here)
# For the moment let's use tftp and ftp (tftpd-hpa and vsftpd)
# sudo apt install vsftpd -y

### Following the process here (w/ modifications as per directories)
sudo apt install tftpd-hpa -y
sudo apt install apache2 -y
sudo apt install nfs-kernel-server -y
sudo apt install unzip -y

# Download pxelinux packages
mkdir -p $UNPACKDIR/{shim,grub}
cd $UNPACKDIR
if [ ! -f $UNPACKDIR/syslinux-6.03.zip ] ; then
{
	wget https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.zip
	unzip syslinux-6.03.zip
}
fi


### Create the tftp folder structure, 
# note - differs from c-nergy as /srv/tftp is the default
# in /var/www/html used the xubuntu subdirectory instead of just server and desktop
sudo mkdir -p $TFTP_DEFAULT/{xubuntu,grub}
sudo mkdir -p $TFTP_DEFAULT/xubuntu/desktop/jammy
sudo mkdir -p $TFTP_DEFAULT/pxelinux.cfg
sudo mkdir -p $HTTP_DEFAULT/xubuntu/{server,desktop}/{focal,jammy}

# download UEFI packages & ISO images
cd $UNPACKDIR
echo $UNPACKDIR
apt-get download shim.signed
SHIMFILE=$(ls shim-signed*)
echo $SHIMFILE
dpkg -x $SHIMFILE shim
apt-get download grub-efi-amd64-signed
GRUBFILE=$(ls grub-efi*)
echo $GRUBFILE
dpkg -x $GRUBFILE grub

# for now just download jammy and unpack it into the $HTTP_DEFAULT/xubuntu/desktop/<version> directory
wget http://mirror.csclub.uwaterloo.ca/xubuntu-releases/22.04/release/$JAMMYDESKTOP
sudo mount $JAMMYDESKTOP /mnt
echo "*** COPYING ISO to $HTTP_DEFAULT/xubuntu/desktop/jammy - be patient ***"
sudo cp -rf /mnt/* $HTTP_DEFAULT/xubuntu/desktop/jammy
sudo cp -rf /mnt/.disk $HTTP_DEFAULT/xubuntu/desktop/jammy
sudo umount /mnt

### populate the tftp folder
sudo cp $UNPACKDIR/bios/com32/elflink/ldlinux/ldlinux.c32  $TFTP_DEFAULT
sudo cp $UNPACKDIR/bios/com32/libutil/libutil.c32 $TFTP_DEFAULT
sudo cp $UNPACKDIR/bios/com32/menu/menu.c32 $TFTP_DEFAULT
sudo cp $UNPACKDIR/bios/com32/menu/vesamenu.c32 $TFTP_DEFAULT
sudo cp $UNPACKDIR/bios/core/pxelinux.0 $TFTP_DEFAULT
sudo cp $UNPACKDIR/bios/core/lpxelinux.0 $TFTP_DEFAULT
sudo cp $HTTP_DEFAULT/xubuntu/desktop/jammy/casper/vmlinuz $TFTP_DEFAULT/xubuntu/desktop/jammy
sudo cp $HTTP_DEFAULT/xubuntu/desktop/jammy/casper/initrd $TFTP_DEFAULT/xubuntu/desktop/jammy

### populate the grub folder
sudo cp $UNPACKDIR/grub/usr/lib/grub/x86_64-efi-signed/grubnetx64.efi.signed $TFTP_DEFAULT/grub/grubx64.efi
sudo cp $UNPACKDIR/shim/usr/lib/shim/shimx64.efi.signed $TFTP_DEFAULT/grub/bootx64.efi
cp $HTTP_DEFAULT/xubuntu/desktop/jammy/boot/grub/grub.cfg $TFTP_DEFAULT/grub
cp $HTTP_DEFAULT/xubuntu/desktop/jammy/boot/grub/unicode.pf2 $TFTP_DEFAULT/grub/font.pf2

### symlink the boot folder
#sudo ln -s $TFTP_DEFAULT/boot $TFTP_DEFAULT/bios/boot

### copy the default file included here to $TFTP_DEFAULT/bios/pxelinux.cfg
sudo cp $CODEDIR/install-pxe/default $TFTP_DEFAULT/pxelinux.cfg
sudo cp $CODEDIR/install-pxe/grub.cfg $TFTP_DEFAULT/grub





############## IGNORE EVERYTHING HERE AS THIS IS FROM AN OLD SERVER - HERE for REFERENCE ############
### vsftpd options (from our old server)
# anon_root=/home/ftp


## Restrict to passive FTP on only a few ports
## https://serverfault.com/questions/421161/how-to-configure-vsftpd-to-work-with-passive-mode
# port_enable=NO
# pasv_enable=YES
# pasv_min_port=8000
# pasv_max_port=8030
# listen=YES
# anonymous_enable=YES

# Make directories for the servers
# sudo mkdir -p /home/ftp/cfg/{focal,jammy}
# sudo mkdir -p /srv/tftp/xubuntu/{focal,jammy}

# Directories in the old server under /srv/tftp/ubuntu/bionic
# {i386, amd64}
# i386/boot-screens/
# i386/initrd.gz
# i386/linux
# i386/pxelinux.0
# i386/pxelinux.cfg/
# i386/pxelinux.cfg/default

### i386/pxelinux.cfg/default
## D-I config version 2.0 
## search path for the c32 support libraries (libcom32, libutil etc.)
# path ubuntu-installer/i386/boot-screens/
# include ubuntu-installer/i386/boot-screens/menu.cfg
# default ubuntu-installer/i386/boot-screens/vesamenu.c32
# prompt 0
# timeout 0
