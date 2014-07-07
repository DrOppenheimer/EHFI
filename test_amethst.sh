#!/bin/bash                                                                                                                                              
# Simple script to test AMETHST, if this test complete's without errors, AMETHST is working                                                              
# move to the directory with AMEHST test data
cd ./datasets/test_analysis_data

# run the test
AMETHST.pl -f test_analysis_commands -k -z

# perform post test cleanup
rm *log
rm -R AMETHST.Summar*
rm AMETHST.All_data.tar.gz
rm *list*

# print simple message
echo "If no errors were displayed, AMETHST is properly installed"
