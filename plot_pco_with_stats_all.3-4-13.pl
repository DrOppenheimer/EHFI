#!/usr/bin/env perl

# Adapted from 11-21-12 version, for use with master that can call
# plot_pco_with_stats,
# plot_qiime_pco_with_stats, or
# plot_OTU_pco_with_stats

#use strict;
use warnings;
use Getopt::Long;
use Cwd;

my $start = time;

my($data_file, $cleanup, $help, $verbose, $debug, $output_dir, $output_PCoA_dir, $output_DIST_dir, $output_avg_DISTs_dir, $perm_dir);

my $current_dir = getcwd()."/";
#if($debug) { print STDOUT "current_dir: "."\t".$current_dir."\n";}

#define defaults for variables that need them
my $groups_list = "groups_list";
my $input_dir = $current_dir;
my $print_dist = 1;
my $dist_list = "DISTs_list";
my $dist_method = "bray-curtis";  
my $avg_dists_list = "AVG_DISTs_list";
my $headers = 1; 
my $perm_list = "permutation_list" ;
my $perm_type = "sample_rand";
my $num_perm = 10;
my $num_cpus = 10;
my $time_stamp =`date +%m-%d-%y_%H:%M:%S`;  # create the time stamp month-day-year_hour:min:sec:nanosec
chomp $time_stamp;
# date +%m-%d-%y_%H:%M:%S:%N month-day-year_hour:min:sec:nanosec

# check input args and display usage if not suitable
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

unless ( @ARGV > 0 || $data_file ) { &usage(); }

if ( ! GetOptions (
		   "data_file=s"       => \$data_file,
		   "groups_list=s"     => \$groups_list,
		   "input_dir=s"       => \$input_dir,
		   "output_dir=s",     => \$output_dir,
		   "output_PCoA_dir=s" => \$output_PCoA_dir,
		   "print_dist=i"      => \$print_dist,
		   "output_DIST_dir"   => \$output_DIST_dir,
		   "dist_method=s"     => \$dist_method,
		   "headers=i"         => \$headers,
		   "perm_dir"          => \$perm_dir,
		   "perm_type=s"       => \$perm_type,
		   "num_perm=i"        => \$num_perm,
		   "num_cpus=i"        => \$num_cpus,
		   "cleanup!"          => \$cleanup,
		   "help!"             => \$help, 
		   "verbose!"          => \$verbose,
		   "debug!"            => \$debug
		  )
   ) { &usage(); }

unless ($output_dir){ # allow user to select output dir
  $output_dir = $current_dir."plot_pco_with_stats.".$data_file.".".$dist_method.".RESULTS/";
}else{
  $output_dir = $output_dir."/"."plot_pco_with_stats.".$data_file.".".$dist_method.".RESULTS/";
}

$output_PCoA_dir =      $output_dir."PCoAs/";
$output_DIST_dir =      $output_dir."DISTs/";
$output_avg_DISTs_dir = $output_dir."AVG_DISTs/";
$perm_dir =             $output_dir."permutations/";

# name P value summary output file
my $output_p_value_summary = $output_dir.$data_file.".".$dist_method.".P_VALUES_SUMMARY";

# create directories for the output files
unless (-d $output_dir) { mkdir $output_dir; }
unless (-d $perm_dir) { mkdir $perm_dir; }
unless (-d $output_PCoA_dir) { mkdir $output_PCoA_dir; }
unless (-d $output_DIST_dir) { mkdir $output_DIST_dir; }
unless (-d $output_avg_DISTs_dir) { mkdir $output_avg_DISTs_dir;}

# create a log file
#my $log_file = $data_file.".plot_pco_with_stats.log";
my $log_file = $output_dir."/".$data_file.".plot_pco_with_stats.log"; # place log in the output dir
open(LOG, ">", $log_file) or die "cannot open LOG $log_file";
print LOG "start: "."\t"."\t".$time_stamp."\n";

&running();

##### Make sure that the input files don't have nutty line terminators (creep in when you use excel to modify the files)
&correct_line_terminators($input_dir, $data_file);
&correct_line_terminators($input_dir, $groups_list);


##### Make sure that the groups_list only contains headers that exist in the data file -- kill the program as soon as they don't
$check_status = check_groups($input_dir, $data_file, $groups_list);
unless ($check_status eq "All groups members match a header from the data file"){
  print LOG "DATA_FILE  : ".$input_dir.$data_file."\n";
  print LOG "GROUPS_LIST: ".$input_dir.$groups_list."\n";
  print LOG $check_status."JOB KILLED";
  print STDOUT "DATA_FILE  : ".$input_dir.$data_file."\n";
  print STDOUT "GROUPS_LIST: ".$input_dir.$groups_list."\n";
  print STDOUT $check_status."JOB KILLED"."\n";
  exit 1;
}else{
  print LOG "DATA_FILE  : ".$input_dir.$data_file."\n";
  print LOG "GROUPS_LIST: ".$input_dir.$groups_list."\n";
  print LOG $check_status.", proceeding"."\n\n";
  print STDOUT "DATA_FILE  : ".$input_dir.$data_file."\n";
  print STDOUT "GROUPS_LIST: ".$input_dir.$groups_list."\n";
  print STDOUT "\n\n".$check_status.", proceeding"."\n\n";
}





##### PROCESS ORIGNAL DATA #####

# process the original data_file to produce PCoA and DIST files
print LOG "process original data file (".$data_file.") > *.PCoA & *.DIST ... "."\n";
# my $output_og_pco = $data_file.".".$dist_method.".OG.PCoA";
print LOG "system(plot_pco_shell.sh ".$data_file." ".$input_dir." ".$output_dir." ".1." ".$output_dir." ".$dist_method $headers.")\n";
system("plot_pco_shell.sh $data_file $input_dir $output_dir 1 $output_dir $dist_method $headers");
print LOG "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

# Process original data_file.DIST to produce original_file.DIST.AVG_DIST
print LOG "process original data *.DIST file (".$data_file.".".$dist_method.".DIST) > *.AVG_DIST ... "."\n";
print LOG "system(avg_distances.sh ".$data_file." ".$dist_method."DIST ".$output_dir." ".$groups_list." ".$data_file.$dist_method."DIST ".$output_dir.")\n";
system("avg_distances.sh $data_file.$dist_method.DIST $output_dir $groups_list $data_file.$dist_method.DIST $output_dir");
print LOG "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

# use R script sample_matrix.r to generate permutations of the original data
print LOG "generate (".$num_perm.") permutations ... "."\n";
my $R_rand_script = "$data_file.R_sample_script.".$time_stamp.".r";
open(R_SCRIPT, ">", $R_rand_script) or die "cannot open R_SCRIPT $R_rand_script";

exit("\n\n"."stopped"."\n\n";);

##### CREATE AND PROCESS PERMUTED DATA



#create R script to generate permutations - permutations are placed in a permutations directory
print R_SCRIPT (
		"# script generated by plot_pco_with_stats.pl to run sample_matrix.r"."\n".
		"source(\"~/bin/sample_matrix.9-18-12.r\")"."\n".
		"sample_matrix(file_name = \"$data_file\", file_dir = \"$input_dir\", num_perm = $num_perm, perm_type = \"$perm_type\", write_files = 1, perm_dir = \"$perm_dir\", verbose = 0, debug = 0)"
	       );

# generate permutations with R script created above
system( "R --vanilla --slave < $R_rand_script" );
print LOG "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
system( "rm $R_rand_script" );

# create list of the permutation files
print LOG "creating list of permutated data files ... "."\n";
&list_dir($perm_dir, "permutation",  $output_dir.$perm_list);
print LOG "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

# perform PCoA on all of the permutations - outputs placed in directories created for the PCoA and DIST files
print LOG "process permutations > *.PCoA & *.DIST ... "."\n";
if($debug){ 
  system( "cat $output_dir$perm_list | xargs -t -n1 -P$num_cpus -I{} plot_pco_shell.sh {} $perm_dir $output_PCoA_dir 1 $output_DIST_dir $dist_method $headers" );
}else{
  system( "cat $output_dir$perm_list | xargs -n1 -P$num_cpus -I{} plot_pco_shell.sh {} $perm_dir $output_PCoA_dir 1 $output_DIST_dir $dist_method $headers" );
}
print LOG "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

#Create list of all permutation *.DIST files
print LOG "creating list of *.DIST files produced from permutated data ... "."\n"; 
&list_dir($output_DIST_dir, ".DIST",  $output_dir.$dist_list);
print LOG "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

#if($debug){print "\n\nHERE (1)\n\n";}

# Create files that contain the averages of all within and between group distances
print LOG "process permutation *.DIST > *.AVG_DIST ... "."\n";
if($debug){
  system ( "cat  $output_dir$dist_list | xargs -t -n1 -P$num_cpus -I{} avg_distances.sh {} $output_DIST_dir $groups_list {} $output_avg_DISTs_dir" );
}else{
  system ( "cat  $output_dir$dist_list | xargs -n1 -P$num_cpus -I{} avg_distances.sh {} $output_DIST_dir $groups_list {} $output_avg_DISTs_dir" );
}
print LOG "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

#if($debug){print "\n\nHERE (2)\n\n";}

#Create a list of all the *.AVG_DIST files
print LOG "creating list of *.AVG_DIST files ... "."\n"; 
&list_dir($output_avg_DISTs_dir, "AVG_DIST",  $output_dir.$avg_dists_list);
print LOG "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

# Run the final script to calculate P values by comparing the original to all permutaion derived distances matrixes
print LOG "processing all *.AVG_DIST to produce P values ... "."\n";
system( "perl ~/bin/avg_dist_summary.8-24-12.pl -og_avg_dist_file  $output_dir$data_file.$dist_method.DIST.AVG_DIST -avg_dists_dir $output_avg_DISTs_dir -avg_dists_list  $output_dir$avg_dists_list -output_file $output_p_value_summary" );
print LOG "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
                                                                                                                        
# perform cleanup if specified
if ($cleanup) {
  &cleanup_sub();
}

my $end = time;
my $min = int(($end - $start) / 60);
my $sec = ($end - $start) % 60;

print STDOUT "all DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
print STDOUT "ELAPSED TIME: "."(".$min.")"."minutes "."(".$sec.")"."seconds"."\n";
print LOG "all DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
print LOG "ELAPSED TIME: "."(".$min.")"."minutes "."(".$sec.")"."seconds"."\n";




############### SUBS ###############



# removed permutation files     
sub cleanup_sub { 
   print LOG "cleanup ... "."\n";
  system("rm $output_dir*_list; rm -R $output_PCoA_dir; rm -R $output_DIST_dir; rm -R $output_avg_DISTs_dir; rm -R $perm_dir");
  print LOG "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
}




sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
time stamp:           $time_stamp
script:               $0

DESCRIPTION:
This script performs pco analysis with group distances on an original data file, 
and a specified number of permutations of the original data to derive p values
   
USAGE:
    --data_file        (string)  no default
                                    original data file (in R compatible tab delimited format)
    --input_dir        (string)  default = $current_dir
                                    path that containts the data file
    --groups_list      (string)  default = $groups_list
                                    file that contains groups list
                                    group per line, each sample in a group (line) is comma separated
                                    sample names should be same as in the data_file header
    --num_perm         (integer) default = $num_perm 
                                    number of permutations to perform
    --perm_type        (string)  default = $perm_type 
                                    --> choose from the following three methods <--
                                         sample_rand   - randomize fields in sample/column
                                         dataset_rand  - randomize fields across dataset
                                         complete_rand - randomize every individual count across dataset
    --dist_method      (string)  default = $dist_method
                                    --> can slect from the following distances/dissimilarities <-- 
                                         bray-curtis | maximum  | canberra    | binary   | minkowski  | 
                                         euclidean   | jacccard | mahalanobis | sorensen | difference |
                                         manhattan
    --perm_dir         (string)  default = /results/permutations
                                    directory to store permutations
    --num_cpus         (integer) default = $num_cpus
                                    number of cpus to use (xargs)
    -----------------------------------------------------------------------------------------------
    --cleanup          (flag)       delete all of the permutation temp files
    --help             (flag)       see the help/usage
    --verbose          (flag)       run in verbose mode
    --debug            (flag)       run in debug mode

);
  exit 1;
}




sub running {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT qq(
RUNNING
------------------------------------------
script:               $0
time stamp:           $time_stamp
------------------------------------------
);
print LOG qq(
RUNNING
------------------------------------------
script:               $0
time stamp:           $time_stamp
------------------------------------------

);
}



sub list_dir {
  
  my($dir_name, $list_pattern, $dir_list) = @_;
  
  open(DIR_LIST, ">", $dir_list) or die "\n\n"."can't open DIR_LIST $dir_list"."\n\n";
  opendir(DIR, $dir_name) or die "\n\n"."can't open DIR $dir_name"."\n\n";
  
  my @dir_files_list = grep /$list_pattern/, readdir DIR; 
  print DIR_LIST join("\n", @dir_files_list); print DIR_LIST "\n";
  closedir DIR;
  
}





sub correct_line_terminators {
  
  my($input_dir, $file) = @_;
  
  my $temp_file = $file.".tmp";
  
  open(FILE, "<", $input_dir."/".$file) or die "Couldn't open FILE $file"."\n";
  open(TEMP_FILE, ">", $input_dir."/".$temp_file) or die "Couldn't open TEMP_FILE $temp_file"."\n";
  
  while (my $line = <FILE>){          
    $line =~ s/\r\n|\n\r|\n|\r/\n/g;  #get rid of the line ends that are there #replace them with \n
    print TEMP_FILE $line; 
  }
  
  unlink $input_dir."/".$file or die "\n"."Couldn't delete FILE $file"."\n";
  rename $input_dir."/".$temp_file, $input_dir."/".$file or die "\n"."Couldn't rename TEMP_FILE $temp_file to FILE $file"."\n";
  
}








sub check_groups { # script hashes the headers from the data file and checks to see that all headers in groups have a match in the data file

  my($input_dir, $data_file, $groups_list) = @_;

  my $check_status = "All groups members match a header from the data file"; # variable to carry results of the check back to main
  my $header_hash; # declare hash for the individual headers
  
  open(DATA_FILE, "<", $input_dir."/".$data_file) or die "\n\n"."can't open DATA_FILE $data_file"."\n\n";
  
  my $header_line = <DATA_FILE>; # get the line with the column headers from the data file
  chomp $header_line;
  if($debug){ print STDOUT "HEADER_LINE: ".$header_line."\n" }
  my @header_array = split("\t", $header_line); # place headers in an array
  shift @header_array; # shift off the first entry -- should be empty (MG-RAST) or a non essential index description (Qiime)
  
  
  if($debug){ my $num_headers = 0; }
  foreach (@header_array){ # iterate through the array of headers and place them in a hash
    $header_hash->{$_} = 1;
    if($debug){ $num_headers++; print STDOUT "Data Header(".$num_headers."): ".$_."\n"; }
  }
  
  open(GROUPS_FILE, "<", $input_dir."/".$groups_list) or die "\n\n"."can't open GROUPS_LIST $groups_list"."\n\n"; 
  while (my $groups_line = <GROUPS_FILE>){
    chomp $groups_line;
    my @line_array = split(",", $groups_line);
    foreach (@line_array){
      unless ( $header_hash->{$_} ){
	$check_status = "\n"."FAIL - "."groups id: ".$_." does not exist in the data file: ";
      }
    }

  }

  return $check_status;

}
