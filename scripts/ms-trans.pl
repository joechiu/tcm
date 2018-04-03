#!/usr/bin/perl

#
#   $URL: http://theurl.link/tcm/scripts/ms-trans.pl $
#   $Rev: 132 $
#   $Author: JC $
#   $Date: 2017-07-24 15:54:10 +1000 (Mon, 24 Jul 2017) $
#   $Id: ms-trans.pl 132 2017-07-24 05:54:10Z JC $
#
###############################################################################
#
# Description:
# ms-trans.pl is a transfer control and monitor service to transfer the CDR 
# files from the source to the target directory and validate/monitor inproper 
# processes and collect the information of transferred transactions to either 
# the database or log files or both.
#
# Input: gzipped XML raw files
# Output: gzipped XML raw files
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
use db;

use constant APP => 'RUN';
use constant GO => 30; # go after GO seconds if process locked

my $e = new elog;
my $db = new db;
my $u = new util(db=>$db);
my $NN = 1;
my $TEST;

GetOptions('t!' => \$TEST, 'test!' => \$TEST);

if (my @pid = LOOK($$)) {
    $e->plog($e->f("PID %s still in process, $0 will be running after %d seconds...", join(', ', @pid), GO), 'warn');
    sleep GO;
}

$e->info( "Source: $util::sdir, Target: $util::tdir" ) if RUN( 'header' );

if (not $TEST) {
    RUN( APP ) || 
    exit printf "[%s] %s running every %s minutes with %s minutes offset, idling...\n", $u->time, $0, sys->{RUN}, cron->{RUN};
}

my $t1 = _gettime;

$e->plog($e->f("%02d. ==== task control monitor service is running ====", $NN++));
my $da = $u->files;
if (not $u->ok($da)) {
    $e->plog($e->f("%02d. %s", $NN++, $u->errstr), 'warn');
    $e->flag(1);
    exit
}

$e->plog($e->f("%02d. -- TCM transactions start (%ss)", $NN++, _timediff));

$e->plog($e->f("%02d. \tmoving files (%ss)", $NN++, _timediff($t1)));
$u->mv($da);

if ($u->err) {
    $e->plog($e->f("%02d. \tError: failed to move files - %s (%ss)", $NN++, $u->errstr, _timediff), 'err');
    $e->flag(1);
} else { 
    $e->plog($e->f("%02d. \t%s files transferred! marking flag and dumping data (%ss)",$NN++,  $u->total, _timediff), 'ok');
    $e->flag(0);
    $e->dump( "transfer - ".Dumper($u->{da}) );

    $e->plog($e->f("%02d. \tdb transactions (%ss)", $NN++, _timediff));
    $u->trans;

    $e->plog($e->f("%02d. \tprocessing missing and found files (%ss)", $NN++, _timediff));
    $u->missing_found;

    $e->plog($e->f("%02d. \tprinting column counter status: ", $NN++));
    $u->cc;
}

$e->plog($e->f("%02d. -- TCM transactions end (%ss)", $NN++, _timediff($t1)));

