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

my $start_time_stamp =`date +%m-%d-%y_%H:%M:%S`;  # create the time stamp month-day-year_hour:min:sec:nanosec
my ($command_file, $debug, $help);

if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

unless ( @ARGV > 0 || $command_file ) { &usage(); }

if ( ! GetOptions (
		   "f|command_file=s" => \$command_file
		  )
   ) { &usage(); }

my $current_dir = getcwd()."/";
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

    print LOG "Start Command_".$job_counter."( ".$log_prefix." ) at ".`date +%m-%d-%y_%H:%M:%S`.$line."\n";
    my $job_log = $current_dir.$command_file.".".$log_prefix.".command_".$job_counter.".error_log";
    
    if($debug){
      print("MADE IT HERE (0)"."\n");
      $line = $line." 2>$job_log";
      print("\n"."LINE:"."\n".$line."\n\n");
    }

    $line = $line." 2>$job_log";

    my @command_args;
    push (@command_args, "2>$job_log");
    if($debug){print("MADE IT HERE (1)"."\n");}
    #system($line, @command_args);
    system($line);
    if($debug){print("MADE IT HERE (2)"."\n");}
    print LOG "Finish Command_".$job_counter." at ".`date +%m-%d-%y_%H:%M:%S`."\n";
    if($debug){print("MADE IT HERE (3)"."\n");}
    $job_counter++;
    
  }else{
    
    print LOG "\n".$line."\n\n";
    
    # check lines that start with # to see if they start with #job, in which case, following text in line is used for logging
    if( $line =~ s/#job// ){
      $line =~ s/\s+//g;
      $log_prefix = $line;
    }

 }
  
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
plot_pco_with_stats.MASTER...  --command_file COMMAND_FILE

DESCRIPTION:
This a master script that allows you to queue jobs for the following three scripts:

     plot_pco_with_stats,
     plot_qiime_pco_with_stats,
     plot_OTU_pco_with_stats, or
     plot_pco_with_stats_all

The only argument is the name of the file that has the commands to run these scripts.
Command file has to have each job in a single line.
Format is 
"--option value --option value ... --flag"

It will generate a master log that tells you when each job started and completed.
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

EXAMPLE:
#job Analysis_1
~/AMETHST/plot_pco_with_stats_all.3-4-13.pl -f 1.MG-RAST.MG-RAST_default.removed.raw -g AMETHST.groups -p 10 -t dataset_rand -m bray-curtis -z MG-RAST_pipe -c 10 -o Analysis_1w -cleanup
~/AMETHST/plot_pco_with_stats_all.3-4-13.pl -f 1.MG-RAST.MG-RAST_default.removed.raw  -g AMETHST.groups -p 10 -t rowwise_rand -m bray-curtis -z MG-RAST_pipe -c 10 -o Analysis_1b -cleanup
~/AMETHST/combine_summary_stats.pl  -m pattern  -w Analysis_9w  -b Analysis_9b  -o Analysis_1.P_VALUE_SUMMARY


#job Analysis_2
~/AMETHST/plot_pco_with_stats_all.3-4-13.pl -f 9.Qiime.Qiime_default.removed.raw -g AMETHST.groups -p 10 -t dataset_rand -m unifrac -z qiime_pipe  -q qiime_table  -a ~/AMETHST/qiime_trees/97_otus.tree -c 10 -o Analysis_2w -cleanup
~/AMETHST/plot_pco_with_stats_all.3-4-13.pl -f 9.Qiime.Qiime_default.removed.raw  -g AMETHST.groups -p 10 -t rowwise_rand -m unifrac -z qiime_pipe  -q qiime_table  -a ~/AMETHST/qiime_trees/97_otus.tree -c 10 -o Analysis_2b -cleanup
~/AMETHST/combine_summary_stats.pl  -m pattern  -w Analysis_2w  -b Analysis_2b  -o Analysis_2.P_VALUE_SUMMARY


USAGE:

    -f|--command_file (string)  no default
                                  
An array of typical options (indicating defaults) for each of the drive scripts is
provided below.  Note that each takes nearly, but not exactly, the same arguments.
The QIIME one has the most unique arguments.



);
  exit 1;
}
