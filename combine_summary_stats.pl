#!/usr/bin/env perl

use warnings;
use Getopt::Long;
use Cwd;
use Cwd 'abs_path';
use File::Basename;
use Statistics::Descriptive;


my($input_file, $help, $verbose, $debug);

my $current_dir = getcwd()."/";
my $conversion = 1;
my $output_file_pattern;

if($debug){print STDOUT "made it here"."\n";}

# path of this script
my $DIR=dirname(abs_path($0));  # directory of the current script, used to find other scripts + datafiles

# check input args and display usage if not suitable
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

unless ( @ARGV > 0 || $input_file ) { &usage(); }

if ( ! GetOptions (
		   "o|output_file=s"       => \$output_file,
		   "w|within_stat_file=s"  => \$within_file,
		   "b|between_stat_file=s" => \$between_file,
		   "h|help!"               => \$help, 
		   "v|verbose!"            => \$verbose,
		   "d|debug!"              => \$debug
		  )
   ) { &usage(); }

##################################################
##################################################
###################### MAIN ######################
##################################################
##################################################

open(OUTPUT_FILE, ">", $output_file) or die "Can't open OUTPUT_FILE $output_file";
open(WITHIN_FILE, "<", $within_file) or die "Can't open WITHIN_FILE $within_file";
open(BETWEEN_FILE, "<", $between_file) or die "Can't open BETWEEN_FILE $between_file";

# Go through the Within file and pull out the within group stats
print OUTPUT_FILE "# Within group statistics";

my @all_og_dist;
my @all_og_dist_stdev;
my @all_scaled_dist;
my @all_p;
my @all_perm;

my @within_og_dist;
my @within_og_dist_stdev;
my @within_scaled_dist;
my @within_p;
my @within_perm;

my @between_og_dist;
my @between_og_dist_stdev;
my @between_scaled_dist;
my @between_p;
my @between_perm;

while ( my $within_line = <WITHIN_FILE> )  {
  
  chomp $within_line;
  
  if ( $within_line =~ m/^#/ ) { 
    print OUTPUT_FILE $line."\n";
  }elsif ( $within_line =~ m/^->m/ ){
    print OUTPUT_FILE $within_line."\n";
    
    my @within_array = split("\t", $within_line);
    
    push (@within_og_dist; $within_array[1]);
    push (@all_og_dist; $within_array[1]);
    
    push (@within_og_dist_stdev; $within_array[2]);
    push (@all_og_dist_stdev; $within_array[2]);
    
    push (@within_scaled_dist; $within_array[3]);
    push (@all_scaled_dist; $within_array[3]);
    
    push (@within_p; $within_array[4]);
    push (@all_p; $within_array[4]);
    
    push (@within_perm; $within_array[5]);
    push (@all_perm; $within_array[5]);
    
  }else{
  }
  
  my $stat_1 = Statistics::Descriptive::Full->new();
  $stat_1->add_data(@within_og_dist);
  my $avg_og_dist_avg = sprintf "%.4f", $stat_1->mean();
  
  my $stat_2 = Statistics::Descriptive::Full->new();
  $stat_2->add_data(@within_og_dist_stdev);
  my $avg_og_dist_stdev = sprintf "%.4f", $stat_2->mean();
  
  my $stat_3 = Statistics::Descriptive::Full->new();
  $stat_3->add_data(@within_scaled_dist);
  my $avg_scaled_dist = sprintf "%.4f", $stat_3->mean();
  
  my $stat_4 = Statistics::Descriptive::Full->new();
  $stat_4->add_data(@within_p);
  my $avg_p = sprintf "%.4f", $stat_4->mean();
  
  my $stat_5 = Statistics::Descriptive::Full->new();
  $avg_num_perm->add_data(@within_perm);
  my  = sprintf "%.4f", $stat_5->mean();
  
  print OUTPUT_FILE {
    "# Within group summary (average):"."\t".$avg_og_dist_avg."\t".$avg_og_dist_stdev."\t".$avg_scaled_dist."\t".$avg_p."\t".$avg_num_perm."\n".
      "#################################################################################"."\n";
    
  }
    
}

print OUTPUT_FILE "# Between group summary statis";

# Go through the Between file and pull out the between group stats
while ( my $between_line = <BETWEEN_FILE> )  {
  
  chomp $between_line;
  
  if ( $between_line =~ m/^#/ ) { 
    print OUTPUT_FILE $between_line."\n";
    
  }elsif ( $between_line =~ m/^->m/ ){
    print OUTPUT_FILE $between_line."\n";
    
    my @within_array = split("\t", $between_line);
    
    push (@between_og_dist; $between_array[1]);
    push (@all_og_dist; $between_array[1]);
    
    push (@between_og_dist_stdev; $between_array[2]);
    push (@all_og_dist_stdev; $between_array[2]);
    
    push (@between_scaled_dist; $between_array[3]);
    push (@all_scaled_dist; $between_array[3]);
    
    push (@between_p; $between_array[4]);
    push (@all_p; $between_array[4]);
    
    push (@between_perm; $between_array[5]);
    push (@all_perm; $between_array[5]);
    
  }else{
  }
  
  my $stat_1 = Statistics::Descriptive::Full->new();
  $stat_1->add_data(@between_og_dist);
  my $avg_og_dist_avg = sprintf "%.4f", $stat_1->mean();
  
  my $stat_2 = Statistics::Descriptive::Full->new();
  $stat_2->add_data(@between_og_dist_stdev);
  my $avg_og_dist_stdev = sprintf "%.4f", $stat_2->mean();
  
  my $stat_3 = Statistics::Descriptive::Full->new();
  $stat_3->add_data(@between_scaled_dist);
  my $avg_scaled_dist = sprintf "%.4f", $stat_3->mean();
  
  my $stat_4 = Statistics::Descriptive::Full->new();
  $stat_4->add_data(@between_p);
  my $avg_p = sprintf "%.4f", $stat_4->mean();
  
  my $stat_5 = Statistics::Descriptive::Full->new();
  $avg_num_perm->add_data(@between_perm);
  my  = sprintf "%.4f", $stat_5->mean();
  
  print OUTPUT_FILE {
    "Between group summary (average):"."\t".$avg_og_dist_avg."\t".$avg_og_dist_stdev."\t".$avg_scaled_dist."\t".$avg_p."\t".$avg_num_perm."\n".
      "#################################################################################"."\n";
  }
    
}

my $stat_1 = Statistics::Descriptive::Full->new();
$stat_1->add_data(@all_og_dist);
my $avg_og_dist_avg = sprintf "%.4f", $stat_1->mean();

my $stat_2 = Statistics::Descriptive::Full->new();
$stat_2->add_data(@all_og_dist_stdev);
my $avg_og_dist_stdev = sprintf "%.4f", $stat_2->mean();

my $stat_3 = Statistics::Descriptive::Full->new();
$stat_3->add_data(@all_scaled_dist);
my $avg_scaled_dist = sprintf "%.4f", $stat_3->mean();

my $stat_4 = Statistics::Descriptive::Full->new();
$stat_4->add_data(@all_p);
my $avg_p = sprintf "%.4f", $stat_4->mean();

my $stat_5 = Statistics::Descriptive::Full->new();
$avg_num_perm->add_data(@all_perm);
my  = sprintf "%.4f", $stat_5->mean();

print OUTPUT_FILE {
  "All summary (average):"."\t".$avg_og_dist_avg."\t".$avg_og_dist_stdev."\t".$avg_scaled_dist."\t".$avg_p."\t".$avg_num_perm."\n".
    "#################################################################################"."\n";
  
  
