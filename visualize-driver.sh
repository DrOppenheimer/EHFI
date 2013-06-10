#!/bin/bash
find -maxdepth 2 -name '*.DIST' | head | xargs -n 1 -P 8 visualize.sh 
