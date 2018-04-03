#!/usr/bin/perl

use strict;
use File::Basename;
use Data::Dumper;
use lib dirname(__FILE__).'/lib';
use c;

use constant APP3 => 'daily_report';

print "Hello \n";

if (RUN( APP3 )) {
    printf "it's about time to cron\n"
} else {
    printf "it's not about time\n"
}

