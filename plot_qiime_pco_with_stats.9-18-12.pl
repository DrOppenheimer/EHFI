#!/usr/bin/env perl
#based on the 3-15-12 version (not 4-25-12)

# Adapted from 5-9-12 version, for use with master that can call
# plot_pco_with_stats,
# plot_qiime_pco_with_stats, or
# plot_OTU_pco_with_stats


#use strict;
use warnings;
use Getopt::Long;
use Cwd;


my $start = time;

my($data_file, $cleanup, $help, $verbose, $debug, $output_dir, $output_PCoA_dir, $output_DIST_dir, $output_avg_DISTs_dir, $perm_dir);

my $dist_method = "unifrac";

my $current_dir = getcwd()."/";
#####################################
my $groups_list = "groups_list";

my $input_dir =            $current_dir;
my $print_dist = 1;

my $perm_type = "sample_rand";
my $num_perm = 10;
my $num_cpus = 10;

my $time_stamp =`date +%m-%d-%y_%H:%M:%S`;  # create the time stamp month-day-year_hour:min:sec:nanosec
chomp $time_stamp;
# date +%m-%d-%y_%H:%M:%S:%N month-day-year_hour:min:sec:nanosec



# check input args and display usage if not suitable
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

unless ( @ARGV > 0 || $data_file || $tree ) { &usage(); }

if ( ! GetOptions (
		   "data_file=s"                => \$data_file,
		   "groups_list=s"              => \$groups_list,
		   "input_dir=s"                => \$input_dir,		   
		   "dist_method=s"              => \$dist_method,
		   "tree=s"                     => \$tree,
		   "print_dist=i"               => \$print_dist,
		   "num_cpus=i"                 => \$num_cpus,		   
		   "num_perm=i"                 => \$num_perm,
		   "perm_type=s"                => \$perm_type,		   
		   "cleanup!"                   => \$cleanup,
		   "help!"                      => \$help, 
		   "verbose!"                   => \$verbose,
		   "debug!"                     => \$debug,		   
		  )
   ) { &usage(); }

### Create directory for output
$output_dir = $current_dir."plot_QIIME_pco_with_stats.".$data_file.".".$dist_method.".RESULTS/";
$output_PCoA_dir =      $output_dir."PCoAs/";
$output_DIST_dir =      $output_dir."DISTs/";
$output_avg_DISTs_dir = $output_dir."AVG_DISTs/";
$perm_dir =             $output_dir."permutations/";

# create directories for the output files
unless (-d $output_dir) { mkdir $output_dir; }
unless (-d $perm_dir) { mkdir $perm_dir; }
unless (-d $output_PCoA_dir) { mkdir $output_PCoA_dir; }
unless (-d $output_DIST_dir) { mkdir $output_DIST_dir; }
unless (-d $output_avg_DISTs_dir) { mkdir $output_avg_DISTs_dir;}

##################################################
##################################################
###################### MAIN ######################
##################################################
##################################################

if ( $dist_method =~ m/frac/ ){ # exit if phylogentic analysis is selected without a valid tree
  unless (-f "$tree") {
    print STDOUT "
          You selected a phylogenetic analysis (like unifrac or weighted_unifrac),
     but you did not specify a valid -tree argument; a value was not provided, 
     the specified tree file (*.tre) does not exist, or is an empty file.

          The tree you specified was:

          $tree \n\n";
    exit 1;
  }
}

# create a log file
my $log_file = $output_dir."job.log";
open(LOG, ">", $log_file) or die "cannot open LOG $log_file";
print LOG "start: "."\t"."\t".$time_stamp."\n";

&running();

##### Make sure that the input files don't have nutty line terminators (creep in when you use excel to modify the files)
&correct_line_terminators($input_dir, $data_file);
&correct_line_terminators($input_dir, $groups_list);
if($tree){&correct_line_terminators($input_dir, $tree);}

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


# name P value summary output file
#my $pvalue_summary = $data_file.".PCoA."."P_values";
my $pvalue_summary = $data_file.".".$dist_method.".PCoA."."P_values";

# create directories for the output files
#unless (-d $permutations_data_dir) { mkdir $permutations_data_dir; }

##########################################
########## PROCESS ORIGNAL DATA ##########
##########################################

if($debug){print "Got here >1<"."\n";}

##### Make sure that input file uses conventional unix line terminators
my $temp_filename = $data_file.".tmp";
open(DATA_FILE, "<", $input_dir.$data_file) or die "Couldn't open DATA_FILE $data_file"."\n";
open(TEMP_FILE, ">", $input_dir.$temp_filename) or die "Couldn't open TEMP_FILE $temp_filename"."\n";

while (my $line = <DATA_FILE>){          
  $line =~ s/\r\n|\n\r|\n|\r/\n/g;  #get rid of the line ends that are there
  print TEMP_FILE $line; #replace them with \n
}

close(DATA_FILE);
close(TEMP_FILE);
system("rm $input_dir$data_file; mv $input_dir$temp_filename $input_dir$data_file");



if($debug){print "Got here >2<"."\n";}

##### convert qiime formatted abundance table (0 based index on left, tax string on right, first non # row = headers) to biom format
my $biom_file = $data_file.".biom";
system("convert_biom.py -i $input_dir$data_file -o $output_dir$biom_file --biom_table_type=\"otu table\"");
#print LOG "convert data_file to biom format"."\n".
print STDERR "convert data_file to biom format"."\n".
  "( ".$data_file." > ".$data_file.".biom )"."\n".
  "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
if($debug){print "Got here >3<"."\n";}

##### produce a distance matrix (*.DIST) using qiime - *.tre needed for phylogenetically aware metrics (i.e. unifracs)
print STDERR "produce distance matrix with qiime:"."\n".
  "( ".$data_file.".biom > ".$output_dir."distance-metric_".$data_file.".biom )"."\n";

if ( $dist_method =~ m/frac/) { # add the tree argument to beta_diversity.py for unifrac (phylogenetically aware) analyses
  system("beta_diversity.py -i $output_dir$biom_file -o $output_dir -m $dist_method -t $tree");
  print STDERR "qiime-based distance analysis:"."\n".
    "( beta_diversity.py -i $output_dir$biom_file -o $output_dir -m $dist_method -t $tree )"."\n".
      "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
  
}else{
  system("beta_diversity.py -i $output_dir$biom_file -o $output_dir -m $dist_method");
  print STDERR "qiime-based distance analysis:"."\n".
    "( beta_diversity.py -i $output_dir$biom_file -o $output_dir -m $dist_method )"."\n".
      "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
  
}
if($debug){print "Got here >4<"."\n";}
my $qimme_dist_filename = $output_dir.$dist_method."_".$data_file.".txt";
my $dist_filename = $output_dir.$dist_method."_".$data_file.".DIST";
system("mv $qimme_dist_filename $dist_filename");


# use R to produce a PCoA from the distance matrix
my $pcoa_file = $output_dir.$dist_method."_".$data_file.".PCoA";
system("plot_qiime_pco_shell.sh $dist_filename $pcoa_file");
print STDERR "produce PCoA from qiime distance:"."\n".
  "( plot_qiime_pco_shell.sh $dist_filename $pcoa_file )"."\n".
  "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n"; 

if($debug){print "Got here >5<"."\n";}

# create AVG_DIST file for the original data
$dist_filename = $dist_method."_".$data_file.".DIST";
my $avg_dist_filename = $dist_method."_".$data_file;
system("avg_distances.sh $dist_filename $output_dir $groups_list $avg_dist_filename $output_dir");
print STDERR "Produce *.AVG_DIST file from the original data *.DIST file"."\n"."DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

if($debug){print "Got here >6<"."\n";}

######################################################
########## GENRATE AND PROCESS PERMUTATIONS ##########
######################################################
##########  DERIVE PERMUTATION BASED STATS  ##########
######################################################

# Create a version of the QIIME table in R friendly format
######      my $R_data_file = $data_file.".R_formatted";
#&format_table_qiime_2_R($data_file, $R_data_file);
system("qiime_2_R.pl -i $input_dir$data_file -o $input_dir$data_file -c 3");
print STDERR "create R-formatted version of qiime abundance table:"."\n".
  "( qiime_2_R.pl -i $input_dir$data_file -o $input_dir$data_file -c 3 )"."\n".
  "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

if($debug){print "Got here >7<"."\n";}

# use R script sample_matrix.r to generate permutations of the original data
my $R_rand_script = "R_sample_matrix_script.".$time_stamp.".r"; # create R script to generate permutations

my $R_data_file = $data_file.".qiime_ID_and_tax_string.R_table";
if ($debug){print "R_data_file: $R_data_file"."\n";}

open(R_SCRIPT, ">", $R_rand_script) or die "cannot open R_SCRIPT $R_rand_script";

print R_SCRIPT (
		"# script generated by plot_qiime_pco_with_stats.pl to run sample_matrix.r"."\n".
		"source(\"~/bin/sample_matrix.9-18-12.r\")"."\n".
		"sample_matrix(file_name = \"$R_data_file\", file_dir = \"$input_dir\", num_perm = $num_perm, perm_type = \"$perm_type\", write_files = 1, perm_dir = \"$perm_dir\", verbose = 0, debug = 1)"
	       );
if($debug){print "Got here >8<"."\n";}

system( "R --vanilla --slave < $R_rand_script" ); # run the script
system( "rm $R_rand_script" );
print STDERR "generated (".$num_perm.") permutations in $perm_dir "."\n".
  "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

if($debug){print "Got here >9<"."\n";}

# generate qiime formatted versions of the permuted data tables # could use xargs here too
my @R_permutation_list = &list_dir($perm_dir, "R_table");
foreach my $R_permutation (@R_permutation_list){
  if ($debug) {print "\n"."perm_dir: ".$perm_dir."\n"."R_permutation: ".$R_permutation."\n";}
  if ($debug) {print "qiime_2_R.pl -i $perm_dir$R_permutation -c 5"."\n"."\n";}
  system("qiime_2_R.pl -i $perm_dir$R_permutation -c 5");
  if($cleanup){system("rm $perm_dir$R_permutation");}
}
print STDERR "Generated *.Qiime_table files from *.R_table files in $perm_dir"."\n".
  #"( qiime_2_R.pl -i $permutations_data_dir.$R_permutation -c 5 )"."\n".
  "deleted *.R_table"."\n".
  "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

# generate biom format files from each qiime_formattted table # could use xargs here too
my @Qiime_permutation_list = &list_dir($perm_dir, "Qiime_table\$");
foreach my $Qiime_permutation (@Qiime_permutation_list){
  my $biom_permutation = $Qiime_permutation.".biom";
  system("convert_biom.py -i $perm_dir$Qiime_permutation -o $perm_dir$biom_permutation --biom_table_type=\"otu table\"");
  if($cleanup){system("rm $perm_dir$Qiime_permutation");}
}
print STDERR "Generated biom tables from Qiime_formatted tables in $perm_dir"."\n".
  "deleted *.Qiime_table"."\n".
    "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";


# produce *.DIST files for each permutation - using qiime beta_diversity.py
my @biom_permutation_list = &list_dir($perm_dir, ".biom\$");
my $biom_file_list = "$perm_dir"."biom_file_list";
open(BIOM_FILE_LIST, ">", $biom_file_list);
print BIOM_FILE_LIST join("\n", @biom_permutation_list);
close(BIOM_FILE_LIST);

if ( $dist_method =~ m/frac/ ) { # add the tree argument to beta_diversity.py for unifrac (phylogenetically aware) analyses
  system( "cat $biom_file_list | xargs  -n1 -P $num_cpus -I{} beta_diversity.py -i '$perm_dir'{} -o $output_DIST_dir -m $dist_method -t $tree" );
}else{
  if($debug) { print STDOUT "cat $biom_file_list | xargs  -n1 -P $num_cpus -I{} beta_diversity.py -i '$perm_dir'{} -o $output_DIST_dir -m $dist_method"."\n"; }
  system( "cat $biom_file_list | xargs  -n1 -P $num_cpus -I{} beta_diversity.py -i '$perm_dir'{} -o $output_DIST_dir -m $dist_method" );
}
print STDERR "produced *.DIST (distance matrixes) for each of (".$num_perm.") permutations in $perm_dir"."\n".
  "Note that they have a *.txt extension, not *.DIST"."\n".
  "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";


# produce *.AVG_DIST file for each *.DIST file
#unless (-d $output_avg_DISTs_dir) { mkdir $output_avg_DISTs_dir; }
#my @dist_permutation_list = &list_dir($perm_dir, ".txt");
my @dist_permutation_list = &list_dir($output_DIST_dir, ".txt");
my $dist_file_list = $output_DIST_dir."dist_file_list";
open(DIST_FILE_LIST, ">", $dist_file_list);
print DIST_FILE_LIST join("\n", @dist_permutation_list);
close(DIST_FILE_LIST);
system ( "cat $dist_file_list | xargs -n1 -P $num_cpus -I{} avg_distances.sh {} $output_DIST_dir $groups_list {} $output_avg_DISTs_dir" );
print STDERR "produced *.AVG_DIST (distance matrixes) for each of (".$num_perm.") permutations in $output_DIST_dir"."\n".
  "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

# use R to produce PCoAs for each permutation -- this code was never implemented/ is not complete
#
# you won't be able to just uncomment it and have it work
# my $pcoa_file = $output_dir.$dist_method."_".$data_file.".PCoA";
# system("plot_qiime_pco_shell.sh $dist_filename $pcoa_file");
# print STDERR "produce PCoA from qiime distance:"."\n".
#   "( plot_qiime_pco_shell.sh $dist_filename $pcoa_file )"."\n".
#   "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n"; 

# generate AVG_DISTs_list
my @AVG_DISTs_list = &list_dir($output_avg_DISTs_dir, ".AVG_DIST\$");
my $avg_dists_list = $output_avg_DISTs_dir."AVG_DISTs_list";
open(AVG_DISTS_LIST, ">", $avg_dists_list);
print AVG_DISTS_LIST join("\n", @AVG_DISTs_list);
close(AVG_DISTS_LIST);


# Run the final script to calculate P values by comparing the original to all permutaion derived distances matrixes
#my $output_p_value_summary = $output_dir.$dist_method."_".$data_file.".P_VALUES_SUMMARY";  ####### HERE HERE HERE
my $output_p_value_summary = $output_dir.$data_file.".".$dist_method.".P_VALUES_SUMMARY";
my $og_avg_dist_filename = $output_dir.$avg_dist_filename.".AVG_DIST";
system( "avg_dist_summary.8-24-12.pl -og_avg_dist_file $og_avg_dist_filename -avg_dists_dir $output_avg_DISTs_dir -avg_dists_list $avg_dists_list -output_file $output_p_value_summary" );
print STDERR "produced final summary:"."\n".$output_dir.$data_file.".P_VALUES_SUMMARY"."\n".
  "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";


# Perform cleanup if requested
if ($cleanup){
  #system("rm -R PERMs");
  #system("rm -R PERM_DISTs");
  #system("rm -R AVG_DISTs");
  system("rm $output_dir*_list; rm -R $output_PCoA_dir; rm -R $output_DIST_dir; rm -R $output_avg_DISTs_dir; rm -R $perm_dir");
}


# print total runtime in the log
my $end = time;
my $min = int(($end - $start) / 60);
my $sec = ($end - $start) % 60;

print STDOUT "all DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
print STDOUT "ELAPSED TIME: "."(".$min.")"."minutes "."(".$sec.")"."seconds"."\n";
print LOG "all DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
print LOG "ELAPSED TIME: "."(".$min.")"."minutes "."(".$sec.")"."seconds"."\n";



##################################################
##################################################
###################### SUBS ######################
##################################################
##################################################



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

  print STDERR qq(
RUNNING
------------------------------------------
script:               $0
time stamp:           $time_stamp
------------------------------------------

);

}



sub list_dir {
  
  my($dir_name, $list_pattern) = @_;
  
  opendir(DIR, $dir_name) or die "\n\n"."can't open DIR $dir_name"."\n\n";
  
  my @dir_files_list = grep /$list_pattern/, readdir DIR; 
  closedir DIR;
  
  my @filtered_dir_files_list;
  while (my $dir_object = shift(@dir_files_list)) {
    $dir_object =~ s/^\.//;
    push(@filtered_dir_files_list, $dir_object);
    #print "DIR  ".$dir_name.$dir_object."\n";
  }
  
  return @filtered_dir_files_list;
  
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
and a specified number of permutations of the original data to derive p values.
This version was written to use qiime formatted data, and uses qiime functions to 
calculate the distances (see plot_pco_with_stats.pl - does not use qiime functions).
This script can use unifrac|weighted_unifrac distance metrics. Output is in an 
automatically generated director ("./plot_qiime_pco_with_stats".\$dist_method."RESULTS/").
   
USAGE:
    --data_file                  (string)  NO DEFAULT
                                              original data file, in the old qiime format:
                                              (0 based index on left, tax string on right, 
                                              first row (#ID) = headers)

    --input_dir                  (string)  default = current directory
                                              path that containts the data file

    --tree                       (string)  NO DEFAULT
                                              path/file for *.tre file
                                              example:
                                              /home/ubuntu/software/gg_otus-4feb2011-release/trees/gg_97_otus_4feb2011.tre
                                              a *.tre file - only used if a phylogenitically 
                                              aware metric like unifrac|weighted_unifrac is 
                                              used.  Only required for phylogentically aware 
                                              metrics like unifrac|weighted_unifrac

    --groups_list                (string)  default = $groups_list
                                              file that contains groups list group per line,
                                              each sample in a group (line) is comma 
                                              separated sample names should be same as in
                                              the data_file header

    --dist_method                (string)  default = $dist_method
                                              the distance metric to be used.  Can be any 
                                              available in the installed version of qiime 
                                              (see them with >beta_diversity.py -s)

    --num_perm                   (integer) default = $num_perm 
                                              number of permutations to perform

    --perm_type                  (string)  default = $perm_type 
                                              --> choose from the following three methods <--
                                                  sample_rand   - randomize fields in 
                                                                  sample/column
                                                  dataset_rand  - randomize fields across 
                                                                  dataset
                                                  complete_rand - randomize every individual 
                                                                  count across dataset

    --num_cpus                   (integer) default = $num_cpus
                                              number of cpus to use for parallel processing
                                              to figure out how many cpus yoy have on unix/
                                              linux this should work:
                                              >grep -e "processor" -c /proc/cpuinfo
    -----------------------------------------------------------------------------------------
    --cleanup                    (flag)       default = off   ::  delete all of temp files
    --help                       (flag)       see the help/usage
    --verbose                    (flag)       run in verbose mode
    --debug                      (flag)       run in debug mode

);
  exit 1;
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
