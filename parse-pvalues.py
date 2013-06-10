#!/usr/bin/env python

import sys, os
import numpy as np
from optparse import OptionParser
import re

if __name__ == '__main__':
    usage  = "usage: %prog -i <input sequence file> -o <output file>"
    parser = OptionParser(usage)
    parser.add_option("-i", "--input",  dest="infile", default=None, help="Input sequence file.")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default=True, help="Verbose [default off]")
    parser.add_option("-d", "--diagonal", dest="diagonal", action="store_true", default=False, help="Overwrite diagonal with 0.5")
    
    (opts, args) = parser.parse_args()
    infile = opts.infile
    if not opts.infile and args[0]: 
        infile = args[0]
    f = open(infile)   # parse column labels
  
    h =  {} 
    phyla = []
    table = []
    samplenames0 = f.readline().split("\t")  
    index = {}
    index[0] = ""
    #del(samplenames0[0])
    #print infile
    NUMGROUPS = 0
    sizeofgroups = {}
    pvalindex = 3
    for l in f:  
        l = l.rstrip()
        c = l.split("\t")
        if l[0] != "#" :
            b = re.search("mean_Group\((\d*)\).*group_members=c\((.*)" , l)
            try: 
                NUMBINS = 0
                if(len(b.groups()) > 0):
                    firstgroup = b.groups()[1].split(",")[0]
                    if firstgroup[0] == "\"":  
                        firstgroup = firstgroup[1:]
                    if firstgroup[-1] == "\"":  
                        firstgroup = firstgroup[:-1]
                    index[int(b.groups()[0] )-1] = firstgroup+"..."
                    NUMBINS += len(b.groups()[1].split(",")) 
                    NUMGROUPS += 1
                sizeofgroups[b.groups()[0]] = NUMBINS
            except AttributeError:
                pass
            a = re.search("Group\((\d*)\)::Group\((\d*)\)", c[0])
            if  a != None and len(a.groups()) == 2 :
                pval = c[pvalindex]
                a1 = int(a.groups()[0]) -1
                a2 = int(a.groups()[1]) -1
      #          print pval 
                h[(int(a1), int(a2))] = pval 
                h[(int(a2), int(a1))] = pval
            a = re.search("->mean_Group\((\d*)\)", c[0])
            if  a != None and len(a.groups()) == 1 :
                pval = c[pvalindex]
                a1 = int(a.groups()[0]) -1
      #         print pval 
                h[(int(a1), int(a1))] = pval 
      
        else:
            if c[0] == "# dist description":  # determine which format output is in
                if c[3] == "og_dist_P" : 
                    pvalindex = 3
                if c[4] == "og_dist_P" : 
                    pvalindex = 4
    NUMBINS = 0
    for i in sizeofgroups.keys():
        NUMBINS += sizeofgroups[i]
    if opts.diagonal: 
        for i in range(0, NUMBINS):
            h[(i, i)] = 0.5 
    grouplabels = [str(i+1) for i in range(0, NUMGROUPS) ]
    grouplabels = [index[i] for i in range(0, NUMGROUPS) ]
    print "#Pvalues\t", "\t".join(grouplabels)
    for i in range(0, NUMGROUPS):
        print grouplabels[i]+"\t"+"\t".join( "%.05f"%(1-m) for m in (map(float, (h[(i, j)] for j in range(NUMGROUPS) ))))
