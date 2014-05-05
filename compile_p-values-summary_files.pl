#!/usr/bin/env perl


#use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use Cwd;

my $start_time_stamp = `date +%m-%d-%y_%H:%M:%S`;
chomp $start_time_stamp;

my ($target_dir, $unzip, $help, $verbose, $debug);
my $input_pattern = ".P_VALUE_SUMMARY\$";
my $output_pattern;
my $current_dir = getcwd()."/";
my $output_zip = "AMETHST_Summary.tar.gz";
my($group_name, $raw_dist, $group_dist_stdev, $scaled_dist, $dist_p, $num_perm, $group_members, $sort_output);
#my $raw_dists_out ="";

#if($debug) { print STDOUT "current_dir: "."\t".$current_dir."\n";}

# check input args and display usage if not suitable
#unless($go){if ( @ARGV==0 ) { &usage(); }}
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

#unless ( @ARGV > 0 || $data_file ) { &usage(); }

if ( ! GetOptions (
		   "d|target_dir=s"     => \$target_dir,
		   "u|unzip!"           => \$unzip,
		   "i|input_pattern=s"  => \$input_pattern,
		   "o|output_pattern=s" => \$output_pattern,
		   #"g|go!"              => \$go,
                   "s|sort_output!"     => \$sort_output,
		   "z|output_zip=s"     => \$output_zip,
		   "h|help!"            => \$help, 
		   "v|verbose!"         => \$verbose,
		   "b|debug!"           => \$debug
		  )
   ) { &usage(); }


unless( $output_zip =~ m/\.tar\.gz$/ ){ die "\n\n"."-z|--output_zip must be of format *.tar.gz"."\n\n"; }

unless ($target_dir) {$target_dir = $current_dir;} # use current directory if no other is supplied
#unless ($output_pattern) {$output_pattern = "my_compiled.P_VALUES_SUMMARY.".$start_time_stamp;}
unless ($output_pattern) {$output_pattern = "my_compiled.P_VALUES_SUMMARY";}
#if($debug){print STDOUT "\n\n\noutput_pattern: ".$output_pattern."\n\n\n"}


if ( $unzip ){
  #system("ls *.tar.gz > tar_list.txt")==0 or die "died listing *.tar.gz";  
  system('for i in *tar.gz; do tar -zxf $i; done')==0 or die "died unzipping *.tar.gz listed in tar_list.txt";
}


# create output files
open(OUTPUT_RAW_DISTS, ">",       $target_dir.$output_pattern.".raw_avg_dist") or die "can't open OUTPUT_RAW_DISTS";
open(OUTPUT_RAW_DISTS_STDEV, ">", $target_dir.$output_pattern.".raw_avg_dist_stdev") or die "can't open OUTPUT_RAW_DISTS_STDEV";
open(OUTPUT_SCALED_DISTS, ">",    $target_dir.$output_pattern.".scaled_avg_dist") or die "can't open OUTPUT_SCALED_DISTS";
open(OUTPUT_P_VALUES, ">",        $target_dir.$output_pattern.".p_values") or die "can't open OUTPUT_P_VALUES";
open(OUTPUT_NUM_PERM, ">",        $target_dir.$output_pattern.".num_perm") or die "can't open OUTPUT_NUM_PERM";
open(LOG, ">",                    $target_dir.$output_pattern.".log") or die "can't open LOG";

# print selected args to the log
print LOG qq(
time stamp:           $start_time_stamp
script:               $0
############### ARGS ###############
d|target_dir       $target_dir
i|input_pattern    $input_pattern
o|output_pattern   $output_pattern
z|output_zip       $output_zip
############## FLAGS ###############
);
if( defined($unzip) )      { print LOG "u|unzip            $unzip\n"; }      else{ print LOG "u|unzip            0\n"; }
#if( defined($go) )         { print LOG "g|go               $go\n"; }         else{ print LOG "g|go               0\n"; }
if( defined($sort_output) ){ print LOG "s|sort_output      $sort_output\n"; }else{ print LOG "s|sort_output      0\n"; }
if( defined($help) )       { print LOG "h|help             $help\n"; }       else{ print LOG "h|help             0\n"; }
if( defined($verbose) )    { print LOG "v|erbose           $verbose\n"; }    else{ print LOG "v|verbose          0\n"; }
if( defined($debug) )      { print LOG "d|debug            $debug\n"; }      else{ print LOG "d|debug            0\n"; }
print LOG "####################################";


####################################


# Start the header strings
my $raw_dists_header = "RAW_DISTS"."\n"."input_file";
my $group_dists_stdev_header = "RAW_DISTS_STDEV"."\n"."input_file";
my $scaled_dists_header = "SCALED_DISTS"."\n"."input_file";
my $dist_ps_header = "p's"."\n"."input_file";
my $num_perms_header = "NUM_PERMS"."\n"."input_file";

# read input file names into array
@file_list = &list_dir($target_dir, $input_pattern);  

my $file_counter = 0;
foreach my $file (@file_list){ # process each file 
  #if($debug){print STDOUT "\n".$file;}
 
 # initialize outputs
  my $raw_dists_out = $file;
  my $raw_dists_stdevs_out = $file;
  my $scaled_dists_out = $file;
  my $dist_ps_out = $file;
  my $num_perms_out = $file;
  
  open(FILE, "<", $target_dir.$file) or die "can't open FILE $target_dir$file"; 
  while (my $line = <FILE>){
    
    unless ($line =~ m/^#/){ # skip comment lines
      #if($debug){print STDOUT $line;}
      chomp $line;
      if($debug){print STDOUT "LINE: ".$line."\n";}
      my @line_array = split("\t", $line);
      $group_name = $line_array[0];
      if($debug){print STDOUT "\n"."group_name:"."\t".$group_name."\n";}
      
      # parse data from line
      $raw_dist = $line_array[1];
      $group_dist_stdev = $line_array[2];
      $scaled_dist = $line_array[3];
      $dist_p = $line_array[4];
      $num_perm = $line_array[5];
      $group_members = $line_array[6];

      # add data to output
      $raw_dists_out = $raw_dists_out."\t".$raw_dist;
      $raw_dists_stdevs_out = $raw_dists_stdevs_out."\t".$group_dist_stdev;
      $scaled_dists_out = $scaled_dists_out."\t".$scaled_dist;
      $dist_ps_out = $dist_ps_out."\t".$dist_p;
      $num_perms_out = $num_perms_out."\t".$num_perm;
      
      #if($debug){print STDOUT "\nraw_dists: ".$raw_dists_out;}
      
      # complete the header strings when reading through the first file
      if ($file_counter == 0) {

	$raw_dists_header = $raw_dists_header."\t".$group_name." :: ".$group_members;
	$group_dists_stdev_header = $group_dists_stdev_header."\t".$group_name." :: ".$group_members;
	$scaled_dists_header = $scaled_dists_header."\t".$group_name." :: ".$group_members;
	$dist_ps_header = $dist_ps_header."\t".$group_name." :: ".$group_members;
	$num_perms_header = $num_perms_header."\t".$group_name." :: ".$group_members;
	
      }

      #if($debug){print STDOUT "\n".$raw_dists_header; }

    }
    

  }
 
  if ($file_counter == 0){ # print the headers
    print OUTPUT_RAW_DISTS $raw_dists_header."\n";
    print OUTPUT_RAW_DISTS_STDEV $group_dists_stdev_header."\n";
    print OUTPUT_SCALED_DISTS $scaled_dists_header."\n";
    print OUTPUT_P_VALUES $dist_ps_header."\n";
    print OUTPUT_NUM_PERM $num_perms_header."\n";
  }
  
  #print the data
  print OUTPUT_RAW_DISTS $raw_dists_out."\n";
  print OUTPUT_RAW_DISTS_STDEV $raw_dists_stdevs_out."\n";
  print OUTPUT_SCALED_DISTS $scaled_dists_out."\n";
  print OUTPUT_P_VALUES $dist_ps_out."\n";
  print OUTPUT_NUM_PERM $num_perms_out."\n";
  $file_counter++;
  

}
  


if ( $sort_output ){
# create folders for summary output and move files to them
  
  # name of the output directory is name of archive with all extensions stripped, and prefixed with "AMETHST_Summary."
  my $summary_dir_base = basename($output_zip, ".tar.gz");
  #my $summary_dir_base = "AMETHST_Summary.".($output_zip =~ s/\.[^\n]*//); 
  
  my $summary_dir = $current_dir.$summary_dir_base;
  unless ( -d $summary_dir ) {
    mkdir $summary_dir;
  } 
  my $move_pcoas_string = "mv *.P_VALUES_SUMMARY.* $summary_dir";
  system($move_pcoas_string)==0 or die "died running"."\n".$move_pcoas_string."\n";

  my $pcoa_flat_dir = $summary_dir."/PCoA_flat_files";
  unless ( -d $pcoa_flat_dir ){
    mkdir $pcoa_flat_dir;
  }
  my $move_pcoa_flat_string = "mv *.PCoA $pcoa_flat_dir";
  system($move_pcoa_flat_string)==0 or die "died running"."\n".$move_pcoa_flat_string."\n";

  my $pcoa_image_dir = $summary_dir."/PCoA_images";
  unless ( -d $pcoa_image_dir ){
    mkdir $pcoa_image_dir;
  }
  my $move_pcoa_image_string = "mv *.pcoa.png $pcoa_image_dir";
  system($move_pcoa_image_string)==0 or die "died running"."\n".$move_pcoa_image_string."\n";

  my $pcoa_p_summary_dir = $summary_dir."/P_value_summaries";
  unless ( -d $pcoa_p_summary_dir ){
    mkdir $pcoa_p_summary_dir;
  }
  my $move_p_summaries_string = "mv *.P_VALUE_SUMMARY $pcoa_p_summary_dir";
  system($move_p_summaries_string)==0 or die "died running"."\n".$move_p_summaries_string."\n";

  my $individual_results_dir = $summary_dir."/individual_results/";
  unless ( -d $individual_results_dir ){
    mkdir $individual_results_dir;
  }

  # this one's a little more complicate - copies the individual result folders to the summary dir
  my $list_individual_results_string = "ls -d *.RESULTS> individual_results_list";
  system($list_individual_results_string)==0 or die "died running"."\n".$list_individual_results_string."\n";
  my $copy_individual_results_string = "for i in `cat individual_results_list`; do mv \$i $individual_results_dir; done";
  system($copy_individual_results_string)==0 or die "died running"."\n".$copy_individual_results_string."\n";

  # # If non default, make sure $output_zip has the correct extension - removes double .. if it introduces them
  # unless( $output_zip eq "AMETHST_Summary.tar.gz" ){
  #   unless( $output_zip =~ m/\.tar\.gz$/ ){ 
  #     $output_zip = $output_zip.".tar.gz";
  #     $output_zip =~ s/\.\./\./;
  #     # perl -e 'my $test="test..x.y"; if($test =~ s/\.\./\./){print STDOUT "\n$test\n";}'
  #   }
  # }
  if( $output_zip ){
    my $tar_summary_dir_string = "tar -zcf $output_zip $summary_dir_base";
    system($tar_summary_dir_string)==0 or die "died running"."\n".$tar_summary_dir_string."\n";
  }
  
}









sub list_dir {
  
  my($dir_name, $list_pattern) = @_;
  
  opendir(DIR, $dir_name) or die "\n\n"."can't open DIR $dir_name"."\n\n";
  
  my @dir_files_list = grep /$list_pattern/, readdir DIR; 
  closedir DIR or die "can't close DIR";
  
  my @filtered_dir_files_list;
  while (my $dir_object = shift(@dir_files_list)) {
    $dir_object =~ s/^\.//;
    push(@filtered_dir_files_list, $dir_object);
    #print "DIR  ".$dir_name.$dir_object."\n";
  }
  
  return @filtered_dir_files_list;
  
}





# sub list_dir {
  
#   my($dir, $pattern) = @_;
  
#   #open(DIR_LIST, ">", $dir_list) or die "\n\n"."can't open DIR_LIST $dir_list"."\n\n";
#   opendir(DIR, $dir) or die "\n\n"."can't open DIR $dir_name"."\n\n";
  
#   my @dir_list = grep /$pattern/, readdir DIR; or die "\n\n"."can't read DIR $dir"."\n\n";
#   #print DIR_LIST join("\n", @dir_list); print DIR_LIST "\n";
#   closedir DIR;
#   return(@dir_list)
  
# }




sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
time stamp:           $start_time_stamp
script:               $0

USAGE:
compile_p-values-summary_files -d|--dir_path <dir path> -i|--input_pattern <input pattern> -o|--output_prefix <output prefix>

     -d|--dir_path        default = $current_dir
                          string - path for directory with files (default is current directory)

     -i|--input_pattern   default = $input_pattern
                          pattern or extension to match at the end of the files

     -o|--output_prefix   default = $output_pattern
                          prefix for the output files

     -s|--sort_output     sort output - PCoA image, PCoA flat files, individual Pvalue summaries are all placed in their own folders

     -z|--output_zip      default=$output_zip
                          requires -s|--sort_output
                          name for a zipped archive of the sorted output

     -u|--unzip           flag to unzip any *.tar.gz before proceeding

     -h|--help
     -v|--verbose
     -b|--debug

DESCRIPTION:
This script will produce summary outputs from multiple *.P_VALUES_SUMMARY files
produced from AMETHST.pl, or any of the individual scripts that it 
drives:

     plot_pco_with_stats,
     plot_qiime_pco_with_stats,
     plot_OTU_pco_with_stats, or
     plot_pco_with_stats_all

The script produces 5 output files that contain the:

     output_pattern.raw_avg_dist        # the raw average distances calculated for each within/between group analysis
     output_pattern.raw_avg_dist_stdev  # standard deviations for the raw average distances
     output_pattern.scaled_avg_dist     # average distances scaled from 0 to 1
     output_pattern.p_values            # p value for each within/between group average distance
     output_pattern.num_perm            # number of permutations used to generate the p values

The only argument is the path for the directory that contains the *.P_VALUES_SUMMARY
files. The default path is "./".
   
);
  exit 1;
}

# compile_p-values-summary_files.pl --output_zip='.$summary_name'
