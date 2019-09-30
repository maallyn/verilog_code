#!/usr/bin/perl
use strict;
use Math::Trig;
use File::stat;
open (my $outstuff, ">", "outstuff.v") or die "cannot open outstuff $!";

my $index1;

my $angle;
my $sinval;
my $outval;
my $myrad;
my $mysin;
my $myintsin;

for ($index1 = 0; $index1 < 40; $index1 += 1) {
  $angle = (360/40) * ($index1);
  $angle = int($angle);
  $myrad = deg2rad($angle);
  $mysin = 1 + sin($myrad);
  $mysin = $mysin * 20;
  $myintsin = int($mysin);
  
  print "degree  $index1 - angle $angle radian $myrad - sine $mysin - integer $myintsin\n";
  print $outstuff "assign wand_position_sin[$index1] = $myintsin;\n";
  }

close $outstuff;
