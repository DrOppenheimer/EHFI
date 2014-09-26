#!/bin/bash

set -e # checking of all commands 
set -x # print each command before execution

####################################################################################
### install dependencies for qiime_deploy and R # requires one manual interaction
####################################################################################
echo "Installing dependencies for qiime_deploy and R"
cd /home/ubuntu
sudo bash << EOSHELL_3
### for R install later add cran release specific repos to /etc/apt/sources.list
# echo deb http://cran.rstudio.com/bin/linux/ubuntu precise/ >> /etc/apt/sources.list # 12.04 # Only exist for LTS - check version with lsb_release -a
echo deb http://cran.rstudio.com/bin/linux/ubuntu trusty/ >> /etc/apt/sources.list  # 14.04 # Only exist for LTS - check version with lsb_release -a
### add cran public key # this makes it possible to install most current R below
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
### for qiime install later, uncomment the universe and multiverse repositories from /etc/apt/sources.list
sed -e '/verse$/s/^#\{1,\}//' /etc/apt/sources.list > /etc/apt/sources.list.edit; mv /etc/apt/sources.list.edit /etc/apt/sources.list
### update and upgrade
how apt-get -y install build-essential
apt-get -y update   
apt-get -y upgrade  # try without updade # try with --force-yes
apt-get clean 
### install required packages
apt-get -y --force-yes upgrade python-dev libncurses5-dev libssl-dev libzmq-dev libgsl0-dev openjdk-6-jdk libxml2 libxslt1.1 libxslt1-dev ant git subversion zlib1g-dev libpng12-dev libfreetype6-dev mpich2 libreadline-dev gfortran unzip libmysqlclient18 libmysqlclient-dev ghc sqlite3 libsqlite3-dev libc6-i386 libbz2-dev libx11-dev libcairo2-dev libcurl4-openssl-dev libglu1-mesa-dev freeglut3-dev mesa-common-dev xorg openbox emacs r-cran-rgl xorg-dev libxml2-dev mongodb-server bzr make gcc mercurial python-qcli
apt-get clean
EOSHELL_3
echo "DONE Installing dependencies for qiime_deploy and R"
# sudo dpkg --configure -a # if you run tin trouble
# /etc/apt/sources.list  redundancy
####################################################################################

####################################################################################
### Clone repos for qiime-deploy and AMETHST
####################################################################################
echo "Cloning the qiime-deploy and AMETHST git repos"
cd /home/ubuntu/
git clone git://github.com/qiime/qiime-deploy.git
git clone https://github.com/MG-RAST/AMETHST.git
git clone https://github.com/DrOppenheimer/Kevin_Installers.git
echo "DONE cloning the qiime-deploy and AMETHST git repos"
####################################################################################

####################################################################################
### INSTALL cdbtools (Took care of the cdb failure above)
####################################################################################
echo "Installing cdbtools"
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
echo "DONE installing cdbtools"
####################################################################################

####################################################################################
### INSTALL QIIME ### also see https://github.com/qiime/qiime-deploy 4-23-14
####################################################################################
## NOTE: Qiime isntallation frequently breaks, and you have to continue by hand 
## does not break in a consistent way
## This will also install cdbfasta & cdbyank, python and perl
## Uncomment the universe and multiverse repositories from /etc/apt/sources.list
echo "Installing Qiime"
#sudo bash << EOFSHELL4
cd /home/ubuntu/
sudo python ./qiime-deploy/qiime-deploy.py /home/ubuntu/qiime_software -f ./AMETHST/qiime_configuration/qiime.amethst.config --force-remove-failed-dirs --force-remove-previous-repos
apt-get -y clean
#EOFSHELL4
echo "DONE Installing Qiime"
####################################################################################

####################################################################################
### INSTALL most current R on Ubuntu 14.04, install multiple non-base packages
####################################################################################
echo "Installing R"
sudo bash << EOSHELL_5
apt-get -y build-dep r-base # install R dependencies (mostly for image production support)
apt-get -y install r-base   # install R
apt-get clean
# Install R packages, including matR, along with their dependencies
EOSHELL_5

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

echo "DONE installing R"
####################################################################################

####################################################################################
#### install perl packages
####################################################################################
echo "Installing perl packages"
sudo bash << EOSHELL_7
#curl -L http://cpanmin.us | perl - --sudo App::cpanminus
curl -L http://cpanmin.us | perl - --sudo Statistics::Descriptive
#cpan -f App::cpanminus # ? if this is first run of cpan, it will have to configure, can't figure out how to force yes for its questions
#                       # this may already be installed
#cpanm Statistics::Descriptive
EOSHELL_7
echo "DONE installing perl packages"
####################################################################################

####################################################################################
### Add AMETHST to Envrionment Path (permanently)
####################################################################################
echo "Adding AMETHST to the PATH"
sudo bash << EOSHELL_8
sudo bash 
echo "export \"PATH=$PATH:/home/ubuntu/AMETHST"\" >> /home/ubuntu/.profile
source /home/ubuntu/.profile
#exit
EOSHELL_8
source /home/ubuntu/.profile
echo "DONE adding AMETHST to the PATH (full PATH is in /home/ubuntu/.profile)"
# PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games" # original /etc/environment path
####################################################################################

####################################################################################
### Test AMETHST functionality
####################################################################################
echo "TESTING AMETHST FUNCTIONALITY"
source /home/ubuntu/.profile
test_amethst.sh
echo "DONE testing AMETHST functionality"
####################################################################################




