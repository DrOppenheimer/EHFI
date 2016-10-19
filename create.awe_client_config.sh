#!/bin/bash

# work as super user
sudo bash <<EOF
 EOFSHELL
 
# delete the old config file if it is there
rm -f /home/ubuntu/awe_client_config

# create the new config file
# NOTE: This script assumes that all of the env variables it
# uses are defined by sourcing ~/.profile

source ~/.profile

cat >/home/ubuntu/awe_client_config<<EOF
EOF

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
_cliprint_app_msg=true
clientgroup_token=${AWE_CLIENT_GROUP_TOKEN}
pre_work_script=
# arguments for pre-workunit script execution should be comma-delimited
pre_work_script_args=
#for openstack client only
openstack_metadata_url=http://169.254.169.254/2009-04-04/meta-data
domain=default-domain #e.g. megallan
EOF

# create links to awe directories
cd /home/ubuntu
ln -snf ${AWE_DATA} awe_data
ln -snf ${AWE_WORK} awe_work
ln -snf ${AWE_LOGS} awe_logs

EOFSHELL
EOF
