#!/bin/bash

# script to prepare dependencies for EHFI tools on a blank EC2 node

sudo apt-get update
sudo apt-get install -y git r-base-core python-matplotlib libstatistics-descriptive-perl python-numpy python-scipy

echo 'install.packages("matlab", repos="http://cran.case.edu/")' | sudo R --vanilla 
echo 'install.packages("ecodist", repos="http://cran.case.edu/")' | sudo R --vanilla 

git clone https://github.com/Droppenheimer/EHFI
echo 'export PATH=$PATH:$HOME/EHFI' >> ~/.bash_profile

export PATH=$PATH:$HOME/EHFI
