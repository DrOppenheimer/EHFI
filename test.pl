#!/usr/bin/env perl
use Cwd;
use Cwd 'abs_path';
use File::Basename;
my $DIR=system(dirname(abs_path($0)));
print "\n\n"."DIR: ".$DIR."\n\n";
