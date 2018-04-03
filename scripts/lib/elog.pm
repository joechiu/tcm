package elog;

#
#   $URL: http://theurl.link/tcm/scripts/lib/elog.pm $
#   $Rev: 198 $
#   $Author: JC $
#   $Date: 2017-08-17 11:08:31 +1000 (Thu, 17 Aug 2017) $
#   $Id: elog.pm 198 2017-08-17 01:08:31Z JC $
#
###############################################################################
#
# Description:
# elog.pm provides error handlers, email and log functions.
#
# Input: NA
# Output: NA
#
###############################################################################

use strict;
use Data::Dumper;
use POSIX qw/strftime/;
use IO::File;
use Net::SMTP;
use conf;

use constant OFFSET => 86400;
use constant TIMECHK => '00:02:00|00:03:00';

our $DB		= logc->{db};
our $OK		= logc->{ok};
our $INFO	= logc->{info};
our $ERR	= logc->{err};
our $DEAD	= logc->{dead};
our $WARN	= logc->{warn};
our $DEBUG	= logc->{debug};
our $DUMP	= logc->{dump};
our $MAIL	= logc->{mail};
our $DBLOG	= logc->{dbhead};
our $DUMPLOG	= logc->{dumphead};
our $LOGDIR	= logc->{dir};
our $LOGPRE	= logc->{tcm};
our $LOGAGE	= logc->{age};
our $FLAG 	= path->{tmp}.'/'.file->{flag};
# our $TEST	= $conf::TEST;

my $fh;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %c = @_;
    map { $self->{lc($_)} = $c{$_} } keys %c;
    $fh = new IO::File if !$fh;
    return $self;
}

sub flag {
    my $e = shift;
    my $flag = shift;

    if ($flag) {
        $fh->open($FLAG);
        $flag = <$fh>;
        $flag++;
    }

    $fh->open("> $FLAG");
    # chmod 0777, $FLAG if $TEST;
    print $fh $flag;
}

sub db {
    my $e = shift;
    my $msg = shift;
    $e->lp($INFO, $msg, $DBLOG);
}
sub dbwarn {
    my $e = shift;
    my $msg = shift;
    $e->lp($WARN, $msg, $DBLOG);
}
sub dberr {
    my $e = shift;
    my $msg = shift;
    $e->lp($ERR, $msg, $DBLOG);
}
sub dbinfo {
    my $e = shift;
    my $msg = shift;
    $e->lp($INFO, $msg, $DBLOG);
}

sub ok {
    my $e = shift;
    my $msg = shift;
    $e->lp($OK, "\t$msg");
    return $msg;
}

sub info {
    my $e = shift;
    my $msg = shift;
    $e->lp($INFO, $msg);
    return $msg;
}

sub err {
    my $e = shift;
    my $msg = shift;
    $msg = $e->lp($ERR, $msg);
    $e->sendmail($msg) if $MAIL;
    return undef;
}

sub die {
    my $e = shift;
    my $msg = shift;
    $msg = $e->lp($DEAD, $msg);
    $e->sendmail($msg) if $MAIL;
    return undef;
}

sub warn {
    my $e = shift;
    my $msg = shift;
    $e->lp($WARN, $msg);
    return $msg;
}

sub debug {
    my $e = shift;
    my $msg = shift;
    $e->lp($DEBUG, $msg);
    return $msg;
}

sub dump {
    my $e = shift;
    my $msg = shift;
    $e->lp($DUMP, $msg, $DUMPLOG);
    1;
}

# print and log
sub plog {
    my $e = shift;
    my $msg = shift;
    my $type = shift || 'info';
    print "$msg\n";
    return $e->$type($msg) if $type;
    return $msg;
}

# sprintf
sub spf {
    my $e = shift;
    return sprintf( shift, @_ );
}
sub f {
    my $e = shift;
    return sprintf( shift, @_ );
}

my $nn;
sub lp {
    my $e = shift;
    my ($tag, $msg, $head) = @_;
    my $path = $LOGDIR || "/tmp";
    my $now = strftime("%H:%M:%S", localtime);
    my $today = strftime("%Y%m%d", localtime);
    $head ||= $LOGPRE || "tcm";
    my $file = "$head-$today";
    my $log = "[$today\@$now] $tag\t$msg\n";
    my $logfile = "$path/$file.log";
    map { unlink $_ if -M $_ > $LOGAGE } glob "$path/$head-*";
    $fh->open(">> $logfile");
    # update to 777 for group dev, 766 else
    # chmod 0777, $logfile if $TEST;
    print $fh $log;
    return $log;
}

sub foo {
    my $e = shift;
    # do sendmail 1 minute after every next day
    my $path = $LOGDIR || "/tmp";
    my $now = strftime("%H:%M:%S", localtime(time - OFFSET));
    my $yesterday = strftime("%Y%m%d", localtime(time - OFFSET));
    my $head = $LOGPRE || "tcm";
    my $file = "$head-$yesterday";
    my $logfile = "$path/$file.log";
    $e->info("mail sent($yesterday $now) - OK");
}

sub sendmail {
    my $e = shift;
    my $msg = shift || "just another test by sendmail";
    my $subject = shift || mail->{alert};
    my $to = shift || comm->{to};
    my $from = shift || mail->{from};
    my @to = sda $to;
    {
	open(SENDMAIL, "|/usr/sbin/sendmail -oi -t") or $e->warn("Can't fork for sendmail: $!");
	print SENDMAIL "Subject: $subject\n";
	print SENDMAIL "From: $from\n";
	print SENDMAIL "To: $to\n";
	print SENDMAIL "Content:\n\n";
	print SENDMAIL "$msg\n\n";
	print SENDMAIL mail->{noreply}."\n\n\n";
	close SENDMAIL;
    }
    $e->info("mail sent to: ".$to);
}

sub smtp {
    my $e = shift;
    my $msg = shift || "just another smtp mail";
    my $subject = shift || mail->{report};
    my $to = shift || comm->{to};
    my $from = shift || mail->{from};
    my @to = sda $to;
    my $smtp = Net::SMTP->new(mail->{host});
    foreach my $t (@to) {
	$smtp->mail;
	if ($smtp->to($t)) {
	    $smtp->data();
	    $smtp->datasend("To: $to\n");
	    $smtp->datasend("From: $from\n");
	    $smtp->datasend("Subject: $subject\n\n");
	    $smtp->datasend("$msg\n\n");
	    $smtp->datasend(mail->{noreply}."\n");
	} else {
	    printf "$t: %s\n", $smtp->message();
	}
    }
    $smtp->quit;
    $e->info("mail sent to: ".$to);
}

1;
