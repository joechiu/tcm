#!/usr/bin/perl

#
#   $URL: http://theurl.link/tcm/scripts/ms-alert.pl $
#   $Rev: 205 $
#   $Author: JC $
#   $Date: 2017-08-17 17:17:13 +1000 (Thu, 17 Aug 2017) $
#   $Id: ms-alert.pl 205 2017-08-17 07:17:13Z JC $
#
###############################################################################
#
# Description:
# ms-alert.pl will generate alerts and report including missing seq alert, missing
# file alert and daily report.
#
# Input: database data
# Output: text files
#
###############################################################################

use strict;
use File::Basename;
BEGIN {
    use lib dirname(__FILE__).'/lib';
};
use Getopt::Long;
use Data::Dumper;
use List::Util qw(sum);
use conf;
use util;
use elog;
use db;

sub seq_missing_alert;
sub file_missing_alert;
sub daily_report;

use constant APP1 => 'seq_alert';
use constant APP2 => 'file_alert';
use constant APP3 => 'daily_report';

my $DEV = 0;
my $TEST;
my $REPORT = 's';
my $DAY;
GetOptions('d=s' => \$DAY, 'r=s' => \$REPORT, 't!' => \$TEST, 'test!' => \$TEST) or 
    die qq(Usage: perl $0 -t (test) -r [missing seqnum alert(default) | missing file alert | daily report]\n);

# default: today's records
$DAY ||= 0;

my $e = new elog;
my $db = new db ( day => $DAY );
my $u = new util(db=>$db);
my $regx = s2r xml->{ignore};
my @ignore = s2a xml->{ignore};
my $content;
my @missing;
my $h;
my $HEAD = $DEV ? '[DEV] ' : $TEST ? '[TEST] ' : '';
my $MSG = sys->{extime}." time duration extended for pc/dev only\n\n";
my @SEND;

if (not $TEST) {
    if (RUN( APP1 )) {
	seq_missing_alert;
    } else {
	printf "[%s] %s running new and missing seqnum alerts every %s minutes with %s minute offset, idling...\n", $u->time, uc APP1, sys->{seq_alert}, cron->{seq_alert};
    }
    if (RUN( APP2 )) {
	file_missing_alert;
    } else {
	printf "[%s] %s running missing file alerts every %s minutes with %s minutes offset, idling...\n", $u->time, uc APP2, sys->{file_alert}, cron->{file_alert};
    }
    if (RUN( APP3 )) {
	daily_report;
    } else {
	printf "[%s] %s running missing seq daily report every %s minutes with %s minute offset, idling...\n", $u->time, uc APP3, sys->{daily_report}, cron->{daily_report};
    }
} else {
    print "running manually - $REPORT\n";
    seq_missing_alert	if $REPORT =~ /^s/;
    file_missing_alert	if $REPORT =~ /^f/;
    daily_report	if $REPORT =~ /^d/;
}

sub seq_missing_alert {

    my $f = $u->seq_missing;

    $e->dump(Dumper $f);

    if ($f->{missing}) {
	foreach my $em (@{$f->{elements}}) {
	    $f->{$em}->{missing} || next;
	    $content .= "$em: $f->{$em}->{message}\n";
	    $content .= join(",", @{$f->{$em}->{list}})."\n";
	}
    } else {
	$content .= "no missing seqnums found\n";
    }

    if ($f->{send}) {
	$e->sendmail($content, $HEAD.mail->{alert});
	print "$content\n\n";
	$e->info("mail sent - no seqnums found");
	print "mail sent\n";
    } else {
	$e->info("missing seq alert not sending - it's OK...");
	print "mail not sent - no missing seqnums found\n\n$content";
    }
}

sub file_missing_alert {

    my $f = $u->file_missing;

    $e->dump(Dumper $f);

    my $nn = $f->{total};

    $content .= "MISSING FILE:\n";

    $content .= $u->ignore_element_message;

    if ($f->{missing}) {
	foreach my $e (@{$f->{elements}}) {
	    $content .= "$e: $f->{$e}\n";
	}
	# $content .= "missing files found\n";
    } else {
	$content .= "no missing files found\n";
    }

    if ($f->{send}) {
	print "$content\n\n";
	$e->sendmail($content, $HEAD.mail->{file});
	$e->info("mail sent - no files received");
	print "mail sent\n";
    } else {
	$e->info("file missing alert not sending - no missing files found - it's OK...");
	print "mail not sent - no missing files found\n\n$content";
    }

    $e->dump($content);
}

sub daily_report {

    $content .= $u->rc('new')	if report->{new_element};
    $content .= $u->rc('missing')  if report->{missing_element};
    $content .= $u->rc('ignored')  if report->{ignored_element};
    $content .= $u->rc('empty', 1) if report->{empty_file};
    $content .= $u->rc('invalid',1) if report->{invalid_xml};

    # exception records of report
    my $xr = $db->daily_x_report;
    my $nn = @$xr;
    $content .= "EMPTY / INVALID ($nn found):\n";
    my $xx = 0;
    if ($nn) {
	$xx++;
	foreach my $h (@$xr) {
	    $content .= "- $h->{filename}\t$h->{state}\t$h->{created}\n";
	}
    } else {
	$content .= "No files found\n";
    }

    $content .= "\n\n";

    # stat report/record
    my $sr = $db->daily_missing_report;
    $nn = @$sr;
    
    $content .= "MISSING SEQNUM LIST:\n";
    if ($nn) {
	$content .= "$nn missing seqnum found\n";
	foreach my $h (@$sr) {
	    $content .= "$h->{element}\t$h->{seqnum}\t$h->{state}\t$h->{created}\n";
	}
    } else {
	$content .= "No missing sequence numbers found\n";
    }

    $e->dump($content);

    print "$content\n";
    $e->sendmail($content, $HEAD.mail->{report});

}


