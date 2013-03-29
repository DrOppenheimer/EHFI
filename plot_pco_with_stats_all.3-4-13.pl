#!/usr/bin/env perl

# Adapted from 11-21-12 version, for use with master that can call
# plot_pco_with_stats,
# plot_qiime_pco_with_stats, or
# plot_OTU_pco_with_stats

#use strict;
use warnings;
use Getopt::Long;
use Cwd;
use Cwd 'abs_path';
use File::Basename;

my $start = time;

my($data_file, $cleanup, $help, $verbose, $debug, $output_PCoA_dir, $output_DIST_dir, $output_avg_DISTs_dir);

my $output_dir = "NOT_SUPPLIED";
my $current_dir = getcwd()."/";
my $perm_dir = "default";
#if($debug) { print STDOUT "current_dir: "."\t".$current_dir."\n";}

#define defaults for variables that need them
my $groups_list = "groups_list";
my $dist_pipe = "MG-RAST";
my $input_dir = $current_dir;

my $print_dist = 1;
my $dist_list = "DISTs_list";
my $dist_method = "euclidean";
my $tree = "NA";  
my $avg_dists_list = "AVG_DISTs_list";
my $headers = 1; 
my $perm_list = "permutation_list" ;
my $perm_type = "sample_rand";
my $num_perm = 10;
my $num_cpus = 1;
my $time_stamp =`date +%m-%d-%y_%H:%M:%S`;  # create the time stamp month-day-year_hour:min:sec:nanosec
chomp $time_stamp;
my $DIR=dirname(abs_path($0));  # directory of the current script, used to find other scripts + datafiles

# check input args and display usage if not suitable
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

unless ( @ARGV > 0 || $data_file ) { &usage(); }

if ( ! GetOptions (
		   "f|data_file=s"     => \$data_file,
		   "g|groups_list=s"   => \$groups_list,
		   "dist_pipe=s"       => \$dist_pipe,
		   "i|input_dir=s"     => \$input_dir,
		   "o|output_dir=s"    => \$output_dir,
		   "output_PCoA_dir=s" => \$output_PCoA_dir,
		   "print_dist=i"      => \$print_dist,
		   "output_DIST_dir"   => \$output_DIST_dir,
		   "m|dist_method=s"   => \$dist_method,
		   "tree=s"            => \$tree,
		   "headers=i"         => \$headers,
		   "x|perm_dir"        => \$perm_dir,
		   "t|perm_type=s"     => \$perm_type,
		   "p|num_perm=i"      => \$num_perm,
		   "c|num_cpus=i"      => \$num_cpus,
		   "cleanup!"          => \$cleanup,
		   "help!"             => \$help, 
		   "verbose!"          => \$verbose,
		   "debug!"            => \$debug
		  )
   ) { &usage(); }

# create name for the output directory
if ($output_dir eq "NOT_SUPPLIED"){
  $output_dir = $current_dir."plot_pco_with_stats.".$data_file.".".$dist_method.".".$perm_type.".RESULTS/";
}else{
  $output_dir = $output_dir."/"."plot_pco_with_stats.".$data_file.".".$dist_method.".".$perm_type.".RESULTS/";
}

# create names for subdirectories of the output directory
$output_PCoA_dir =      $output_dir."PCoAs/";
$output_DIST_dir =      $output_dir."DISTs/";
$output_avg_DISTs_dir = $output_dir."AVG_DISTs/";
$perm_dir =             $output_dir."permutations/";

# name P value summary output file
my $output_p_value_summary = $output_dir.$data_file.".".$dist_method.".".$perm_type.".P_VALUES_SUMMARY";

# create directories for the output files
unless (-d $output_dir) { mkdir $output_dir; } #### <---------- THIS IS WHAT HAS TO BE FIXED
unless (-d $perm_dir) { mkdir $perm_dir; }
unless (-d $output_PCoA_dir) { mkdir $output_PCoA_dir; }
unless (-d $output_DIST_dir) { mkdir $output_DIST_dir; }
unless (-d $output_avg_DISTs_dir) { mkdir $output_avg_DISTs_dir;}

# create a log file and print all of the input parameters to it
my $log_file_name = $output_dir."/".$data_file.".".$dist_method.".".$perm_type.".log";
open($log_file, ">", $log_file_name) or die "cannot open $log_file $log_file_name";
print $log_file "start:"."\t".$time_stamp."\n";
print $log_file "\n"."PARAMETERS USED:"."\n";
if ($data_file)       {print $log_file "     data_file:      "."\t".$data_file."\n";}
if ($groups_list)     {print $log_file "     groups_list:    "."\t".$groups_list."\n";}
if ($dist_pipe)       {print $log_file "     dist_pipe:      "."\t".$dist_pipe."\n";}
if ($input_dir)       {print $log_file "     input_dir       "."\t".$input_dir."\n";}
if ($output_dir)      {print $log_file "     output_dir      "."\t".$output_dir."\n";}
if ($output_PCoA_dir) {print $log_file "     output_PCoA_dir "."\t".$output_PCoA_dir."\n";}
if ($print_dist)      {print $log_file "     print_dist      "."\t".$print_dist."\n";}
if ($output_DIST_dir) {print $log_file "     output_DIST_dir "."\t".$output_DIST_dir."\n";}
if ($dist_method)     {print $log_file "     dist_method     "."\t".$dist_method."\n";}
if ($tree)            {print $log_file "     tree            "."\t".$tree."\n";}
if ($headers)         {print $log_file "     headers         "."\t".$headers."\n";}
if ($perm_dir)        {print $log_file "     perm_dir        "."\t".$perm_dir."\n";}
if ($perm_type)       {print $log_file "     perm_type       "."\t".$perm_type."\n";}
if ($num_perm)        {print $log_file "     num_perm        "."\t".$num_perm."\n";}
if ($num_cpus)        {print $log_file "     num_cpus        "."\t".$num_cpus."\n";}
if ($cleanup)         {print $log_file "     cleanup         "."\t".$cleanup."\n";}
if ($help)            {print $log_file "     help            "."\t".$help."\n";}
if ($verbose)         {print $log_file "     verbose         "."\t".$verbose."\n";}
if ($debug)           {print $log_file "     debug           "."\t".$debug."\n\n";}

##################################################
##################################################
###################### MAIN ######################
##################################################
##################################################

# exit if phylogentic analysis is selected without a valid tree
if ( $dist_method =~ m/frac/ ){ 
  unless (-f "$tree") {
    print $log_file "
          You selected a phylogenetic analysis (like unifrac or weighted_unifrac),
     but you did not specify a valid -tree argument; a value was not provided, 
     the specified tree file (*.tre) does not exist, or is an empty file.

          The tree you specified was:

          $tree \n\n";
    exit 1;
  }
}

# function to log running status
my $running_text = &running();
print $log_file $running_text;

##### Make sure that the input files don't have nutty line terminators (creep in when you use excel to modify the files)
&correct_line_terminators($input_dir, $data_file);
&correct_line_terminators($input_dir, $groups_list);


##### Make sure that the groups_list only contains headers that exist in the data file -- kill the program as soon as they don't
$check_status = check_groups($input_dir, $data_file, $groups_list);
unless ($check_status eq "All groups members match a header from the data file"){
  #print $log_file "DATA_FILE  : ".$input_dir.$data_file."\n";
  #print $log_file "GROUPS_LIST: ".$input_dir.$groups_list."\n";
  print $log_file $check_status."JOB KILLED";
  #print STDOUT "DATA_FILE  : ".$input_dir.$data_file."\n";
  #print STDOUT "GROUPS_LIST: ".$input_dir.$groups_list."\n";
  #print STDOUT $check_status."JOB KILLED"."\n";
  exit 1;
}else{
  #print $log_file "DATA_FILE  : ".$input_dir.$data_file."\n";
  #print $log_file "GROUPS_LIST: ".$input_dir.$groups_list."\n";
  print $log_file $check_status.", proceeding"."\n\n";
  #print STDOUT "DATA_FILE  : ".$input_dir.$data_file."\n";
  #print STDOUT "GROUPS_LIST: ".$input_dir.$groups_list."\n";
  #print STDOUT "\n\n".$check_status.", proceeding"."\n\n";
}



##########################################
########## PROCESS ORIGNAL DATA ##########
##########################################

# correct selected pipe for unifrac and OTU dists if needed
if ( $dist_method =~ m/frac/ ){ 
  $dist_pipe = "qiime";
  print $log_file "dist_pipe changed to ".$dist_pipe." to handle dist_method ".$dist_method."\n";    
}elsif ( $dist_method =~ m/OTU/ ) { 
  $dist_pipe = "OTU"; 
  print $log_file "dist_pipe changed to ".$dist_pipe." to handle dist_method ".$dist_method."\n";
}else{
  print $log_file "selected dist_pipe ".$dist_pipe." can handledist_method ".$dist_method."\n";
}



# process original (non permuted) data using qiime to calculate all distances/ dissimilarities
if ( $dist_pipe eq "qiime" ){
  process_original_qiime_data($data_file, $dist_method, $tree, $input_dir, $output_dir, $log_file)
}elsif ( $dist_pipe eq "OTU" ){
  process_original_OTU_data($data_file, $dist_method, $input_dir, $output_dir, $log_file)
}else{
  process_original_data($data_file, $dist_method, $input_dir, $output_dir, $log_file)
}

#  If qiime pipe is used, reformat dat_file from old_qiime table to R friendly format before creating permuted data
if ( $dist_pipe eq "qiime" ){
  system("qiime_2_R.pl -i $input_dir$data_file -o $input_dir$data_file -c 3");
  print $log_file "create R-formatted version of qiime abundance table:"."\n".
    "( qiime_2_R.pl -i $input_dir$data_file -o $input_dir$data_file -c 3 )"."\n".
      "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
}


###### THESE NEED WORK   OTU $avg_dists_list ...
# process permuted data
if ( $dist_pipe eq "qiime" ){
  process_permuted_qiime_data($data_file, $output_dir, $perm_list, $num_cpus, $perm_dir, $output_PCoA_dir, $output_DIST_dir, $output_avg_DISTs_dir, $dist_method, $tree, $headers, $log_file)
}elsif ( $dist_pipe eq "OTU" ){
  process_permuted_OTU_data($data_file, $output_dir, $perm_list, $avg_dists_list, $num_cpus, $perm_dir, $output_PCoA_dir, $output_DIST_dir, $output_avg_DISTs_dir, $dist_method, $headers, $log_file)
}else{
  process_permuted_data($data_file, $output_dir, $perm_list, $num_cpus, $perm_dir, $output_PCoA_dir, $output_DIST_dir, $output_avg_DISTs_dir, $dist_method, $headers, $log_file)
}


                                                                                                                        
# perform cleanup if specified
if ($cleanup) {
  &cleanup_sub();
}



my $end = time;
my $min = int(($end - $start) / 60);
my $sec = ($end - $start) % 60;



#print STDOUT "all DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
#print STDOUT "ELAPSED TIME: "."(".$min.")"."minutes "."(".$sec.")"."seconds"."\n";
print $log_file "all DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
print $log_file "ELAPSED TIME: "."(".$min.")"."minutes "."(".$sec.")"."seconds"."\n";



############### SUBS ###############
############### SUBS ###############
############### SUBS ###############



# removed permutation files     
sub cleanup_sub { 
   print $log_file "cleanup ... "."\n";
  system("rm $output_dir*_list; rm -R $output_PCoA_dir; rm -R $output_DIST_dir; rm -R $output_avg_DISTs_dir; rm -R $perm_dir");
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
}



# usage / help
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
    -f|--data_file        (string)  no default
                                    original data file (in R compatible tab delimited format)
    -i|--input_dir        (string)  default = $current_dir
                                    path that containts the data file
    -o|--output_dir       (string)  default = $output_dir
    -g|--groups_list      (string)  default = $groups_list
                                    file that contains groups list
                                    group per line, each sample in a group (line) is comma separated
                                    sample names should be same as in the data_file header
    -p|--num_perm         (integer) default = $num_perm 
                                    number of permutations to perform
    -t|--perm_type        (string)  default = $perm_type 
                                    --> choose from the following three methods <--
                                         sample_rand   - randomize fields in sample/column
                                         dataset_rand  - randomize fields across dataset
                                         complete_rand - randomize every individual count across dataset
                                         rowwise_rand  - randomize fields in taxon/row 
                                         sampleid_rand - randomize sample/column labels only
    -m|--dist_method      (string)  default = $dist_method
                                    --> can slect from the following distances/dissimilarities <-- 
                                         bray-curtis | maximum  | canberra    | binary   | minkowski  | 
                                         euclidean   | jacccard | mahalanobis | sorensen | difference |
                                         manhattan
    -x|--perm_dir         (string)  default = $perm_dir
                                    directory to store permutations
    -c|--num_cpus         (integer) default = $num_cpus
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
  my $running_text = qq(
RUNNING
------------------------------------------
script:               $0
time stamp:           $time_stamp
------------------------------------------
);
  
  print STDOUT $running_text;

  return $running_text;

}


# sub running {
#   my ($err) = @_;
#   my $script_call = join('\t', @_);
#   my $num_args = scalar @_;
#   print STDOUT qq(
# RUNNING
# ------------------------------------------
# script:               $0
# time stamp:           $time_stamp
# ------------------------------------------
# );
# print LOG qq(
# RUNNING
# ------------------------------------------
# script:               $0
# time stamp:           $time_stamp
# ------------------------------------------

# );
# }


# create a list of pattern matching files in a directory
sub list_dir {
  
  my($dir_name, $list_pattern, $dir_list) = @_;
  
  open(DIR_LIST, ">", $dir_list) or die "\n\n"."can't open DIR_LIST $dir_list"."\n\n";
  opendir(DIR, $dir_name) or die "\n\n"."can't open DIR $dir_name"."\n\n";
  
  my @dir_files_list = grep /$list_pattern/, readdir DIR; 
  print DIR_LIST join("\n", @dir_files_list); print DIR_LIST "\n";
  closedir DIR;
  
}




# correct line terminators
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



# Process the original (non permuted) data, MG-RAST annotations
sub process_original_data {

  my ($data_file, $dist_method, $input_dir, $output_dir, $log_file) = @_;
 
  # process the original data_file to produce PCoA and DIST files
  print $log_file "process original data file (".$data_file.") > *.PCoA & *.DIST ... "."\n";
  my $output_og_pco = $data_file.".".$dist_method.".OG.PCoA";
  system("$DIR/plot_pco_shell.sh $data_file $input_dir $output_dir 1 $output_dir $dist_method $headers");
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  # Process original data_file.DIST to produce original_file.DIST.AVG_DIST
  print $log_file "process original data *.DIST file (".$data_file.".".$dist_method.".DIST) > *.AVG_DIST ... "."\n";
  system("$DIR/avg_distances.sh $data_file.$dist_method.DIST $output_dir $groups_list $data_file.$dist_method.DIST $output_dir");
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  

}



# Process the original (non permuted) data, Qiime annotations
sub process_original_qiime_data {

  my ($data_file, $dist_method, $tree, $input_dir, $output_dir, $log_file) = @_;
   
  # convert qiime formatted abundance table 
  # (0 based index on left, tax string on right, first non # row = headers) to biom format
  my $biom_file = $data_file.".biom";
  system("convert_biom.py -i $input_dir$data_file -o $output_dir$biom_file --biom_table_type=\"otu table\"");
  print $log_file "convert data_file to biom format"."\n".
    "( ".$data_file." > ".$data_file.".biom )"."\n".
      "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
  
  ##### produce a distance matrix (*.DIST) using qiime - *.tre needed for phylogenetically aware metrics (i.e. unifracs)
  print $log_file "produce distance matrix with qiime:"."\n".
    "( ".$data_file.".biom > ".$output_dir."distance-metric_".$data_file.".biom )"."\n";

  # add the tree argument to beta_diversity.py for unifrac (phylogenetically aware) analyses
  if ( $dist_method =~ m/frac/) { 
    system("beta_diversity.py -i $output_dir$biom_file -o $output_dir -m $dist_method -t $tree");
    print $log_file "qiime-based distance analysis:"."\n".
      "( beta_diversity.py -i $output_dir$biom_file -o $output_dir -m $dist_method -t $tree )"."\n".
	"DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";
  }else{
    system("beta_diversity.py -i $output_dir$biom_file -o $output_dir -m $dist_method");
    print $log_file "qiime-based distance analysis:"."\n".
      "( beta_diversity.py -i $output_dir$biom_file -o $output_dir -m $dist_method )"."\n".
	"DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n"; 
  }
  
  # rename the output dist file
  my $qimme_dist_filename = $output_dir.$dist_method."_".$data_file.".txt";
  my $dist_filename = $output_dir.$dist_method."_".$data_file.".DIST";
  system("mv $qimme_dist_filename $dist_filename");

  # use R to produce a PCoA from the distance matrix
  my $pcoa_file = $output_dir.$dist_method."_".$data_file.".PCoA";
  system("plot_qiime_pco_shell.sh $dist_filename $pcoa_file");
  print $log_file "produce PCoA from qiime distance:"."\n".
    "( plot_qiime_pco_shell.sh $dist_filename $pcoa_file )"."\n".
      "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n"; 

  # create AVG_DIST file for the original data
  $dist_filename = $dist_method."_".$data_file.".DIST";
  my $avg_dist_filename = $dist_method."_".$data_file;
  system("avg_distances.sh $dist_filename $output_dir $groups_list $avg_dist_filename $output_dir");
  print $log_file "Produce *.AVG_DIST file from the original data *.DIST file"."\n"."DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

}



# Process the original (non permuted) data, with OTU distances
sub process_original_OTU_data {

  my($data_file, $dist_method, $input_dir, $output_dir, $log_file) = @_;

  # process the original data_file to produce PCoA and DIST files
  print $log_file "process original data file (".$data_file.") > *.PCoA & *.DIST ... "."\n";
  system("OTU_similarities_shell.7-31-12.sh $data_file $input_dir $output_dir 1 $output_dir $dist_method $headers");
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  # process original data_file.DIST to produce original_file.DIST.AVG_DIST
  print $log_file "process original data *.DIST file (".$data_file.".".$dist_method.".DIST) > *.AVG_DIST ... "."\n";
  system("avg_distances.sh $data_file.$dist_method.DIST $output_dir $groups_list $data_file.$dist_method.DIST $output_dir");
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

}




sub process_permuted_data {

  my($data_file, $output_dir, $perm_list, $num_cpus, $perm_dir, $output_PCoA_dir, $output_DIST_dir, $output_avg_DISTs_dir, $dist_method, $headers, $log_file) = @_;

  # use R script sample_matrix.r to generate permutations of the original data
  print $log_file "generate (".$num_perm.") permutations ... "."\n";
  my $R_rand_script = "$data_file.R_sample_script.".$time_stamp.".r";
  open(R_SCRIPT, ">", $R_rand_script) or die "cannot open R_SCRIPT $R_rand_script";

  #create R script to generate permutations - permutations are placed in a permutations directory
  print R_SCRIPT (
		  "# script generated by plot_pco_with_stats.pl to run sample_matrix.r"."\n".
		  "source(\"$DIR/sample_matrix.9-18-12.r\")"."\n".
		  "sample_matrix(file_name = \"$data_file\", file_dir = \"$input_dir\", num_perm = $num_perm, perm_type = \"$perm_type\", write_files = 1, perm_dir = \"$perm_dir\", verbose = 0, debug = 0)"
		 );

  # generate permutations with R script created above
  system( "R --vanilla --slave < $R_rand_script" );
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
  system( "rm $R_rand_script" );

  # create list of the permutation files
  print $log_file "creating list of permutated data files ... "."\n";
  &list_dir($perm_dir, "permutation",  $output_dir.$perm_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  # perform PCoA on all of the permutations - outputs placed in directories created for the PCoA and DIST files
  print $log_file "process permutations > *.PCoA & *.DIST ... "."\n"; 
  print $log_file "executing: cat $output_dir$perm_list | xargs -n1 -P$num_cpus -I{} $DIR/plot_pco_shell.sh {} $perm_dir $output_PCoA_dir 1 $output_DIST_dir $dist_method $headers"."\n";
  system( "cat $output_dir$perm_list | xargs -n1 -P$num_cpus -I{} $DIR/plot_pco_shell.sh {} $perm_dir $output_PCoA_dir 1 $output_DIST_dir $dist_method $headers" );
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  # Create list of all permutation *.DIST files
  print $log_file "creating list of *.DIST files produced from permutated data ... "."\n"; 
  &list_dir($output_DIST_dir, ".DIST",  $output_dir.$dist_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  # Create files that contain the averages of all within and between group distances
  print $log_file "process permutation *.DIST > *.AVG_DIST ... "."\n";
  print $log_file "executing: cat  $output_dir$dist_list | xargs -n1 -P$num_cpus -I{} $DIR/avg_distances.sh {} $output_DIST_dir $groups_list {} $output_avg_DISTs_dir"."\n";
  system ( "cat  $output_dir$dist_list | xargs -n1 -P$num_cpus -I{} $DIR/avg_distances.sh {} $output_DIST_dir $groups_list {} $output_avg_DISTs_dir" );
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
 
  # Create a list of all the *.AVG_DIST files
  print $log_file "creating list of *.AVG_DIST files ... "."\n"; 
  &list_dir($output_avg_DISTs_dir, "AVG_DIST",  $output_dir.$avg_dists_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  # Run the final script to calculate P values by comparing the original to all permutaion derived distances matrixes
  print $log_file "processing all *.AVG_DIST to produce P values ... "."\n";
  print $log_file "executing $DIR/avg_dist_summary.8-24-12.pl -og_avg_dist_file $output_dir$data_file.$dist_method.DIST.AVG_DIST -avg_dists_dir $output_avg_DISTs_dir -avg_dists_list $output_dir$avg_dists_list -output_file $output_p_value_summary"."\n";
  system( "$DIR/avg_dist_summary.8-24-12.pl -og_avg_dist_file $output_dir$data_file.$dist_method.DIST.AVG_DIST -avg_dists_dir $output_avg_DISTs_dir -avg_dists_list $output_dir$avg_dists_list -output_file $output_p_value_summary" );
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";


}



sub process_permuted_qiime_data {

  my($data_file, $output_dir, $perm_list, $num_cpus, $perm_dir, $output_PCoA_dir, $output_DIST_dir, $output_avg_DISTs_dir, $dist_method, $tree, $headers, $log_file) = @_;

  # Create a version of the QIIME table in R friendly format
  system("$DIR/qiime_2_R.pl -i $input_dir$data_file -o $input_dir$data_file -c 3");
  print STDERR "create R-formatted version of qiime abundance table:"."\n".
    "( qiime_2_R.pl -i $input_dir$data_file -o $input_dir$data_file -c 3 )"."\n".
      "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # use R script sample_matrix.r to generate permutations of the original data
  my $R_rand_script = "R_sample_matrix_script.".$time_stamp.".r"; # create R script to generate permutations

  my $R_data_file = $data_file.".qiime_ID_and_tax_string.R_table";
  if ($debug){print "R_data_file: $R_data_file"."\n";}

  open(R_SCRIPT, ">", $R_rand_script) or die "cannot open R_SCRIPT $R_rand_script";

  print R_SCRIPT (
		  "# script generated by plot_qiime_pco_with_stats.pl to run sample_matrix.r"."\n".
		  "source(\"$DIR/sample_matrix.9-18-12.r\")"."\n".
		  "sample_matrix(file_name = \"$R_data_file\", file_dir = \"$input_dir\", num_perm = $num_perm, perm_type = \"$perm_type\", write_files = 1, perm_dir = \"$perm_dir\", verbose = 0, debug = 1)"
	       );
  
  system( "R --vanilla --slave < $R_rand_script" ); # run the script
  system( "rm $R_rand_script" );
  print STDERR "generated (".$num_perm.") permutations in $perm_dir "."\n".
    "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";


  # generate qiime formatted versions of the permuted data tables # could use xargs here too
  my @R_permutation_list = &list_dir($perm_dir, "R_table");
  foreach my $R_permutation (@R_permutation_list){
    system("$DIR/qiime_2_R.pl -i $perm_dir$R_permutation -c 5");
    if($cleanup){system("rm $perm_dir$R_permutation");}
  }
  print $log_file "Generated *.Qiime_table files from *.R_table files in $perm_dir"."\n".
    "deleted *.R_table"."\n".
      "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # generate biom format files from each qiime_formattted table # could use xargs here too
  my @Qiime_permutation_list = &list_dir($perm_dir, "Qiime_table\$");
  foreach my $Qiime_permutation (@Qiime_permutation_list){
    my $biom_permutation = $Qiime_permutation.".biom";
    system("convert_biom.py -i $perm_dir$Qiime_permutation -o $perm_dir$biom_permutation --biom_table_type=\"otu table\"");
    if($cleanup){system("rm $perm_dir$Qiime_permutation");}
  }
  print $log_file "Generated biom tables from Qiime_formatted tables in $perm_dir"."\n".
    "deleted *.Qiime_table"."\n".
      "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # produce *.DIST files for each permutation - using qiime beta_diversity.py
  my @biom_permutation_list = &list_dir($perm_dir, ".biom\$");
  my $biom_file_list = "$perm_dir"."biom_file_list";
  open(BIOM_FILE_LIST, ">", $biom_file_list);
  print BIOM_FILE_LIST join("\n", @biom_permutation_list);
  close(BIOM_FILE_LIST);

  if ( $dist_method =~ m/frac/ ) { # add the tree argument to beta_diversity.py for unifrac (phylogenetically aware) analyses
    print $log_file "executing: cat $biom_file_list | xargs  -n1 -P $num_cpus -I{} beta_diversity.py -i '$perm_dir'{} -o $output_DIST_dir -m $dist_method -t $tree"."\n";
    system( "cat $biom_file_list | xargs  -n1 -P $num_cpus -I{} beta_diversity.py -i '$perm_dir'{} -o $output_DIST_dir -m $dist_method -t $tree" );
    
  }else{
    #if($debug) { print STDOUT "cat $biom_file_list | xargs  -n1 -P $num_cpus -I{} beta_diversity.py -i '$perm_dir'{} -o $output_DIST_dir -m $dist_method"."\n"; }
    print $log_file "executing: cat $biom_file_list | xargs  -n1 -P $num_cpus -I{} beta_diversity.py -i '$perm_dir'{} -o $output_DIST_dir -m $dist_method"."\n";
    system( "cat $biom_file_list | xargs  -n1 -P $num_cpus -I{} beta_diversity.py -i '$perm_dir'{} -o $output_DIST_dir -m $dist_method" );
    
}
  print $log_file "produced *.DIST (distance matrixes) for each of (".$num_perm.") permutations in $perm_dir"."\n".
    "Note that they have a *.txt extension, not *.DIST"."\n".
      "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # produce *.AVG_DIST file for each *.DIST file
  my @dist_permutation_list = &list_dir($output_DIST_dir, ".txt");
  my $dist_file_list = $output_DIST_dir."dist_file_list";
  open(DIST_FILE_LIST, ">", $dist_file_list);
  print DIST_FILE_LIST join("\n", @dist_permutation_list);
  close(DIST_FILE_LIST);
  system ( "cat $dist_file_list | xargs -n1 -P $num_cpus -I{} $DIR/avg_distances.sh {} $output_DIST_dir $groups_list {} $output_avg_DISTs_dir" );
  print $log_file "produced *.AVG_DIST (distance matrixes) for each of (".$num_perm.") permutations in $output_DIST_dir"."\n".
    "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

  # # generate AVG_DISTs_list
  # my @AVG_DISTs_list = &list_dir($output_avg_DISTs_dir, ".AVG_DIST\$");
  # my $avg_dists_list = $output_avg_DISTs_dir."AVG_DISTs_list";
  # open(AVG_DISTS_LIST, ">", $avg_dists_list);
  # print AVG_DISTS_LIST join("\n", @AVG_DISTs_list);
  # close(AVG_DISTS_LIST);

  # Create a list of all the *.AVG_DIST files
  print $log_file "creating list of *.AVG_DIST files ... "."\n"; 
  &list_dir($output_avg_DISTs_dir, "AVG_DIST",  $output_dir.$avg_dists_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  # Run the final script to calculate P values by comparing the original to all permutaion derived distances matrixes
  my $output_p_value_summary = $output_dir.$data_file.".".$dist_method.".P_VALUES_SUMMARY";
  my $og_avg_dist_filename = $output_dir.$avg_dist_filename.".AVG_DIST";
  print $log_file "executing: avg_dist_summary.8-24-12.pl -og_avg_dist_file $og_avg_dist_filename -avg_dists_dir $output_avg_DISTs_dir -avg_dists_list $avg_dists_list -output_file $output_p_value_summary"."\n";
system( "$DIR/avg_dist_summary.8-24-12.pl -og_avg_dist_file $og_avg_dist_filename -avg_dists_dir $output_avg_DISTs_dir -avg_dists_list $avg_dists_list -output_file $output_p_value_summary" );
  print $log_file "produced final summary:"."\n".$output_dir.$data_file.".P_VALUES_SUMMARY"."\n".
    "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";

}



sub process_permuted_OTU_data {

  my($data_file, $output_dir, $perm_list, $num_cpus, $perm_dir, $output_PCoA_dir, $output_DIST_dir, $output_avg_DISTs_dir, $dist_method, $headers, $log_file) = @_;
  
  print R_SCRIPT (
		  "# script generated by plot_pco_with_stats.pl to run sample_matrix.r"."\n".
		  "source(\"$DIR/sample_matrix.9-18-12.r\")"."\n".
		  "sample_matrix(file_name = \"$data_file\", file_dir = \"$input_dir\", num_perm = $num_perm, perm_type = \"$perm_type\", write_files = 1, perm_dir = \"$perm_dir\", verbose = 0, debug = 0)"
		 );

  # generate permutations with R script created above
  system( "R --vanilla --slave < $R_rand_script" );
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
  system( "rm $R_rand_script" );

  # create list of the permutation files
  print $log_file "creating list of permutated data files ... "."\n";
  &list_dir($perm_dir, "permutation", $output_dir.$perm_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  # perform PCoA on all of the permutations - outputs placed in directories created for the PCoA and DIST files
  print $log_file "process permutations > *.PCoA & *.DIST ... "."\n";
  #if($debug){
  # print "Below is the command line used for Xargs:"."\n";
  #  system( "cat $output_dir$perm_list | xargs -t -n1 -P$num_cpus -I{} OTU_similarities_shell.7-31-12.sh {} $perm_dir $output_PCoA_dir 1 $output_DIST_dir $dist_method $headers" );
#}else{
  print $log_file "executing: cat $output_dir$perm_list | xargs -n1 -P$num_cpus -I{} OTU_similarities_shell.7-31-12.sh {} $perm_dir $output_PCoA_dir 1 $output_DIST_dir $dist_method $headers"."\n";
  system( "cat $output_dir$perm_list | xargs -n1 -P$num_cpus -I{} $DIR/OTU_similarities_shell.7-31-12.sh {} $perm_dir $output_PCoA_dir 1 $output_DIST_dir $dist_method $headers" );
#
#}
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";



  # Create list of all permutation *.DIST files
  print $log_file "creating list of *.DIST files produced from permutated data ... "."\n"; 
  &list_dir($output_DIST_dir, ".DIST", $output_dir.$dist_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  # Create files that contain the averages of all within and between group distances
  print $log_file "process permutation *.DIST > *.AVG_DIST ... "."\n";
  #if($debug){
  #  system ( "cat $output_dir$dist_list | xargs -t -n1 -P$num_cpus -I{} avg_distances.sh {} $output_DIST_dir $groups_list {} $output_avg_DISTs_dir" );
  #}else{
  
  print $log_file "executing: cat $output_dir$dist_list | xargs -n1 -P$num_cpus -I{} avg_distances.sh {} $output_DIST_dir $groups_list {} $output_avg_DISTs_dir"."\n";
  system ( "cat $output_dir$dist_list | xargs -n1 -P$num_cpus -I{} avg_distances.sh {} $output_DIST_dir $groups_list {} $output_avg_DISTs_dir" );
  #}
  
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

  # # generate AVG_DISTs_list
  # my @AVG_DISTs_list = &list_dir($output_avg_DISTs_dir, ".AVG_DIST\$");
  # my $avg_dists_list = $output_avg_DISTs_dir."AVG_DISTs_list";
  # open(AVG_DISTS_LIST, ">", $avg_dists_list);
  # print AVG_DISTS_LIST join("\n", @AVG_DISTs_list);
  # close(AVG_DISTS_LIST);
  
    # Create a list of all the *.AVG_DIST files
  print $log_file "creating list of *.AVG_DIST files ... "."\n"; 
  &list_dir($output_avg_DISTs_dir, "AVG_DIST", $output_dir.$avg_dists_list);
  print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";

   # Run the final script to calculate P values by comparing the original to all permutaion derived distances matrixes
  my $output_p_value_summary = $output_dir.$data_file.".".$dist_method.".P_VALUES_SUMMARY";
  my $og_avg_dist_filename = $output_dir.$avg_dist_filename.".AVG_DIST";
  print $log_file "executing: avg_dist_summary.8-24-12.pl -og_avg_dist_file $og_avg_dist_filename -avg_dists_dir $output_avg_DISTs_dir -avg_dists_list $avg_dists_list -output_file $output_p_value_summary"."\n";
system( "$DIR/avg_dist_summary.8-24-12.pl -og_avg_dist_file $og_avg_dist_filename -avg_dists_dir $output_avg_DISTs_dir -avg_dists_list $avg_dists_list -output_file $output_p_value_summary" );
  print $log_file "produced final summary:"."\n".$output_dir.$data_file.".P_VALUES_SUMMARY"."\n".
    "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n\n";


  # # Run the final script to calculate P values by comparing the original to all permutaion derived distances matrixes
  # print $log_file "processing all *.AVG_DIST to produce P values ... "."\n";
  # print $log_file "executing: perl ~/bin/avg_dist_summary.8-24-12.pl -og_avg_dist_file $output_dir$data_file.$dist_method.DIST.AVG_DIST -avg_dists_dir $output_avg_DISTs_dir -avg_dists_list $output_dir$avg_dists_list -output_file $output_p_value_summary"."\n";
  # system( "perl ~/bin/avg_dist_summary.8-24-12.pl -og_avg_dist_file $output_dir$data_file.$dist_method.DIST.AVG_DIST -avg_dists_dir $output_avg_DISTs_dir -avg_dists_list $output_dir$avg_dists_list -output_file $output_p_value_summary" );
  # print $log_file "DONE at:"."\t".`date +%m-%d-%y_%H:%M:%S`."\n";
  
}



sub check_groups { # script hashes the headers from the data file and checks to see that all headers in groups have a match in the data file

  my($input_dir, $data_file, $groups_list) = @_;

  my $check_status = "All groups members match a header from the data file"; # variable to carry results of the check back to main
  my $header_hash; # declare hash for the individual headers
  
  open(DATA_FILE, "<", $input_dir."/".$data_file) or die "\n\n"."can't open DATA_FILE $data_file"."\n\n";
  
  my $header_line = <DATA_FILE>; # get the line with the column headers from the data file
  chomp $header_line;
  #if($debug){ print STDOUT "HEADER_LINE: ".$header_line."\n" }
  my @header_array = split("\t", $header_line); # place headers in an array
  shift @header_array; # shift off the first entry -- should be empty (MG-RAST) or a non essential index description (Qiime)
  
  
  #if($debug){ my $num_headers = 0; }
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
