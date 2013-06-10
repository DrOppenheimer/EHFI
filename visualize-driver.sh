#!/bin/bash
find -maxdepth 2 -name '*.DIST' | xargs -n 1 -P 8 ../visualize.sh 
