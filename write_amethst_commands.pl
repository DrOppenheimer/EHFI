#!/usr/bin/env perl

use warnings;
use Getopt::Long;
use Cwd;
#use Cwd 'abs_path';
use FindBin;
use File::Basename;
#use Statistics::Descriptive;

my($file_out, $help, $verbose, $debug);

$file_out="amethst_commands";
my $current_dir = getcwd()."/";

#if($debug){print STDOUT "made it here"."\n";}

# path of this script
# my $DIR=dirname(abs_path($0));  # directory of the current script, used to find other scripts + datafiles
my $DIR="$FindBin::Bin/";

# check input args and display usage if not suitable
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

if ( ! GetOptions (
		   "i|file_in=s" => \$file_in,
		   "o|file_out=s"         => \$file_out,
		   "h|help!"              => \$help, 
		   "v|verbose!"           => \$verbose,
		   "d|debug!"             => \$debug
		  )
   ) { &usage(); }

unless ( @ARGV > 0 || $file_in ) { &usage(); }
if( $help ){ &usage(); }

open(FILE_IN, "<", $file_in) or die "Can't open FILE_IN $file_in";
open(FILE_IN_TEMP, ">", $file_in.".tmp") or die "Can't open FILE_IN_TEMP ".$file_in.".tmp";
open(FILE_OUT, ">", $file_out) or die "Can't open FILE_OUT $file_out";

# fix wacky line terminators if they are there - likely if file was created with Excel
while (my $line = <FILE_IN>){          
  $line =~ s/\r\n|\n\r|\n|\r/\n/g;  #get rid of the line ends that are there
  print FILE_IN_TEMP $line; #replace them with \n
}
close(FILE_IN);
#unlink($file_in) or die ": $!"
rename($file_in.".tmp", $file_in) or die "Could not rename ".$file_in.".tmp to ".$file_in.": $!";
close(FILE_IN_TEMP);


if($debug){print "\nHELLO.1\n"}


open(FILE_IN, "<", $file_in) or die "Can't open FILE_IN $file_in";
while ( my $line = <FILE_IN> )  {
  
  if($debug){print "\nHELLO.2\n".$line."\n"}
  

  unless ( $line =~ m/^#/ || $line =~ m/^\s*$/ ){

    if($debug){print "\nHELLO.3\n"}

    my @split_line = split("\t",$line);

    my $num_fields = scalar(@split_line)


    if ($debug){ print "\nnum_fields: ".scalar(@split_line)."\n" }

    if ( scalar(@split_line) < 7 || scalar(@split_line) > 8){ die "input line does not have correct number of fields (7 or 8) \n#job_name\t#data_file\t# groups_list\t# num_perm\t# dist_method\t# dist_pipe\t#output_prefix\t#tree(optional)\n\nFILE:\n".$line."\n" }

    my $job_name = $split_line[0];
    my $data_file = $split_line[1];
    my $groups_list = $split_line[2];
    my $num_perm = $split_line[3];
    my $dist_method = $split_line[4];
    my $dist_pipe = $split_line[5];
    my $output_prefix = $split_line[6];
    if($num_fields==7){
      my $tree_name = $split_line[7];
    }


    if($debug){print "job:".$job_name."\n";}
    
    my $file_out_line1 = "#job ".$job_name."\n";

    if($debug){print "\nline_1".$file_out_line1."\n";}

    if($num_fields==7){
      my $file_out_line2 = "plot_pco_with_stats_all.pl --data_file ".$data_file." --sig_if lt --groups_list ".$groups_list." --num_perm ".$num_perm." --perm_type dataset_rand --dist_method ".$dist_method." --dist_pipe ".$dist_pipe." --output_prefix ".$job_name."_w"." --cleanup"."\n";
      my $file_out_line3 = "plot_pco_with_stats_all.pl --data_file ".$data_file." --sig_if gt --groups_list ".$groups_list." --num_perm ".$num_perm." --perm_type rowwise_rand --dist_method ".$dist_method." --dist_pipe ".$dist_pipe." --output_prefix ".$job_name."_b"." --cleanup"."\n";
      my $file_out_line4 = "combine_summary_stats.pl --file_search_mode pattern --within_pattern ".$job_name."_w"." --between_pattern ".$job_name."_b"." --groups_list ".$groups_list."\n\n";
    }else{
      my $file_out_line2 = "plot_pco_with_stats_all.pl --data_file ".$data_file." --sig_if lt --groups_list ".$groups_list." --num_perm ".$num_perm." --perm_type dataset_rand --dist_method ".$dist_method." --dist_pipe ".$dist_pipe." --output_prefix ".$job_name."_w"." --tree ".$tree_name." --cleanup"."\n";
      my $file_out_line3 = "plot_pco_with_stats_all.pl --data_file ".$data_file." --sig_if gt --groups_list ".$groups_list." --num_perm ".$num_perm." --perm_type rowwise_rand --dist_method ".$dist_method." --dist_pipe ".$dist_pipe." --output_prefix ".$job_name."_b"." --tree ".$tree_name." --cleanup"."\n";
      my $file_out_line4 = "combine_summary_stats.pl --file_search_mode pattern --within_pattern ".$job_name."_w"." --between_pattern ".$job_name."_b"." --groups_list ".$groups_list."\n\n";
    }
      
    if($debug){print "HELLO"}
    if($debug){print $file_out_line1.$file_out_line2.$file_out_line3.$file_out_line4 }

    print FILE_OUT $file_out_line1;
    print FILE_OUT $file_out_line2;
    print FILE_OUT $file_out_line3;
    print FILE_OUT $file_out_line4;

      

  }

}




sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
script:               $0

DESCRIPTION:
Script to write an amethst commands list from a much simpler input.
file_in should be a tab delimited file that contains the following 7 or 8 columns 
(column order is expected as):

#job_name #data_file #groups_list #num_perm #dist_method #dist_pipe #output_prefix #tree(optional)

(1) #job_name:      an arbitrary name for the analysis, e.g. analysis_1
(2) #data_file:     the name of the file that contains the abundance data
(3) #groups_list:   the name of the file that contains the groups list
(4) #num_perm:      the number of monte-carlo permutations of the data to use wen generating p values
(5) #dist_method    the distance/dissimilarity metric the use (must be a valid dist_method): 
                         use "plot_pco_with_stats_all.pl -h" for MG-RAST_pipe metrics (see #dist_pip below)
                         use "beta_diversity.py -s" for qiime_pipe metrics            (see #dist_pip below)
                         use "OTU" or "w_OTU" for OTU_pipe metrics                        (see #dist_pip below)
(6) #dist_pipe:     the analysis pipeline used to generate the abudance counts, one of three possible values
                         "MG-RAST_pipe" - distances calculated with R (ecodist and base) 
                         "qiime_pipe"   - distances calculated with qiime
                         "OTU_pipe"     - distances calculated with custom R scripts (utilize OTU overlap)
(7) #output_prefix: an arbitrary prefix to add to the output data
(8) #tree:          the only optional column, the name a a file containing a valid tree for unifrac-based distances


Files with less than 7 or more than 8 columns will generate an error. The column order is expected

NOTE(1): that the "tree" column is optional; it is only required for analyses that require a taxonomic
tree, e.g. analysis that use unifrac-based distance metrics.

NOTE(2): Blank lines or any lines in file_in that start with a # will be ignored. 
   
USAGE: write_amethst_commands.pl [-m file_search_mode][-w within_file] [-b between_file] [-o output_file] [-j job_name] -h -v -d
 
    -i|--file_in (string)  no default = 
                                    file formatted in the description above

    -o|--file_out         (string)  default = $file_out
                                    properly formatted amethst commands file
 _______________________________________________________________________________________

    -h|help                       (flag)       see the help/usage
    -v|verbose                    (flag)       run in verbose mode
    -d|debug                      (flag)       run in debug mode

);
  exit 1;
}


