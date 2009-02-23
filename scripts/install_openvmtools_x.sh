#!/bin/bash

OPEN_VM_TOOLS_VERSION="2009.02.18-148847"
OPEN_VM_TOOLS_MIRROR_PATH="http://internap.dl.sourceforge.net/sourceforge/open-vm-tools"
URIPARSER_VERSION="0.7.4"
URIPARSER_MIRROR_PATH="http://internap.dl.sourceforge.net/sourceforge/uriparser"

# Prior to running this script, you must attach the VMWare Tools iso to the cdrom drive.
# You can do this with VMWare Server (and other consoles) by selecting the "Install VMWare Tools" option.
# The script will mount the drive and extract the package.

function die()
{
    echo $*
    exit 1
}

function checkRoot()
{
    if [ ! $( id -u ) -eq 0 ]; then
        die "Must have super-user rights to run this script.  Run with the command 'sudo $0'"
    fi
}

function installPackages()
{
    for package in "$@"; do
        if [ -z "`dpkg -l |grep $package`" ]; then
            packages="$packages $package"
        fi
    done
    if [ ! -z "$packages" ]; then
        apt-get install -y --force-yes $packages
        if [ ! $? -eq 0 ]; then
            die "Script encountered an error during package installation.  Check errors and retry."
        fi
    fi
}

function checkDependencies()
{
    if [ -z "`dpkg -l |grep wget`" ]; then
        echo "Install script requires wget package.  Script will install package."
        packages="wget"
    fi
    if [ ! -x /usr/bin/killall ]; then
        echo "VMware tools requires 'killall'.  Script will install psmisc package"
        packages="$packages psmisc"
    fi
    installPackages $packages
}
# ----------
# Main script
# ----------

checkRoot

if [ ! -f /media/cdrom0/VMwareTools-1.0.8-126538.tar.gz ]; then
    die "VMware Tools tar ball not found.  Make sure you have setup the VMWare to install tools and try again."
fi

checkDependencies

if [ ! -d vmwaretools ]; then
    mkdir vmwaretools
fi
cd vmwaretools

wget -c $OPEN_VM_TOOLS_MIRROR_PATH/open-vm-tools-$OPEN_VM_TOOLS_VERSION.tar.gz
if [ ! $? -eq 0 ]; then
    die "Encountered error retrieving open-vm-tools tar ball.  Check messages and try again."
fi
echo -n "Extracting open-vm-tools tar ball..."
tar xfz open-vm-tools-$OPEN_VM_TOOLS_VERSION.tar.gz
if [ ! $? -eq 0 ]; then
    die "\nEncountered error extracting open-vm-tools.  Check messages and try again."
fi
echo

wget -c $URIPARSER_MIRROR_PATH/uriparser-$URIPARSER_VERSION.tar.gz
if [ ! $? -eq 0 ]; then
    die "Encountered error retrieving uriparser tar ball.  Check messages and try again."
fi
echo -n "Extracting uriparser tar ball..."
tar xfz uriparser-$URIPARSER_VERSION.tar.gz
if [ ! $? -eq 0 ]; then
    die "\nEncountered error extracting uriparser.  Check messages and try again."
fi
echo 

echo -n "Extracting VMwareTools tar ball..."
tar xfz /media/cdrom0/VMwareTools-*.tar.gz
if [ ! $? -eq 0 ]; then
    die "Encountered error extracting VMWareTools.  Check messages and try again."
fi
echo

installPackages build-essential libgtk2.0-dev xorg-dev libproc-dev libicu-dev \
libdumbnet-dev libglib2.0-dev libgtkmm-2.4-dev libnotify-dev libfuse-dev \
linux-headers-`uname -r`

cd uriparser-*
./configure
if [ ! $? -eq 0 ]; then
    die "Configuration of uriparser was not successful.  Check errors for additional packages not installed by the script and try again."
fi
make
if [ ! $? -eq 0 ]; then
    die "Make of uriparser was not successful.  Cannot continue."
fi
make install
if [ ! $? -eq 0 ]; then
    die "Install of uriparser was not successful.  Cannot continue."
fi
export CFLAGS="-I /usr/local/include/uriparser"
export CPPFLAGS="-I /usr/local/include/uriparser"
cd ..
    
cd open-vm-tools-*
./configure
if [ ! $? -eq 0 ]; then
    die "Configuration of open-vm-tools was not successful.  Check errors for additional packages not installed by the script and try again."
fi
make
if [ ! $? -eq 0 ]; then
    die "Make of open-vm-tools was not successful.  Cannot continue."
fi

cd modules/linux
for i in *
do
    mv ${i} ${i}-only
    tar -cf ${i}.tar ${i}-only
done
cd ../../..

mv -f open-vm-tools-*/modules/linux/*.tar vmware-tools-distrib/lib/modules/source/

cd vmware-tools-distrib
./vmware-install.pl --default


