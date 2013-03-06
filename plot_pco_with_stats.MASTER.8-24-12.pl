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

open(LOG, ">", $log_file) or die "cant open LOG $log_file"."\n";
print LOG "Start: ".$start_time_stamp."\n\n";

my $job_counter = 1;

open(FILE, "<", $path_file) or die "can't open FILE $path_file"."\n"; 

while (my $line = <FILE>){


  

  chomp $line;
  unless ( ($line =~ m/^#/) || ($line =~ m/^\s*$/) ){


    ##### added Oct 9 2012 # try 
    #if ($line =~ m/^>/){
    #  
    #}
    #####

    print LOG "Start Job_".$job_counter." at ".`date +%m-%d-%y_%H:%M:%S`."\n".$line."\n";
    my $job_log = $current_dir.$command_file.".job_".$job_counter.".error_log";
    
    if($debug){
      print("MADE IT HERE (0)"."\n");
      $line = $line." 2>$job_log";
      print("\n"."LINE:"."\n".$line."\n\n");
    }

    $line = $line." 2>$job_log";

    my @command_args;
    push (@command_args, "2> $job_log");
    if($debug){print("MADE IT HERE (1)"."\n");}
    #system($line, @command_args);
    system($line);
    if($debug){print("MADE IT HERE (2)"."\n");}
    print LOG "\n"."Finish Job_".$job_counter." at ".`date +%m-%d-%y_%H:%M:%S`."\n"."\n";
    if($debug){print("MADE IT HERE (3)"."\n");}
    $job_counter++;
    
  }
  

}







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
     plot_qiime_pco_with_stats, or
     plot_OTU_pco_with_stats

The only argument is the name of the file that has the commands to run these scripts.
Command file has to have each job in a single line.
Format is 
"--option value --option value ... --flag"

It will generate a master log that tells you when each job started and completed.
It also creates a log for each job that records all of the error output text.
Note that the plot... scripts also generate their own logs.
   
USAGE:
    -f|--command_file (string)  no default
                                  
An array of typical options (indicating defaults) for each of the drive scripts is
provided below.  Note that each takes nearly, but not exactly, the same arguments.
The QIIME one has the most unique arguments.



);
  exit 1;
}





# for 


# open(FILE_IN, "<", $fastas_dir."/".$ID_A_T_C_G_N_Length_file) or die "Couldn't open file FILE_IN $fastas_dir."/".$ID_A_T_C_G_N_Length_file"."\n";  
# 	    my $num_reads = 0;
# 	    my @read_lengths;
	  
# 	    while (my $line_input = <FILE_IN>){      







# my($data_file, $dist_method, $cleanup, $help, $verbose, $debug);

# my $current_dir = getcwd()."/";
# if($debug) { print STDOUT "current_dir: "."\t".$current_dir."\n";}

# #define defaults for variables that need & have them
# my $groups_list                = "groups_list";
# my $headers                    = 1;
# my $num_cpus                   = 10;
# my $num_perm                   = 1000;
# my $perm_type                  = "sample_rand";
# my $print_dist                 = 1;
# my $tree                       = "/home/ubuntu/qiime/gg_otus-4feb2011-release/trees/gg_97_otus_4feb2011.tre"; # This is the path on Travis' Magellan image
# my $output_DIST_dir            = $current_dir."DISTs/";
# my $output_PCoA_dir            = $current_dir."PCoAs/";
# my $perm_dir                   = $current_dir."permutations/";
# my $permutations_data_dir      = $permutations_data_dir = "./PERMs/";
# my $permutations_dists_dir     = $permutations_dists_dir = "./PERM_DISTs/";
# my $permutations_avg_DISTs_dir = $permutations_avg_DISTs_dir = "./AVG_DISTs/"

# # check input args and display usage if not suitable
# if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

# unless ( @ARGV > 0 || $data_file &&  $groups_list ) { &usage(); }

# if ( ! GetOptions (

# 		   "data_file=s"                   =>$data_file,
# 		   "dist_method=s"                 =>$dist_method,
# 		   "groups_list=s"                 =>$groups_list,
# 		   "headers=i"                     =>$headers,
# 		   "num_cpus=i"                    =>$num_cpus,
# 		   "num_perm=i"                    =>$num_perm,
# 		   "perm_type=s"                   =>$perm_type,
# 		   "print_dist=i"                  =>$print_dist,
# 		   "tree=s"                        =>$tree,
# 		   "output_DIST_dir=s"             =>$output_DIST_dir,
# 		   "output_PCoA_dir=s"             =>$output_PCoA_dir,
# 		   "perm_dir=s"                    =>$perm_dir,
# 		   "permutations_data_dir=s"       =>$permutations_data_dir,
# 		   "permutations_dists_dir=s"      =>$permutations_dists_dir,
# 		   "permutations_avg_DISTs_dir=s"  =>$permutations_avg_DISTs_dir,
# 		   "cleanup!"                      =>$cleanup,
# 		   "debug!"                        =>$debug,
# 		   "help!"                         =>$help,
# 		   "verbose!"                      =>$verbose 

# 		  )
#    ) { &usage(); }
