#!/usr/bin/perl

#
#   $URL: http://theurl.link/tcm/scripts/ms-clean.pl $
#   $Rev: 128 $
#   $Author: JC $
#   $Date: 2017-07-21 15:20:13 +1000 (Fri, 21 Jul 2017) $
#   $Id: ms-clean.pl 128 2017-07-21 05:20:13Z JC $
#
###############################################################################
#
# Description:
# ms-clean.pl used to clean the transferred xml files. Note: dev only
#
# Input: XML raw files
# Output: NA
#
###############################################################################

use strict;
use File::Basename;
use Data::Dumper;
use Getopt::Long;
use lib dirname(__FILE__).'/lib';
use util;
use elog;
use conf;

use constant APP => 'ms_clean';

my $e = new elog;
my $u = new util;
my $TEST;

GetOptions('t!' => \$TEST, 'test!' => \$TEST);

if (not $TEST) {
    RUN( APP ) || 
    exit printf "[%s] %s running every %s minutes with %s minutes offset\n", $u->time, APP, sys->{ms_clean}, cron->{ms_clean};
}

my @f = glob comm->{zippath}."/XML*";

if (@f) {
    my $res = unlink glob "$util::tdir/XML*";

    if ($res) {
	$e->info( @f." files cleaned!" );
    } else {
	$e->warn( "cannot clean $util::tdir/XML*" );
    }
} else {
    $e->info("cannot clean - empty folder");
}
