#!/bin/bash
infile=$1
GROUPFILE="EHFI.groups"
if echo $infile  | grep DIST$ 
then
echo "DIST " $infile
else
echo File $infile does not match DIST
exit
fi

DIST=$infile
AVG_DIST=${DIST/DIST/DIST.AVG_DIST}
P_VALUES_SUMMARY=${DIST/DIST/P_VALUES_SUMMARY}
PCoA=${DIST/DIST/PCoA}

# example scripts to invoke plot_pco_with_stats and visualize the output
if [[ ! -e $DIST.png ]] && [[ -e $DIST ]]
then
 	echo plotting heatmap of original data
	echo plot-distance.py -i $DIST -o $DIST.png 
	     plot-distance.py -i $DIST -o $DIST.png 
else
 	echo skipping creating $DIST.png 
fi


if [[ ! -e $AVG_DIST.csv ]] && [[ -e $AVG_DIST ]]
then
echo parse-avgdistance.py  $AVG_DIST   $AVG_DIST.csv
     parse-avgdistance.py  $AVG_DIST > $AVG_DIST.csv
else
	echo skipping creating $AVG_DIST.csv
fi 

if [[ ! -e $AVG_DIST.csv.png ]] && [[ -e $AVG_DIST.csv ]]
then
echo plot-distance.py -i $AVG_DIST.csv
     plot-distance.py -i $AVG_DIST.csv
else 
echo skipping creating $AVG_DIST.csv.png
fi


if [[ ! -e $P_VALUES_SUMMARY.csv ]] && [[ -e  $P_VALUES_SUMMARY ]]
then
echo generating all-against-all p-value table in $P_VALUES_SUMMARY.csv 
echo parse-pvalues.py -i $P_VALUES_SUMMARY  
     parse-pvalues.py -i $P_VALUES_SUMMARY  > $P_VALUES_SUMMARY.csv
else
echo skipping creating $P_VALUES_SUMMARY.csv
fi


if [[ ! -e $P_VALUES_SUMMARY.csv.png ]] && [[ -e  $P_VALUES_SUMMARY.csv ]]
then
echo generating heatmap of p-values in $P_VALUES_SUMMARY.csv.png
echo plot-distance.py -i $P_VALUES_SUMMARY.csv
     plot-distance.py -i $P_VALUES_SUMMARY.csv
else
echo skipping creating $P_VALUES_SUMMARY.csv.png
fi

if [[ ! -e $PCoA.png ]] && [[ -e  $PCoA ]]
then
echo generating PCOA plot in $PCoA.png
echo parse-pcoa.py -i   $PCoA -g ${GROUPFILE}  -o $PCoA.png 
     parse-pcoa.py -i   $PCoA -g ${GROUPFILE}  -o $PCoA.png 
else
echo skipping creating $PCoA.png
fi

exit 

echo plotting one of the permutations
plot-distance.py -i $analysisdir/permutations/$infile.permutation.1 -o $analysisdir/$infile.permutation.1.png

mv $analysisdir $finalanalysisdir
mv $infile.plot_pco_with_stats.log $infile.$method.$type.plot_pco_with_stats.log
