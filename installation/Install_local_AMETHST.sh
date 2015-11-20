#!/bin/bash

# bash -x Install_local_AMETHST.sh > debug.log 2>&1 # run like this for verbose debugging 

set -e # checking of all commands 
set -x # print each command before execution

# Make sure KB_AUTH_TOKEN and AWE_CLIENT_GROUP_TOKEN have valid values then:
# sudo -E Install_AMETHST_compute_node.havannah.sh

echo "AMETHST INSTALLER START" > AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt

# NOTES: 7-22-14
# I have never gotten this script to run to completion automatically.
# It always breaks on installations of Qiime, but almost never at the same point.
# Long term solution is probably to use Wolfgang's docker for Qiime
# I have used this procedure to create this Magellan snapshot:
# Name: mg_amethst_comp.9-26-14
# ID :  1b553e16-895e-4094-ae66-eff184d6217f                                                                                                                         
####################################################################################
### Script to create an AMETHST compute node from 14.04 bare
### used this to spawn a 14.04 VM:
# vmAWE.pl --create=1 --flavor_name=idp.100 --groupname=am_compute --key_name=kevin_share --image_name="Ubuntu Trusty 14.04" --namelist=yamato
### Then run these commands to download this script and run it
# sudo apt-get -y install git
# git clone https://github.com/DrOppenheimer/Kevin_Installers.git
# ln -s ./Kevin_Installers/Install_AMETHST_compute_node.sh
# ./Install_AMETHST_compute_node.sh
### To start nodes preconfigured with this script
# NEW MAGELLAN (Havvanah)
# vmAWE.pl --create=5 --flavor_name=i2.2xlarge.sd --groupname=am_compute --key_name=kevin_share --image_name="am_comp.8-18-14" --nogroupcheck --greedy
# vmAWE.pl --create=5 # if other options are specified in .bulkvm
# OLD MAGELLAN (NOVUS)
# vmAWE.pl --create=5 --flavor_name=idp.100 --groupname=am_compute --key_name=kevin_share --image_name="am_comp.8-18-14" --nogroupcheck --greedy
# vmAWE.pl --create=5 # if other options are specified in .bulkvm


# MG-RAST-Dev:
# compute nodes
#      Name: mg_amethst_comp.9-10-14
#      ID: c470c6df-54d9-4738-9c73-36d91a30300e
#      # vmAWE.pl --create=5 --flavor_name=i2.2xlarge.sd --groupname=amethst --key_name=kevin_share --image_name="mg_amethst_comp.9-10-14" --nogroupcheck --greedy 
# service node
#      Name: 
#      ID: 
#      # vmAWE.pl --create=5 --flavor_name=i2.medium.sd --groupname=amethst --key_name=kevin_share --image_name="mg_amethst_comp.9-10-14" --nogroupcheck --greedy

# KBASE_Dev
# compute nodes
#      Name: kb_amethst_comp.9-10-14
#      ID: d9be941e-2fbf-4286-b23f-805c74c09784
# service node
#      Name: kb_amethst_service.9-10-14
#      ID: d27cdc97-8782-4a4b-aac0-1e570263072d




####################################################################################


####################################################################################
### move /tmp to /mnt/tmp (compute frequntly needs the space, exact amount depends on data)
####################################################################################
### First - create script that will check for proper /tmp confuguration and adjust at boot
### Then reference a script (downloaded from git later) that will make sure tmp is in correct
### location when this is saved as an image
### replace tmp on current instance - add acript to /etc/rc.local that will cause it to be replaced in VMs generated from snapshot
### DON'T DO THIS FOR THE NEW MAGELLAN VMS!
#sudo bash << EOSHELL_2
## rm -r /tmp; mkdir -p /mnt/tmp/; chmod 777 /mnt/tmp/; sudo ln -s /mnt/tmp/ /tmp
#rm /etc/rc.local

#cat >/etc/rc.local<<EOF_2
##!/bin/sh -e
#. /home/ubuntu/.profile
## /home/ubuntu/Kevin_Installers/change_tmp.sh
#EOF_2

#chmod +x /etc/rc.local
#EOSHELL_2
#echo "DONE moving /tmp"
####################################################################################

####################################################################################
### install dependencies for qiime_deploy and R # requires one manual interaction
####################################################################################
echo "Installing dependencies for qiime_deploy and R" >> AMETHST_install.log.txt
cd /home/ubuntu
sudo bash << EOSHELL_3
### for R install later add cran release specific repos to /etc/apt/sources.list
# echo deb http://cran.rstudio.com/bin/linux/ubuntu precise/ >> /etc/apt/sources.list # 12.04 # Only exist for LTS - check version with lsb_release -a
echo deb http://cran.rstudio.com/bin/linux/ubuntu trusty/ >> /etc/apt/sources.list  # 14.04 # Only exist for LTS - check version with lsb_release -a
### add cran public key # this makes it possible to install most current R below
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
### for qiime install later, uncomment the universe and multiverse repositories from /etc/apt/sources.list, then remove prefix space
sed -e '/verse$/s/^#\{1,\}//' /etc/apt/sources.list > /etc/apt/sources.list.edit; mv /etc/apt/sources.list.edit /etc/apt/sources.list
sed -e '/verse$/s/^ \{1,\}//' /etc/apt/sources.list > /etc/apt/sources.list.edit; mv /etc/apt/sources.list.edit /etc/apt/sources.list
### update and upgrade
#how apt-get -y install build-essential
apt-get update
apt-get -y install build-essential

unset UCF_FORCE_CONFFOLD
export UCF_FORCE_CONFFNEW=YES
ucf --purge /boot/grub/menu.lst
export DEBIAN_FRONTEND=noninteractive
   
apt-get -y upgrade --force-yes
apt-get clean 
### install required packages
apt-get --force-yes -o Dpkg::Options::="--force-confnew" --force-yes -fuy upgrade python-dev libncurses5-dev libssl-dev libzmq-dev libgsl0-dev openjdk-6-jdk libxml2 libxslt1.1 libxslt1-dev ant git subversion zlib1g-dev libpng12-dev libfreetype6-dev mpich2 libreadline-dev gfortran unzip libmysqlclient18 libmysqlclient-dev ghc sqlite3 libsqlite3-dev libc6-i386 libbz2-dev libx11-dev libcairo2-dev libcurl4-openssl-dev libglu1-mesa-dev freeglut3-dev mesa-common-dev xorg openbox emacs r-cran-rgl xorg-dev libxml2-dev mongodb-server bzr make gcc mercurial python-qcli
apt-get clean
EOSHELL_3
echo "DONE Installing dependencies for qiime_deploy and R" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
# sudo dpkg --configure -a # if you run tin trouble
# /etc/apt/sources.list  redundancy
####################################################################################

####################################################################################
### Clone repos for qiime-deploy and AMETHST
####################################################################################
echo "Cloning the qiime-deploy and AMETHST git repos" >> AMETHST_install.log.txt
cd /home/ubuntu/
git clone git://github.com/qiime/qiime-deploy.git
git clone https://github.com/MG-RAST/AMETHST.git
git clone https://github.com/DrOppenheimer/Kevin_Installers.git
echo "DONE cloning the qiime-deploy and AMETHST git repos" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
####################################################################################

# got to here (past GRUB!) - 11-20-15

####################################################################################
### INSTALL cdbtools (Took care of the cdb failure above)
####################################################################################
echo "Installing cdbtools"
echo "Installing cdbtools" >> AMETHST_install.log.txt
sudo bash << EOSHELL_4
apt-get install cdbfasta
# mkdir /home/ubuntu/bin
# curl -L "http://sourceforge.net/projects/cdbfasta/files/latest/download?source=files" > cdbfasta.tar.gz
# tar zxf cdbfasta.tar.gz
# pushd cdbfasta
# make
# cp cdbfasta /home/ubuntu/bin/.
# cp cdbyank /home/ubuntu/bin/.
# popd
# rm cdbfasta.tar.gz
# rm -rf /home/ubuntu/cdbfasta
EOSHELL_4
echo "DONE installing cdbtools" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
####################################################################################

####################################################################################
### INSTALL QIIME ### also see https://github.com/qiime/qiime-deploy 4-23-14
####################################################################################
## NOTE: Qiime isntallation frequently breaks, and you have to continue by hand 
## does not break in a consistent way
## This will also install cdbfasta & cdbyank, python and perl
## Uncomment the universe and multiverse repositories from /etc/apt/sources.list
echo "Installing Qiime"
echo "Installing Qiime" >> AMETHST_install.log.txt
sudo bash << EOFSHELL4
cd /home/ubuntu/
python ./qiime-deploy/qiime-deploy.py /home/ubuntu/qiime_software -f ./AMETHST/qiime_configuration/qiime.amethst.config --force-remove-failed-dirs --force-remove-previous-repos
apt-get -y clean
EOFSHELL4
echo "DONE Installing Qiime" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
####################################################################################

####################################################################################
### INSTALL most current R on Ubuntu 14.04, install multiple non-base packages
####################################################################################
echo "Installing R" >> AMETHST_install.log.txt
sudo bash << EOSHELL_5
apt-get -y build-dep r-base # install R dependencies (mostly for image production support)
apt-get -y install r-base   # install R
apt-get clean
# Install R packages, including matR, along with their dependencies
EOSHELL_5

# got to here 11-20-15

sudo bash << EOSHELL_6
cat >install_packages.r<<EOF_3
## Simple R script to install packages not included as part of r-base
# Install these packages for matR and AMETHST
install.packages(c("KernSmooth", "codetools", "httr", "scatterplot3d", "rgl", "matlab", "ecodist", "gplots", "devtools", "RJSONIO", "animation"), dependencies = TRUE, repos="http://cran.rstudio.com/", lib="/usr/lib/R/library")
# Install these packages for Qiime
install.packages(c("ape", "random-forest", "r-color-brewer", "klar", "vegan", "ecodist", "gtools", "optparse"), dependencies = TRUE, repos="http://cran.rstudio.com/", lib="/usr/lib/R/library")
source("http://bioconductor.org/biocLite.R")
biocLite (pkgs=c("DESeq","preprocessCore"), lib="/usr/lib/R/library")
# Install matR
library(devtools)
install_github(repo="MG-RAST/matR", dependencies=FALSE, ref="3d068d0c4c644083f588379ca111a575a409c797") # Kevin's July 10 commit
library(matR)
dependencies()
q()
EOF_3

R --vanilla --slave < install_packages.r
rm install_packages.r
EOSHELL_6

echo "DONE installing R" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
####################################################################################

####################################################################################
#### install perl packages
####################################################################################
echo "Installing perl packages" >> AMETHST_install.log.txt
#sudo bash << EOSHELL_7
#curl -L http://cpanmin.us | perl - --sudo App::cpanminus
curl -L http://cpanmin.us | perl - --sudo Statistics::Descriptive
#cpan -f App::cpanminus # ? if this is first run of cpan, it will have to configure, can't figure out how to force yes for its questions
#                       # this may already be installed
#cpanm Statistics::Descriptive
#EOSHELL_7
echo "DONE installing perl packages" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
####################################################################################

####################################################################################
### Add AMETHST to Envrionment Path (permanently)
####################################################################################
echo "Adding AMETHST to the PATH" >> AMETHST_install.log.txt
#sudo bash << EOSHELL_8
#sudo bash 
echo "export \"PATH=$PATH:/home/ubuntu/AMETHST"\" >> /home/ubuntu/.profile
#source /home/ubuntu/.profile
#exit
#EOSHELL_8
. /home/ubuntu/.profile
echo "DONE adding AMETHST to the PATH (full PATH is in /home/ubuntu/.profile)" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
# PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games" # original /etc/environment path
####################################################################################

####################################################################################
### Test AMETHST functionality
####################################################################################
echo "TESTING AMETHST FUNCTIONALITY" >> AMETHST_install.log.txt
#source /home/ubuntu/.profile
. /home/ubuntu/.profile
test_amethst.sh
echo "DONE testing AMETHST functionality" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
####################################################################################

####################################################################################
### Test AMETHST functionality
####################################################################################
### DONE
echo "DONE installing local AMETHST" >> AMETHST_install.log.txt
####################################################################################

