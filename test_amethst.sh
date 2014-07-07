#!/bin/bash                                                                                                                                              
# Simple script to test AMETHST, if this test complete's without errors, AMETHST is working                                                              
# move to the directory with AMEHST test data

# get path for AMETHST
START_DIR=`pwd`
WHICH_AMETHST=`which amethst.pl`
AMETHST_PATH=$(dirname ${WHICH_AMETHST})
TEST_DATA_PATH=$AMETHST_PATH"/datasets/test_analysis_data/"

echo "This is a simple test for AMETHST functionaility - if it complete's without errors, AMETHST is properly installed"

echo "Moving to:"
echo $TEST_DATA_PATH

cd $TEST_DATA_PATH

echo "running AMETHST test"
# run the test
AMETHST.pl -f test_analysis_commands -k -z

echo "running post test cleanup"
# perform post test cleanup
rm *log
rm -R AMETHST.Summar*
rm AMETHST.All_data.tar.gz
rm *list*

echo "moving back to:" 
echo $START_DIR"
cd $START_DIR

# print simple message
echo "If no errors were displayed, AMETHST is properly installed"
