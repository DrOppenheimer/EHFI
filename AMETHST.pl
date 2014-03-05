#!/usr/bin/env perl

# This is a driver script that uses the following perl scripts:
# plot_pco_with_stats,
# plot_qiime_pco_with_stats, or
# plot_OTU_pco_with_stats
#
# It runs these sequntially based on arguments in a list 

use warnings;
use Getopt::Long;
use Cwd;
use File::Basename;
use FindBin;

my $start_time_stamp =`date +%m-%d-%y_%H:%M:%S`;  # create the time stamp month-day-year_hour:min:sec:nanosec
my ($command_file, $zip_prefix, $debug, $help);

if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

unless ( @ARGV > 0 || $command_file ) { &usage(); }

if ( ! GetOptions (
		   "f|command_file=s" => \$command_file,
		   "z|zip_prefix!"    => \$zip_prefix,
		   "h|help!"          => \$help,
		   "d|debug!"         => \$debug
		  )
   ) { &usage(); }

$command_file = basename($command_file);
my $current_dir = getcwd()."/";
my $script_dir = "$FindBin::Bin/";
my $path_file = $current_dir.$command_file;
my $log_file = $current_dir.$command_file.".MASTER.log";
my $log_prefix = "my_log";

open(LOG, ">", $log_file) or die "cant open LOG $log_file"."\n";
print LOG "Start: ".$start_time_stamp."\n\n";

my $job_counter = 1;

open(FILE, "<", $path_file) or die "can't open FILE $path_file"."\n"; 

while (my $line = <FILE>){

  chomp $line;
  
  # skip lines that start with # or are blank
  unless ( ($line =~ m/^#/) || ($line =~ m/^\s*$/) ){

    # print LOG "Start Command_".$job_counter."( ".$log_prefix." ) at ".`date +%m-%d-%y_%H:%M:%S`.$line."\n";
    # my $job_log = $current_dir.$command_file.".".$log_prefix.".command_".$job_counter.".error_log";
    
    # if($debug){
    #   print("MADE IT HERE (0)"."\n");
    #   $line = $line." 2>$job_log";
    #   print("\n"."LINE:"."\n".$line."\n\n");
    # }

    # $line = $line." 2>$job_log";

    # my @command_args;
    # push (@command_args, "2>$job_log");
    # if($debug){print("MADE IT HERE (1)"."\n");}
    # #system($line, @command_args);
    # system($line);
    # if($debug){print("MADE IT HERE (2)"."\n");}
    # print LOG "Finish Command_".$job_counter." at ".`date +%m-%d-%y_%H:%M:%S`."\n";
    # if($debug){print("MADE IT HERE (3)"."\n");}
    # $job_counter++;
    
  }else{
    
    # check lines that start with # to see if they start with #job, in which case, following text in line is used for logging
    if( $line =~ s/#job// ){
      $line =~ s/\s+//g;
      $log_prefix = $line;
    
      print LOG "START Job: name(".$log_prefix.") number(".$job_counter.") at".`date +%m-%d-%y_%H:%M:%S`;
      
      my $cmd1 = $script_dir."plot_pco_with_stats_all.pl ".<FILE>;
      chomp $cmd1;
      system($cmd1);
      print LOG $cmd1."\n"."DONE"."\n";

      my $cmd2 = $script_dir."plot_pco_with_stats_all.pl ".<FILE>;
      chomp $cmd2;
      system($cmd2);
      print LOG $cmd2."\n"."DONE"."\n";

      my $sum_cmd = $script_dir."combine_summary_stats.pl ".<FILE>. " -o $log_prefix.P_VALUE_SUMMARY";
      chomp $sum_cmd;
      system($sum_cmd);
      print LOG $sum_cmd."\n"."DONE"."\n";

      print LOG "FINISH Job: name(".$log_prefix.") number(".$job_counter.") at ".`date +%m-%d-%y_%H:%M:%S`;

      $job_counter++;

    }

 }
  
}

# tar the entire directory if the -z option is used
if ( $zip_prefix ){
  my $output_name = $log_prefix.".RESULTS.tar.gz";
  # can make this list more selective in the future - for now, just gets everything in the directory
  system("ls > file_list.txt");  
  system("sed '/file_list.txt/d' file_list.txt > edited_list.txt");
  system("tar -zcf $output_name -T edited_list.txt");
}


print LOG "\n"."ALL DONE at ".`date +%m-%d-%y_%H:%M:%S`."\n";








sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
time stamp:           $start_time_stamp
script:               $0

USAGE:
     AMETHST.py -f commands_file [options]

    -f|--command_file (string)    no default
    -z|--zip_prefix   (bool)      create a *.tar.gz that contains all data (input and output)
    -h|--help         (bool)      display help/usage
    -d|--debug        (bool)      run in debug mode

DESCRIPTION:
This a master script that allows you to queue jobs for the following three scripts:

     plot_pco_with_stats,
     plot_qiime_pco_with_stats,
     plot_OTU_pco_with_stats, or
     plot_pco_with_stats_all

There are two main arguments.  One (required) specifies the file with he list of commands to 
perform.  The second is optional; the user can specify the prefix for a zip file to be cerated
that will contain all inputs and outputs

The script generates a master log that tells you when each job started and completed.
It also creates a log for each job that records all of the error output text.
Note that the plot... scripts also generate their own logs.

The file with the commands must be formatted as follows

#job "unique name or job for job" 
command line 1 for job
command line 2 for job   
command line 3 for job

#job "unique name or job for job" 
command line 1 for job
command line 2 for job   
command line 3 for job

EXAMPLES:
#job Analysis_1
-f 1.MG-RAST.MG-RAST_default.removed.raw -g AMETHST.groups -p 10 -t dataset_rand -m bray-curtis -z MG-RAST_pipe -c 10 -o Analysis_1w -cleanup
-f 1.MG-RAST.MG-RAST_default.removed.raw  -g AMETHST.groups -p 10 -t rowwise_rand -m bray-curtis -z MG-RAST_pipe -c 10 -o Analysis_1b -cleanup
-m pattern  -w Analysis_9w  -b Analysis_9b  -o Analysis_1.P_VALUE_SUMMARY

#job Analysis_2
-f 9.Qiime.Qiime_default.removed.raw -g AMETHST.groups -p 10 -t dataset_rand -m unifrac -z qiime_pipe  -q qiime_table  -a ~/AMETHST/qiime_trees/97_otus.tree -c 10 -o Analysis_2w -cleanup
-f 9.Qiime.Qiime_default.removed.raw  -g AMETHST.groups -p 10 -t rowwise_rand -m unifrac -z qiime_pipe  -q qiime_table  -a ~/AMETHST/qiime_trees/97_otus.tree -c 10 -o Analysis_2b -cleanup
-m pattern  -w Analysis_2w  -b Analysis_2b  -o Analysis_2.P_VALUE_SUMMARY


);
  exit 1;
}
