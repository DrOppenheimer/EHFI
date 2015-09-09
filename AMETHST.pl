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
my ($command_file, $compile_summary, $awe_compile_summary, $compile_all, $debug, $help);

# Set option defaults
my $summary_name = "AMETHST.Summary";
my $all_name = "AMETHST.All_data";
my $qiime_activate_script = "na"; #"/home/ubuntu/qiime_software/activate.sh";
my $r_path = "/usr/bin";
my $amethst_path = "/home/ubuntu/AMETHST";

if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); exit 0; }

unless ( @ARGV > 0 || $command_file || $awe_compile_summary) { &usage(); exit 1;}

if ( ! GetOptions (
		   "f|command_file=s"          => \$command_file,
		   "q|qiime_activate_script=s" => \$qiime_activate_script,
		   "r|r_path=s"                => \$r_path,
		   "a|amethst_path=s"          => \$amethst_path,          
		   
		   "c|awe_compile_summary!"    => \$awe_compile_summary,

		   "k|compile_summary!"        => \$compile_summary,  
		   "m|summary_name=s"          => \$summary_name,
		   
		   "z|zip_all!"                => \$zip_all,
		   "n|all_name=s"              => \$all_name,

		   "h|help!"                   => \$help,
		   "d|debug!"                  => \$debug
		  )
   ) { &usage(); exit 1; }

# Check to make sure that summary and all file names are unique
if ( $summary_name eq $all_name){
  print STDOUT "-m|--summary_name: ".$summary_name."\n"."and -n|--all_name: ".$all_name." must be unique, please try again";
  exit 1;
}else{
  # make sure potential output names are appended with correct extensions
  unless( $summary_name =~ m/\.tar\.gz$/ ){ $summary_name=$summary_name.".tar.gz"; }
  unless( $all_name =~ m/\.tar\.gz$/ ){ $all_name=$all_name.".tar.gz"; }

}

# Check to make sure that the hard coded files and paths above actually exist
#unless (-e $qiime_activate_script) {

# Conditional on qiime_activate_script na
unless ( $qiime_activate_script eq "na" ){
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

# Add qiime pathing information by indirectly sourcing the activate script --
# i.e. read each "export" line and use it to create an envrionment variable for the perl session
# place old environment in a variable, is added back to end of Qiime based PATH

# conditional on qiime_activate_script na
unless ( $qiime_activate_script eq "na" ){
  my $original_path = $ENV{PATH}; chomp $original_path;
  open(QIIME_ACTIVATION, "<", $qiime_activate_script) or die "can't open QIIME_ACTIVATION $qiime_activate_script"."\n"; 
  while (my $line = <QIIME_ACTIVATION>){
    if ($line =~ s/^export //){ # identify "export" lines and trim "export " from the line
      chomp $line;
      $line =~ s/\s\s+/ /g; # get rid of any whitespace
      my @line_array=split("=",$line); # split the line
      my $var_name=$line_array[0]; # first entry is the variable name
      my $var_value=$line_array[1]; # second entry is the variable value
      #print STDOUT "\n"."var:"."\t".$var_name."\n"."var_value:"."\t".$var_value."\n\n"; # ENV debugging
      $ENV{$var_name} = "$var_value"; # load the variables into perls environment variable hash   
    }  
  }
}

# Add the R and AMETHST path information to beginning of path # also add /bin, which is overwritten 7-7-14
$ENV{PATH} = "$amethst_path:$r_path:$ENV{PATH}:$original_path";
## add original path to the end of the modified path
## $ENV{PATH} = "$ENV{PATH}:$original_path";
print STDOUT "THIS_IS_MY_PATH"."\n".$ENV{PATH}."\n";

my $current_dir = getcwd()."/";

########### Run if -c option (AWE summary) is invoked ###########
if ($awe_compile_summary){

  # unzip tarred data if it's there
  my @tar_zip_files = glob "$current_dir*.tar.gz";
  if( scalar(@tar_zip_files) > 0 ){ 
    system('for i in *tar.gz; do tar -zxf $i; done')==0 or die "died unzipping *.tar.gz listed in tar_list.txt"; 
  }  
  ## my @files = glob "$dir/*.txt";
  ## for (0..$#files){
  ##   $files[$_] =~ s/\.txt$//;
  ## }

  # compile the data
  my $compile_summary_string = "compile_p-values-summary_files.pl --sort_output --output_zip=$summary_name";
  #print LOG "\n\n"."Running compile_p-values-summary_files.pl:"."\n".$compile_summary_string."\n"; 
  system($compile_summary_string)==0 or die "dies running:"."\n".$compile_summary_string."\n" ;
#################################################################  
}else{

  ######### PERFORM AMETHST ANALYSIS ###########

  # define some variables from the commands file
  $command_file = basename($command_file);
  my $script_dir = "$FindBin::RealBin/";
  my $path_file = $current_dir.$command_file;
  #my $log_file = $current_dir.$command_file.".MASTER.log";
  my $log_prefix = "my_log";  
  my $job_counter = 1;
  my $log_file = $current_dir.$command_file.".".$start_time_stamp.".log";
  
  # Open the log for printing
  open(LOG, ">", $log_file) or die "cant open LOG $log_file"."\n";
  print LOG "Start: ".$start_time_stamp."\n";

  # try to detect the number of CPUS
  my $num_cpus=`nproc`;
  unless($num_cpus){
    print LOG "Can't detect number of CPUS with nproc, using a single cpu"."\n\n";
    $num_cpus=1;
  }else{
    #chomp $num_cpus
    $num_cpus =~ s/\R//g;
    print LOG "Detected ".$num_cpus." CPUS, using all but one of them"."\n\n";
    $num_cpus=$num_cpus-1;
  }

  # process through the commands file
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

  # Option to run compile_p-values-summary_files.pl - results are placed in an archive
  if ( $compile_summary ){
    my $compile_summary_string = "compile_p-values-summary_files.pl --sort_output --output_zip=$summary_name";
    print LOG "\n\n"."Running compile_p-values-summary_files.pl:"."\n".$compile_summary_string."\n"; 
    system($compile_summary_string)==0 or die "dies running:"."\n".$compile_summary_string."\n" ;
  }
    
  # Option to place all data - input and output into a single *.tar.gz
  if ( $zip_all ){
    print LOG "\n"."Creating archive of all input and output data: ".$all_name."\n";
    my $all_name = $all_name;
    # can make this list more selective in the future - for now, just gets everything in the directory
    system("ls > file_list.txt")==0 or die "died writing file_list.txt";  
    system("sed '/file_list.txt/d' file_list.txt > edited_list.txt")==0 or die "died on sed of file_list.txt";
    system("tar -zcf $all_name -T edited_list.txt")==0 or die "died on tar of files in file_list.txt";
  }
  
  print LOG "\n"."ALL DONE at ".`date +%m-%d-%y_%H:%M:%S`."\n";
  close(LOG);
  
}




sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
time stamp:           $start_time_stamp
script:               $0

USAGE:
     There are two usages - for the perl and AWE versions:

     (1) AMETHST.pl -f command_file [options]

     (2) AMETHST.pl -c --summary_name MY_SUMMARY_FILENAME


     (1) Can be used to perform analysis and summarize all in one step (for the perl stand alone version or the AWE service)
     (2) Can be used to produce a summary for a complete anlaysis (for use with the AWE service)


    -f|--command_file           (string)    no default,
                                            name of the file with commands

    -q|--qiime_activate_script  (string)    default: $qiime_activate_script
                                            indicates absolute path and filename for qiime activate script
    
    -r|--r_path                 (string)    default: $r_path
                                            indicates the absolute path for r (should not be qiime installed r)

    -a|--amethst_path           (string)    default: $amethst_path
                                            indicates the absolute path for AMETHST (i.e. the git repo directory)

    -c|--awe_compile_summary    (bool)      default is off
                                            for use with AWE execution of AMETHST.pl only (not as stand alone with perl)
                                            used with the -m|--summary_name option to create a *.tar.gz of summary

    -k|--compile_summary        (bool)      default is off (use with -m|--summary_name)
                                            for use with perl execution of AMETHST.pl only (not the AWE version)
                                            runs the compile_p-values-summary_files.pl script to create a summary of all analyses
                                            for use with perl execution of AMETHST.pl only (not the AWE version)
                                            used with the -m|--summary_name option to create a *.tar.gz of summary

    -m|--summary_name           (string)    default: $summary_name
					    requires -c|--awe_compile_summary or -k|--compile_summary
                                            name for the archive that contains the summary, appended with .tar.gz

    -z|--zip_all                (bool)      default is off (use with -n|all_name)
                                            for use with perl execution of AMETHST.pl only (not the AWE version)
                                            create a tar.gz that contains all inputs and outputs
                                            
    -n|--all_name               (string)    default: $all_name
                                            for use with perl execution of AMETHST.pl only (not the AWE version)
                                            requires -z|--zip_all
                                            name for the archive created by -z|--zip_all, appended with .tar.gz
                                            						
						
    -h|--help                   (bool)      default is off,
                                            display help/usage

    -d|--debug                  (bool)      default is off,
                                            run in debug mode

DESCRIPTION:
Driver script for AMETHST analysis, for use in stand along perl installations
or as part of the AWE AMETHST service.

Typical local (stand alone) perl usage (script is executed just once)

     AMETHST.pl -f test_analysis_commands -k --summary_name MY_SUMMARY

Typical AWE service usage (script -is executed twice)
NOTE: These steps are automated in the service version, i.e. you should 
not use this method for running AMETHST locally.

     AMETHST.pl -f test_analysis_commands
     AMETHST.pl -c --summary_name MY_SUMMARY

);
  # exit 1;
}
