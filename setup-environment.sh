#!/bin/bash

# script to prepare dependencies for EHFI tools on a blank EC2 node

sudo apt-get update
sudo apt-get install -y git 
git clone https://github.com/DrOppenheimer/EHFI

sudo apt-get install -y r-base-core python-matplotlib libstatistics-descriptive-perl python-numpy python-scipy

echo 'install.packages("matlab", repos="http://cran.case.edu/")' | sudo R --vanilla 
echo 'install.packages("ecodist", repos="http://cran.case.edu/")' | sudo R --vanilla 
echo 'export PATH=$PATH:$HOME/EHFI' >> ~/.bash_profile

git clone git://github.com/qiime/qiime-deploy.git
git clone git://github.com/qiime/qiime-deploy-conf.git
cd qiime-deploy/
sudo apt-get --force-yes -y install python-dev libncurses5-dev libssl-dev libzmq-dev l
ibgsl0-dev openjdk-6-jdk libxml2 libxslt1.1 libxslt1-dev ant git subversion build-essential zl
ib1g-dev libpng12-dev libfreetype6-dev mpich2 libreadline-dev gfortran unzip libmysqlclient18 
libmysqlclient-dev ghc

python qiime-deploy.py $HOME/qiime_software/ -f $HOME/qiime-deploy-conf/qiime-1.6.0/qiime.conf --force-remove-failed-dirs

echo 'PATH=$PATH:$HOME/EHFI' >> $HOME/.bashrc

source $HOME/.bashrc

# QIIME overloads the system R... 
echo 'install.packages("ecodist", repos="http://cran.case.edu/")' | sudo /home/ubuntu/qiime_software/r-2.12.0-release/bin/R  --vanilla
echo 'install.packages("matlab", repos="http://cran.case.edu/")' | sudo /home/ubuntu/qiime_software/r-2.12.0-release/bin/R  --vanilla
