#!/bin/bash

set -e # checking of all commands 
set -x # print each command before execution

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
### Create environment variables for key options
####################################################################################
echo "Creating environment variables" >> AMETHST_install.log.txt
#sudo bash << EOSHELL_1
cat >>/home/ubuntu/.profile<<EOF_1
#export AWE_SERVER="http://kbase.us/services/awe/" # KBase production
#export AWE_SERVER="http://140.221.67.190:7080" # KBase dev # external ip
#export AWE_SERVER="http://10.1.16.5:7080" # KBase dev # internal ip
#export AWE_SERVER="http://140.221.67.236:8000" # MG-RAST
#export AWE_SERVER="http://140.221.67.184:8000" # Wolfgang's server 9-19-14
export AWE_SERVER="http://10.1.12.14:8000" # Wolfgang's server, internal ip
export AWE_CLIENT_GROUP="amethst" # ${HOSTNAME}
export HOSTNAME=`hostname`
export GOPATH=/home/ubuntu/gopath
export AWE_DATA="/data/awe/data"
export AWE_WORK="/data/awe/work"
export AWE_LOGS="/data/awe/logs"
EOF_1
. /home/ubuntu/.profile
#EOSHELL_1
echo "DONE creating environment variables" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
####################################################################################

####################################################################################
### set your KB_AUTH_TOKEN and GROUP TOKEN (by hand - is added to ~/.profile below ) ## DON'T FORGET TO ADD KB_AUTH_TOKEN
### THIS SECTION REQUIRED FOR USE AS A COMPUTE CLIENT FOR THE KBase SERVICE VERSION OF AMETHST
####################################################################################
echo "Checking for KB_AUTH_TOKEN and AWE_CLIENT_GROUP_TOKEN variables" >> AMETHST_install.log.txt

if [[ ${KB_AUTH_TOKEN}X = "X" ]]; then
    echo "KB_AUTH_TOKEN is not defined, it must be to proceed"
    echo "KB_AUTH_TOKEN is not defined, it must be to proceed" >> AMETHST_install.log.txt
    exit 1
else
    echo "KB_AUTH_TOKEN = "${KB_AUTH_TOKEN}
    echo "KB_AUTH_TOKEN = "${KB_AUTH_TOKEN} >> AMETHST_install.log.txt
fi

if [[ ${AWE_CLIENT_GROUP_TOKEN}X = "X" ]]; then
    echo "AWE_CLIENT_GROUP_TOKEN is not defined, it must be to proceed"
    echo "AWE_CLIENT_GROUP_TOKEN is not defined, it must be to proceed" >> AMETHST_install.log.txt
    exit 1
else
    echo "AWE_CLIENT_GROUP_TOKEN = "${KB_AUTH_TOKEN}
    echo "AWE_CLIENT_GROUP_TOKEN = "${KB_AUTH_TOKEN} >> AMETHST_install.log.txt
fi

echo "DONE checking for KB_AUTH_TOKEN and AWE_CLIENT_GROUP_TOKEN" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
exit
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
#sudo bash << EOSHELL_3
### for R install later add cran release specific repos to /etc/apt/sources.list
# echo deb http://cran.rstudio.com/bin/linux/ubuntu precise/ >> /etc/apt/sources.list # 12.04 # Only exist for LTS - check version with lsb_release -a
echo deb http://cran.rstudio.com/bin/linux/ubuntu trusty/ >> /etc/apt/sources.list  # 14.04 # Only exist for LTS - check version with lsb_release -a
### add cran public key # this makes it possible to install most current R below
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
### for qiime install later, uncomment the universe and multiverse repositories from /etc/apt/sources.list
sed -e '/verse$/s/^#\{1,\}//' /etc/apt/sources.list > /etc/apt/sources.list.edit; mv /etc/apt/sources.list.edit /etc/apt/sources.list
### update and upgrade
#how apt-get -y install build-essential
apt-get -y install build-essential


unset UCF_FORCE_CONFFOLD
export UCF_FORCE_CONFFNEW=YES
ucf --purge /boot/grub/menu.lst

export DEBIAN_FRONTEND=noninteractive

apt-get -y update   
apt-get -y upgrade  # try without updade # try with --force-yes
apt-get clean 
### install required packages
apt-get --force-yes -o Dpkg::Options::="--force-confnew" --force-yes -fuy upgrade python-dev libncurses5-dev libssl-dev libzmq-dev libgsl0-dev openjdk-6-jdk libxml2 libxslt1.1 libxslt1-dev ant git subversion zlib1g-dev libpng12-dev libfreetype6-dev mpich2 libreadline-dev gfortran unzip libmysqlclient18 libmysqlclient-dev ghc sqlite3 libsqlite3-dev libc6-i386 libbz2-dev libx11-dev libcairo2-dev libcurl4-openssl-dev libglu1-mesa-dev freeglut3-dev mesa-common-dev xorg openbox emacs r-cran-rgl xorg-dev libxml2-dev mongodb-server bzr make gcc mercurial python-qcli
apt-get clean
#EOSHELL_3
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

####################################################################################
### INSTALL cdbtools (Took care of the cdb failure above)
####################################################################################
echo "Installing cdbtools"
echo "Installing cdbtools" >> AMETHST_install.log.txt
#sudo bash << EOSHELL_4
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
#EOSHELL_4
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
#sudo bash << EOFSHELL4
cd /home/ubuntu/
python ./qiime-deploy/qiime-deploy.py /home/ubuntu/qiime_software -f ./AMETHST/qiime_configuration/qiime.amethst.config --force-remove-failed-dirs --force-remove-previous-repos
apt-get -y clean
#EOFSHELL4
echo "DONE Installing Qiime" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
####################################################################################

####################################################################################
### INSTALL most current R on Ubuntu 14.04, install multiple non-base packages
####################################################################################
echo "Installing R" >> AMETHST_install.log.txt
#sudo bash << EOSHELL_5
apt-get -y build-dep r-base # install R dependencies (mostly for image production support)
apt-get -y install r-base   # install R
apt-get clean
# Install R packages, including matR, along with their dependencies
#EOSHELL_5

#sudo bash << EOSHELL_6
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
#EOSHELL_6

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
### INSTALL, CONFIGURE, and START AWE client (Uses Wei's script - commented copies of script and configureation are in appendix below
####################################################################################
### INSTALL
#### DON'T FORGET TO SET A VALUE FOR AWE_CLIENT_GROUP_TOKEN !!!
#### DON'T FORGET TO SET A VALUE FOR AWE_CLIENT_GROUP_TOKEN !!!
#### DON'T FORGET TO SET A VALUE FOR AWE_CLIENT_GROUP_TOKEN !!!

echo "Installing, configuring, and starting the AWE client" >> AMETHST_install.log.txt
#sudo bash << EOSHELL_9
cd /home/ubuntu
curl http://www.mcs.anl.gov/~wtang/files/install_aweclient.sh > install_aweclient.sh
chmod u=+x install_aweclient.sh
./install_aweclient.sh
#source /home/ubuntu/.profile
. source /home/ubuntu/.profile
### CONFIGURE

# config template from https://github.com/MG-RAST/AWE/blob/master/templates/awec.cfg.template
cat >/home/ubuntu/awe_client_config<<EOF_4
[Directories]
# See documentation for details of deploying Shock
site=$GOPATH/src/github.com/MG-RAST/AWE/site
data=${AWE_DATA}
logs=${AWE_LOGS}

[Args]
debuglevel=0

[Client]
workpath=${AWE_WORK}
supported_apps=*
app_path=/home/ubuntu/apps/bin
serverurl=${AWE_SERVER}
name=${HOSTNAME}
group=${AWE_CLIENT_GROUP}
auto_clean_dir=true
worker_overlap=false
print_app_msg=true
clientgroup_token=${AWE_CLIENT_GROUP_TOKEN}
pre_work_script=
# arguments for pre-workunit script execution should be comma-delimited
pre_work_script_args=
#for openstack client only
openstack_metadata_url=http://169.254.169.254/2009-04-04/meta-data
domain=default-domain #e.g. megallan
EOF_4

# create some easy links for awe data, log and work folders
cd /home/ubuntu
ln -s ${AWE_DATA}
ln -s ${AWE_WORK}
ln -s ${AWE_LOGS}

# write the auth token to the profile
echo "export KB_AUTH_TOKEN=\"${KB_AUTH_TOKEN}\"" >> ~/.profile ## DON'T FORGET TO ADD KB_AUTH_TOKEN to ~/.profile

#EOSHELL_9
echo "DONE installing AWE" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
####################################################################################


####################################################################################
### Prep /etc/rc.local
####################################################################################
#sudo bash << EOSHELL_2
echo "editing /etc/rc.local to start amethst on boot/reboot" >> AMETHST_install.log.txt
rm /etc/rc.local

cat >/etc/rc.local<<EOF_2
#!/bin/sh -e
. /home/ubuntu/.profile
# /home/ubuntu/Kevin_Installers/change_tmp.sh
sudo mkdir -p ${AWE_DATA}
sudo mkdir -p ${AWE_WORK}
sudo mkdir -p ${AWE_LOGS}
sudo screen -S awe_client -d -m bash -c "source /home/ubuntu/.profile; echo \$PATH > /home/ubuntu/awe_screen_pathlog.txt; /home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config > /home/ubuntu/awe_screen_log.txt"

EOF_2
chmod +x /etc/rc.local
#EOSHELL_2
echo "DONE editing /etc/rc.local" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
####################################################################################

####################################################################################
echo "INSTALLATION of AMETHST is COMPLETE -- the VM will reboot in 10 seconds" >> AMETHST_install.log.txt
echo "________________________________________________________" >> AMETHST_install.log.txt
sleep 10
sudo reboot
####################################################################################




####################################################################################
####################################################################################
####################################################################################
# DONE JUST NOTES FROM HERE ON
# DONE JUST NOTES FROM HERE ON
# DONE JUST NOTES FROM HERE ON
# DONE JUST NOTES FROM HERE ON
# DONE JUST NOTES FROM HERE ON


####################################################################################
####################################################################################
###### Old config template
# cat >/home/ubuntu/awe_client_config<<EOF_4
# [Directories]
# # See documentation for details of deploying Shock
# site=$GOPATH/src/github.com/MG-RAST/AWE/site
# data=/mnt/data/awe/data
# logs=/mnt/data/awe/logs

# [Args]
# debuglevel=0

# [Client]
# totalworker=2
# workpath=/mnt/data/awe/work
# supported_apps=*
# app_path=/home/ubuntu/apps/bin
# serverurl=${AWE_SERVER}
# name=${HOSTNAME}
# group=${AWE_CLIENT_GROUP}
# auto_clean_dir=true
# worker_overlap=false
# print_app_msg=true
# username=
# password=
# #for openstack client only
# #openstack_metadata_url=http://169.254.169.254/2009-04-04/meta-data
# domain=default-domain #e.g. megallan
# EOF_4
# ####################################################################################
# ####################################################################################








# # Try it this way?

# sudo bash << EOSHELL_10

# cat >>/home/ubuntu/start_awe.sh<<EOF_5
# source /home/ubuntu/.profile;
# source /home/ubuntu/AMETHST/installation/AMETHST_AWE_env.txt;
# echo $PATH > /home/ubuntu/awe_client.screen.path_log.txt;
# /home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config;
# EOF_5

# chmod +x /home/ubuntu/start_awe.sh

# cat >>/etc/rc.local<<EOF_6
# sudo screen -S awe_client -d -m bash -c "/home/ubuntu/start_awe.sh"
# sudo mkdir -p /mnt/data/awe/awe_data
# sudo mkdir -p /mnt/data/awe/work
# sudo mkdir -p /mnt/data/awe/logs
# EOF_6

# EOSHELL_10


# ####################################################################################
# ####################################################################################
# ####################################################################################
# ### Just notes from here on
# # 140.221.84.145
# # 140.221.84.148
# # http://kbase.us/services/awemonitor.html
# ####################################################################################

# cat >>/etc/rc.local<<EOF_5
# . /home/ubuntu/.profile
# #echo $PATH > /home/ubuntu/my_path
# /home/ubuntu/Kevin_Installers/change_tmp.sh
# sudo screen -S awe_client -d -m bash -c "date; echo \$PATH > /home/ubuntu/amethst_screen_path; source /home/ubuntu/.profile; source /home/ubuntu/AMETHST/installation/AMETHST_AWE_env.txt; /home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config"
# sudo mkdir -p /mnt/data/awe/awe_data
# sudo mkdir -p /mnt/data/awe/work
# sudo mkdir -p /mnt/data/awe/logs
# EOF_5

# EOSHELL_10

# ############################################################################################################################################################################################################
# ############################################################################################################################################################################################################
# # ORIGINAL WORKING SOLUTION ( /etc/rc.local/ )
# # ORIGINAL WORKING SOLUTION
# # ORIGINAL WORKING SOLUTION

# #!/bin/sh -e                                                                                                                                                                  
# . /home/ubuntu/.profile
# #echo $PATH > /home/ubuntu/my_path
# /home/ubuntu/Kevin_Installers/change_tmp.sh
# sudo screen -S awe_client -d -m bash -c "date; echo \$PATH > /home/ubuntu/awe_screen_pathlog1.txt; source /home/ubuntu/.profile; source /home/ubuntu/AMETHST/installation/AMETHST_AWE_env.txt; echo \$PATH > /home/ubuntu/awe_screen_pathlog2.txt; /home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config"
# sudo mkdir -p /mnt/data/awe/awe_data
# sudo mkdir -p /mnt/data/awe/work
# sudo mkdir -p /mnt/data/awe/logs
# ############################################################################################################################################################################################################
# ############################################################################################################################################################################################################



# ########################################################################################################################################################################################################################################################################################################################################################################################################################



# ################################################################
# # new group name and key

# #









# . /home/ubuntu/.profile 
# . /home/ubuntu/AMETHST/installation/AMETHST_AWE_env.txt 
# sudo /home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config &
# echo $PATH > /home/ubuntu/path_log.txt
# printenv > /home/ubuntu/env_log.txt"
# sudo mkdir -p /mnt/data/awe/awe_data
# sudo mkdir -p /mnt/data/awe/work
# sudo mkdir -p /mnt/data/awe/logs
# #sudo ln -s /mnt/data/awe/awe_data
# #sudo ln -s /mnt/data/awe/work
# #sudo ln -s /mnt/data/awe/logs
# EOF_5

# EOSHELL_10






# cd /home/ubuntu/AMETHST
# sudo git pull
# cd /home/ubuntu/Kevin_Installers
# sudo git pull
# cd ~
# . /home/ubuntu/.profile
# . /home/ubuntu/AMETHST/installation/AMETHST_AWE_env.txt
# sudo /home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config &
# echo $PATH > /home/ubuntu/screen_path_log.txt
# printenv > /home/ubuntu/screen_env_log.txt
# sudo mkdir -p /mnt/data/awe/awe_data
# sudo mkdir -p /mnt/data/awe/work
# sudo mkdir -p /mnt/data/awe/logs
# echo "test" > /home/ubuntu/some_file.txt
# #sudo ln -s /mnt/data/awe/awe_data
# #sudo ln -s /mnt/data/awe/work
# #sudo ln -s /mnt/data/awe/logs





# ####################################################################################
# ### DONE

# # THis does not work
# # sudo screen -S awe_client -d -m /home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config



# # #!/bin/sh -e
# # . /home/ubuntu/.profile
# # echo $PATH > /home/ubuntu/my_path
# # /home/ubuntu/Kevin_Installers/change_tmp.sh
# # ##sudo -E screen -l -S awe_client -d -m /home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config
# # ##sudo -E screen -S awe_client -d -m /home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config
# # sudo screen -S test -d -m /home/ubuntu/bin/print_path.sh
# # #sudo screen -S bash -c "echo \$PATH > please_work_path; awe_client -d -m /home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config"
# # #sudo screen -S awe_client -d -m /home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config
# # # sudo -i
# # # echo $PATH >> /home/ubuntu/my_path 

# ### /home/ubuntu/bin/print_path.sh
# ##!/bin/bash                                                                                                                                                                      
# #echo $PATH > /home/ubuntu/my_path.screen










# ####################################################################################


# # screen -S awe_client -d -m bash -c "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/home/ubuntu/AMETHST;/home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config"







# # echo "sudo screen -S awe_client -d -m /home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config" >> ~/etc/rc.local

# # Wolfgang 7-24-14
# # workaround:

# # change
# # sudo screen -S awe_client -d -m /home/ubuntu/gopath/bin/awe-client -conf
# # /home/ubuntu/awe_client_config

# # into (something like)
# # sudo screen -S awe_client -d -m bash -c "PATH=XXXX
# # /home/ubuntu/gopath/bin/awe-client -conf /home/ubuntu/awe_client_config"








# ####################################################################################
# ####################################################################################
# ####################################################################################
# ####################################################################################
# ### APPENDIX

# ### FOR ALL THINGS AWE SEE http://www.mcs.anl.gov/~wtang/files/awe-example.pdf # and
# ### https://github.com/MG-RAST/AWE/wiki/Manual-to-Get-Started # and
# ### https://github.com/MG-RAST/AWE/

# ####################################################################################
# ### INSTALL AWE
# ### from http://www.mcs.anl.gov/~wtang/files/install_aweclient.sh # 7-10-14
# ####################################################################################
# #!/bin/bash
# # set -xe
# # INSTALLDIR=${HOME}
# # #here we could wait for volume to be attached
# # cd ${INSTALLDIR}

# # # create directories:
# # for i in data logs work ; do mkdir -p ${INSTALLDIR}/data/awe/${i} ; chmod 777 ${INSTALLDIR}/data/awe/${i} ; done
# # cd ${INSTALLDIR}
# # sudo apt-get update
# # sudo apt-get -y install mongodb-server bzr make gcc mercurial git
# # if [ ! -e ${INSTALLDIR}/go/bin/go ]
# # then
# # mkdir -p ${INSTALLDIR}/gopath
# # hg clone -u release https://code.google.com/p/go
# # cd ${INSTALLDIR}/go/src
# # ./all.bash
# # fi
# # export GOPATH=${INSTALLDIR}/gopath
# # export PATH=$PATH:${INSTALLDIR}/go/bin:${INSTALLDIR}/gopath/bin
# # n=`grep "export GOPATH=${INSTALLDIR}/gopath" ~/.bashrc | wc -l`
# # if [ $n -eq 0 ]
# # then
# #     echo "export GOPATH=${INSTALLDIR}/gopath" >> ~/.bashrc
# #     echo "PATH=\$PATH:${INSTALLDIR}/go/bin:${INSTALLDIR}/gopath/bin" >> ~/.bashrc
# # fi
# # if [ ! -d ${INSTALLDIR}/gopath/src/github.com/MG-RAST/AWE ]
# # then
# # go get github.com/MG-RAST/AWE/...
# # else
# # cd ${INSTALLDIR}/gopath/bin
# # rm -f ${INSTALLDIR}/gopath/bin/AWE_BUILD.sh
# # wget http://www.mcs.anl.gov/~wtang/files/AWE_BUILD.sh
# # chmod +x AWE_BUILD.sh
# # #go get will build when getting the code, AWE_BUILD.sh is used to build if code changes
# # cd ${INSTALLDIR}/gopath/src/github.com/MG-RAST/AWE
# # git pull origin master
# # ${INSTALLDIR}/gopath/bin/AWE_BUILD.sh
# # fi
# # mkdir -p ${INSTALLDIR}/etc
# # #upstart symlink
# # sudo ln -s -f /lib/init/upstart-job /etc/init.d/awe-client
# # cd ${INSTALLDIR}
# # sudo rm -f awe-client.conf /etc/init/awe-client.conf
# # wget http://www.mcs.anl.gov/~wtang/files/awe-client.conf 
# # sudo mv awe-client.conf /etc/init/awe-client.conf
# # # install scripts for software other than AWE client
# # mkdir -p ${INSTALLDIR}/install_scripts/
# # FILESPEC=*.sh
# # for SCRIPT in ${INSTALLDIR}/install_scripts/$FILESPEC
# # do
# # if [ -x $SCRIPT ]
# # then
# # echo "Executing install script: $SCRIPT"
# # $SCRIPT
# # fi
# # done
# # cd ${INSTALLDIR}
# # echo "install awe done!"
# ####################################################################################

# ####################################################################################
# ### CONFIGURE AWE (client only)
# ### from https://raw.githubusercontent.com/MG-RAST/AWE/master/templates/awec.cfg.template
# ####################################################################################
# # [Directories]
# # # See documentation for details of deploying Shock
# # site=$GOPATH/src/github.com/MG-RAST/AWE/site
# # data=/mnt/data/awe/data
# # logs=/mnt/data/awe/logs

# # [Args]
# # debuglevel=0

# # [Client]
# # totalworker=2
# # workpath=/mnt/data/awe/work
# # supported_apps=
# # app_path=/home/ubuntu/apps/bin
# # serverurl=http://localhost:8001
# # name=default_client
# # group=default_group
# # auto_clean_dir=false
# # worker_overlap=false
# # print_app_msg=true
# # username=
# # password=
# # #for openstack client only
# # #openstack_metadata_url=http://169.254.169.254/2009-04-04/meta-data
# # domain=default-domain #e.g. megallan
# ####################################################################################

# ####################################################################################
# ### INSTALL UPDATED R ONLY
# ####################################################################################
# # ### add cran public key # this makes it possible to install most current R below
# # apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
# # ### for qiime install later, uncomment the universe and multiverse repositories from /etc/apt/sources.list
# # echo deb http://cran.rstudio.com/bin/linux/ubuntu trusty/ >> /etc/apt/sources.list
# # sed -e '/verse$/s/^#\{1,\}//' /etc/apt/sources.list > /etc/apt/sources.list.edit; mv /etc/apt/sources.list.edit /etc/apt/sources.list
# # ### update and upgrade
# # apt-get -y update
# # apt-get -y upgrade 
# # apt-get -y build-dep r-base # install R dependencies (mostly for image production support)
# # apt-get -y install r-base   # install R
# # ### Install addition packages
# # cat >install_packages.r<<EOF
# # # Install these packages 
# # install.packages(c("KernSmooth", "codetools", "httr", "scatterplot3d"), dependencies = TRUE, repos="http://cran.rstudio.com/", lib="/usr/lib/R/library")
# # q()
# # EOF
# # R --vanilla --slave < install_packages.r
# # rm install_packages.r
# ####################################################################################

# ####################################################################################
# ### INSTALL cdbtools (Took care of the cdb failure above)
# ####################################################################################
# # echo "Installing cdbtools"
# # sudo bash << EOFSHELL5
# # CURL="http://sourceforge.net/projects/cdbfasta/files/latest/download?source=files"
# # CBASE="cdbfasta"
# # #echo "###### downloading $CBASE ######"
# # curl -L $CURL > $CBASE".tar.gz"
# # tar zxf $CBASE".tar.gz"
# # #echo "###### installing $CBASE ######"
# # pushd $CBASE
# # make
# # cp cdbfasta $IDIR/bin/.
# # cp cdbyank $IDIR/bin/.
# # popd
# # rm $CBASE".tar.gz"
# # rm -rf $CBASE
# # EOFSHELL5
# # echo "DONE installing cdbtools"
# ####################################################################################


# ####################################################################################
# ####################################################################################
# ####################################################################################

# ####################################################################################
# ####################################################################################
# ####################################################################################