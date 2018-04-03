package tt; # test tool

#
#   $URL: http://theurl.link/tcm/scripts/lib/elog.pm $
#   $Rev: 80 $
#   $Author: JC $
#   $Date: 2017-06-02 11:39:40 +1000 (Fri, 02 Jun 2017) $
#   $Id: elog.pm 80 2017-06-02 01:39:40Z JC $
#
###############################################################################
#
# Description:
# tt.pm provides requested tools for tests.
#
# Input: NA
# Output: NA
#
###############################################################################

use strict;
use Data::Dumper;
use POSIX qw/strftime/;
use File::Basename;

our $db;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %c = @_;
    map { $self->{lc($_)} = $c{$_} } keys %c;
    $self->{PASS} = [];
    return $self;
}

sub conftest {
    my $t = shift;
    my $cc; 
    my $path = dirname(__FILE__);
    eval { $cc = do "$path/comm.pl" };
    return $@ if $@;
    return $cc
}

sub dbconnect {
    my $t = shift;
    my $h = shift;
    eval { $db = new db(
	    host    => $h->{dbhost},
	    sid     => $h->{dbsid},
	    port    => 1521,
	    user    => $h->{dbuser},
	    pass    => $h->{dbpass},
    ) || die "cannot connect to db" };
    if ($@) {
	$db->{errstr} = [];
	push @{$db->{errstr}}, $@
    }
    $db->{errstr}
}

sub methods {
    my $t = shift;
    my $o = shift || return ();
    my @m = ();
    my @ex = qw/
	errors
	__ANON__
	sql
	EXPORT
	BEGIN
	ENV
	EXPORT_FAIL
	ISA
    /;

    my @o = eval "\%$o\:\:";
    return () if $@;

    foreach (@o) {
	if (/$o\:\:(.*)/) {
	    my $m = $1;
	    grep( /$m/, @ex ) && next;
	    push @m, $m;
	}
    }

    @m;
}

sub is_exist { 
    my $t = shift;
    my $d = shift; 
    if (-e $d and -d $d) {
	push @{$t->{PASS}}, 'directory exists';
	return 1
    }
    push @{$t->{PASS}}, 0;
    return 0
}

sub PASS {
    my $t = shift;
    map { /0/ && return } @{$t->{PASS}};
    return 1
}

1;
