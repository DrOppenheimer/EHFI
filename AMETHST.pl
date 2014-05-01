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
chomp $start_time_stamp;
my ($command_file, $zip_prefix, $debug, $help);


my $qiime_activate_script = "/home/ubuntu/qiime_software/activate.sh";
my $r_path = "/usr/bin";
my $amethst_path = "/home/ubuntu/AMETHST";

# Check to make sure that the hard coded files and paths above actually exist
unless (-e $qiime_activate_script) {
 print STDOUT "The specified qiime activate script:\n$qiime_activate_script\ndoes not exist.\nPlease specify a qiime activations script that exists\n";
 exit 1;
 } 

unless (-d $r_path ){
print STDOUT "The specified path for R:\n$r_path\ndoes not exist.\nPlease specify a valid R path";
exit 1;
}

unless (-d $amethst_path ){
print STDOUT "The specified path for AMETHST:\n$amethst_path\ndoes not exist.\nPlease specify a valid AMETHST path";
exit 1;
}


# get path information from the qiime activations script
open(QIIME_ACTIVATION, "<", $qiime_activate_script) or die "can't open QIIME_ACTIVATION $qiime_activate_script"."\n"; 
while (my $line = <QIIME_ACTIVATION>){
  if ($line =~ s/^export PATH=//){
    $line =~ s/PATH//;
      local $ENV{PATH} = "$ENV{PATH}:$line";
  }  
}
# add the R and AMETHST path information
local $ENV{PATH} = "$ENV{PATH}:$r_path:$amethst_path";
#if ($debug){ print STDOUT "PATH:\n".$ENV{PATH}."\n"; }

if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); exit 0; }

unless ( @ARGV > 0 || $command_file ) { &usage(); exit 1;}

if ( ! GetOptions (
		   "f|command_file=s"          => \$command_file,
		   "q|qiime_activate_script=s" => \$qiime_activate_script,
		   "r|r_path=s"                => \$r_path,
		   "a|amethst_path=s"          => \$amethst_path,          
		   "z|zip_prefix!"             => \$zip_prefix,
		   "h|help!"                   => \$help,
		   "d|debug!"                  => \$debug
		  )
   ) { &usage(); exit 1; }

$command_file = basename($command_file);
my $current_dir = getcwd()."/";
my $script_dir = "$FindBin::Bin/";
my $path_file = $current_dir.$command_file;
#my $log_file = $current_dir.$command_file.".MASTER.log";
my $log_prefix = "my_log";

my $job_counter = 1;
my $log_file = $current_dir.$command_file.".".$start_time_stamp.".log";

open(LOG, ">", $log_file) or die "cant open LOG $log_file"."\n";
print LOG "Start: ".$start_time_stamp."\n";


# try to detect the number of CPUS
my $num_cpus=`nproc`;
unless($num_cpus){
  print LOG "Can't detect number of CPUS with nproc, using a single cpu"."\n\n";
  $num_cpus=1;
}else{
  print LOG "Detected ".$num_cpus." CPUS, using all but one of them"."\n\n";
  chomp $num_cpus;
  $num_cpus=$num_cpus-1;
}

open(FILE, "<", $path_file) or die "can't open FILE $path_file"."\n"; 

while (my $line = <FILE>){

  chomp $line;
  
  # skip lines that start with # or are blank
  unless ( ($line =~ m/^#/) || ($line =~ m/^\s*$/) ){
    
  }else{
    
    if( $line =~ s/^#job// ){
      chomp $line;
      $line =~ s/\s+//g;
      $log_prefix = $line;
    
      print LOG "START Job: name(".$log_prefix.") number(".$job_counter.") at".`date +%m-%d-%y_%H:%M:%S`."\n";
      
      #my $cmd1 = $script_dir."plot_pco_with_stats_all.pl ".<FILE>;
      my $cmd1 = $script_dir.<FILE>;
      chomp $cmd1;
      $cmd1 = $cmd1." --job_name $log_prefix --num_cpus $num_cpus";
      print LOG $cmd1."\n"."...";
      system($cmd1)==0 or die "died running command:"."\n".$cmd1."\n";
      print LOG "DONE"."\n\n";

      #my $cmd2 = $script_dir."plot_pco_with_stats_all.pl ".<FILE>;
      my $cmd2 = $script_dir.<FILE>;
      chomp $cmd2;
      $cmd2 = $cmd2." --job_name $log_prefix --num_cpus $num_cpus";
      print LOG $cmd2."\n"."...";
      system($cmd2)==0 or die "died running command:"."\n".$cmd2."\n";
      print LOG "DONE"."\n\n";

      #my $sum_cmd = $script_dir."combine_summary_stats.pl ".<FILE>;
      my $sum_cmd = $script_dir.<FILE>;
      chomp $sum_cmd;
      $sum_cmd = $sum_cmd." --log_file $log_file --job_name $log_prefix --output_file $log_prefix.P_VALUE_SUMMARY";
      print LOG $sum_cmd."\n"."...";
      system($sum_cmd)==0 or die "died running command:"."\n".$sum_cmd."\n";
      print LOG "DONE"."\n\n";

      print LOG "FINISH Job: name(".$log_prefix.") number(".$job_counter.") at ".`date +%m-%d-%y_%H:%M:%S`."\n";

      $job_counter++;

    }

 }
  
}

### THIS NEEDS TO BE MOVED UP INTO THE PAIR ANALYSIS LOOP -- or added to workflow after all ...
# tar the entire directory if the -z option is used
if ( $zip_prefix ){
  my $output_name = $log_prefix.".RESULTS.tar.gz";
  # can make this list more selective in the future - for now, just gets everything in the directory
  system("ls > file_list.txt")==0 or die "died writing file_list.txt";  
  system("sed '/file_list.txt/d' file_list.txt > edited_list.txt")==0 or die "died on sed of file_list.txt";
  system("tar -zcf $output_name -T edited_list.txt")==0 or die "died on tar of files in file_list.txt";
}


print LOG "\n"."ALL DONE at ".`date +%m-%d-%y_%H:%M:%S`."\n";
close(LOG);






sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
time stamp:           $start_time_stamp
script:               $0

USAGE:
     AMETHST.pl -f command_file [options]

    -f|--command_file           (string)    no default,
                                            name of the file with commands

    -q|--qiime_activate_script  (string)    default: $qiime_activate_script
                                            indicates absolute path and filename for qiime activate script
    
    -r|--r_path                 (string)    default: $r_path
                                            indicates the absolute path for r (should not be qiime installed r)

    -a|--amethst_path           (string)    default: $amethst_path
                                            indicates the absolute path for AMETHST (i.e. the git repo directory)

    -z|--zip_prefix             (bool)      default is off, 
                                            create a *.tar.gz that contains all data (input and output)    

    -h|--help                   (bool)      default is off,
                                            display help/usage

    -d|--debug                  (bool)      default is off,
                                            run in debug mode

DESCRIPTION:
Driver script for AMETHST analysis

);
  # exit 1;
}
