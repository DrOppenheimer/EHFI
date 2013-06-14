#!/bin/bash
plot_pco_with_stats_all.3-4-13.pl -f o-0.0001 -g o.groups -m euclidean -t dataset_rand -z qiime_pipe -q qiime_table -o test_a   # -cleanup
plot_pco_with_stats_all.3-4-13.pl -f o-0.0001 -g o.groups -m euclidean -t rowwise_rand -z qiime_pipe -q qiime_table -o test_b   # -cleanup


