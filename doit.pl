#!/usr/bin/perl
use strict;
use Math::Trig;
use File::stat;
open (my $outstuff, ">", "outstuff.v") or die "cannot open outstuff $!";
print $outstuff "reg	[0:7] sin[90];\n";

my $index1;

my $angle;
my $sinval;
my $outval;
my $myrad;
my $mysin;
my $myintsin;

for ($index1 = 0; $index1 < 47; $index1 += 1) {
  $angle = (360/47) * $index1;
  $angle = int($angle);
  $myrad = deg2rad($angle);
  $mysin = 1 + sin($myrad);
  $mysin = $mysin * 50;
  $myintsin = int($mysin);
  
  print "degree  $index1 - angle $angle radian $myrad - sine $mysin - integer $myintsin\n";
  print $outstuff "assign sin[$index1] = $myintsin;\n";
  }

close $outstuff;
