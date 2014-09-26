#!/bin/bash

# Recipe for creating a kevin.land VM -- 
# a vm with my usual analytical and AWE -based tools


####################################################################################
### install dependencies for qiime_deploy and R # requires one manual interaction
####################################################################################
echo "Installing dependencies for qiime_deploy and R"
cd /home/ubuntu
sudo bash << EOSHELL_1
### for R install later add cran release specific repos to /etc/apt/sources.list
# echo deb http://cran.rstudio.com/bin/linux/ubuntu precise/ >> /etc/apt/sources.list # 12.04 # Only exist for LTS - check version with lsb_release -a
echo deb http://cran.rstudio.com/bin/linux/ubuntu trusty/ >> /etc/apt/sources.list  # 14.04 # Only exist for LTS - check version with lsb_release -a
### add cran public key # this makes it possible to install most current R below
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
### for qiime install later, uncomment the universe and multiverse repositories from /etc/apt/sources.list
sed -e '/verse$/s/^#\{1,\}//' /etc/apt/sources.list > /etc/apt/sources.list.edit; mv /etc/apt/sources.list.edit /etc/apt/sources.list
### update and upgrade
apt-get -y install build-essential
apt-get -y update
apt-get -y upgrade
apt-get clean 
### install required packages
apt-get -y --force-yes upgrade python-dev libncurses5-dev libssl-dev libzmq-dev libgsl0-dev openjdk-6-jdk libxml2 libxslt1.1 libxslt1-dev ant git subversion zlib1g-dev libpng12-dev libfreetype6-dev mpich2 libreadline-dev gfortran unzip libmysqlclient18 libmysqlclient-dev ghc sqlite3 libsqlite3-dev libc6-i386 libbz2-dev libx11-dev libcairo2-dev libcurl4-openssl-dev libglu1-mesa-dev freeglut3-dev mesa-common-dev xorg openbox emacs r-cran-rgl xorg-dev libxml2-dev mongodb-server bzr make gcc mercurial python-qcli
apt-get clean
EOSHELL_1
echo "DONE Installing dependencies for qiime_deploy and R"
####################################################################################
# if there is a problem try this
# sudo dpkg --configure -a





####################################################################################
### INSTALL AWE Tools (from https://docs.google.com/document/d/1LO41UQvdJXXqY5_3azxuD7yhs1CH5UF-o_jm4wsVvXo/edit#)
####################################################################################
# clone libraries and add them to the path
sudo bash << EOSHELL_2

# clone repos from git and add them to the PATH
cd /home/ubuntu/
mkdir -p git
cd /home/ubuntu/git
git clone https://github.com/wtangiit/vmScriptAWE.git
git clone https://github.com/wgerlach/BulkVM.git
cat >>/home/ubuntu/.profile<<EOF_1
#PATH="$PATH:/home/ubuntu/git/vmScriptAWE:/home/ubuntu/git/BulkVM"
EOF_1

# install some perl modiles
cpan App::cpanminus
cpanm LWP::UserAgent
cpanm LWP::Protocol::https
apt-get -y install libjson-xs-perl

EOSHELL_2

# in ~/git/vmScriptAWE, create the following links
mkdir /home/ubuntu/bin
cd /home/ubuntu/bin
ln -s /home/ubuntu/git/BulkVM/SubmitVM.pm
ln -s /home/ubuntu/git/BulkVM/ManageBulkInstances.pm
ln -s /home/ubuntu/git/vmScriptAWE/vmAWE.pl

# you have to get token (e.g.)
curl --user my_username 'https://nexus.api.globusonline.org/goauth/token?grant_type=client_credentials' | json_xs > my_token
# it will ask you for a password
# You will have to add the following to ~/.profile
export KB_AUTH_TOKEN="YOUR_KEY"
export OS_USERNAME=my_username
export OS_PASSWORD=my_password
export OS_AUTH_URL=https://cloud.mcs.anl.gov:5443/v2.0
export OS_TENANT_NAME=MG-RAST-DEV
export OS_AUTH_STRATEGY=keystone

# source profile
source ~/.profile

# test
vmAWE.pl --info

# First time didn't work - did the following to fix, and then it worked
sudo chmod +x /home/ubuntu/git/BulkVM/SubmitVM.pm
sudo chmod +x /home/ubuntu/git/BulkVM/ManageBulkInstances.pm
sudo chmod +x /home/ubuntu/git/vmScriptAWE/vmAWE.pl

sudo cpan install Parallel::ForkManager File::Flock JSON Text::ASCIITable LWP::Protocol::https

sudo apt-get install libfile-flock-perl 

# made separate config for kbase-dev and mgrast-dev

source ~/.mgrast_profile
source ~/.kbase_profile
####################################################################################


cat >>/home/ubuntu/.profile<<EOF_1

export AWE_SERVER="http://kbase.us/services/awe/" # "http://140.221.84.148:8000"
export AWE_CLIENT_GROUP="amethst"
export HOSTNAME=${HOSTNAME}
export GOPATH=/home/ubuntu/gopath
EOF_1



####################################################################################




####################################################################################
### INSTALL MG-RAST-Tools
####################################################################################
echo "Installing MG-RAST-Tools and dependencies"
echo "script created from history with Wolfgang's help setting it up first time"

cd /home/ubuntu/git
git clone https://github.com/MG-RAST/MG-RAST-Tools.git
git clone https://github.com/MG-RAST/Shock.git
git clone https://github.com/MG-RAST/Shock.git
git clone https://github.com/wgerlach/USAGEPOD.git
cd /usr/share/perl5
sudo ln -s /home/ubuntu/git/Shock/libs/SHOCK/
sudo ln -s /home/ubuntu/git/AWE/utils/lib/AWE/
sudo ln -s /home/ubuntu/git/USAGEPOD/lib/USAGEPOD.pm
cd /usr/local/bin/
sudo ln -s /home/ubuntu/git/MG-RAST-Tools/tools/bin/mg-awe-submit.pl

cat >>/home/ubuntu/.profile<<EOF

export AWE_SERVER_URL=http://140.221.84.148:8000
export AWE_CLIENT_GROUP=am_compute
export SHOCK_SERVER_URL=http://shock.metagenomics.anl.gov:80
EOF

echo "Done installing MG-RAST-Tools"
echo "Try this command to check:"
echo "mg-awe-submit.pl --status"
####################################################################################