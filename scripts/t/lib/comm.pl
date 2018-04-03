#
#
#   $URL: http://theurl.link/tcm/scripts/t/lib/comm.pl $
#   $Rev: 140 $
#   $Author: JC $
#   $Date: 2017-08-03 16:31:29 +1000 (Thu, 03 Aug 2017) $
#   $Id: comm.pl 140 2017-08-03 06:31:29Z JC $
#
#
###############################################################################
#
# 
# NAME
#     comm.pl
# 
# SYNOPSIS
#         require "comm.pl"
# 
# DESCRIPTION
#     comm.pl provides the required functions for comm.t to update the comm
#     settings.
# 
# AUTHOR
#     See the svn header for the info
# 
#
###############################################################################

use Term::ReadLine;
use Data::Dumper;

=head1 NAME

comm.pl

=head1 SYNOPSIS

    require "comm.pl"

=head1 DESCRIPTION

comm.pl provides the required functions for comm.t to update the comm settings.

=head1 AUTHOR

See the svn header for the info

=cut

my $c = [
    {
        c => 'The source path for CDR files', # caption
        k => 'cdrpath', # key
        m => 1, # mandatory
	d => '/your/project/path/Input', # default
    },
    {
        c => 'The target path in the converter',
        k => 'zippath',
        m => 1, # mandatory
	d => '/your/project/path/Converter/Zip',
    },
    {
        c => 'Username for the database access',
        k => 'dbuser',
        m => 1, # mandatory
	d => 'bw_own',
    },
    {
        c => 'Password for the username',
        k => 'dbpass',
        m => 1, # mandatory
	d => 'bw_own',
    },
    {
        c => 'SID for the database instance',
        k => 'dbsid',
        m => 1, # mandatory
	d => 'dbtst01',
    },
    {
        c => 'Host name or server IP for the database',
        k => 'dbhost',
        m => 1, # mandatory
	d => 'yourdb.host.url',
    },
    {
        c => 'The recipient email address, separate multiple emails by comma',
        k => 'to',
        m => 1, # mandatory
	d => 'mediationsystems@yourmail.domain',
    }
];

my $cc = [];
my $hh = {};

my $term = Term::ReadLine->new('Common Configuration');
my $OUT = $term->OUT || \*STDOUT;

foreach my $h (@$c) {
    my $prompt = $h->{c};
    my $comment = $h->{c};

    $prompt .= " [$h->{d}]" if $h->{d};
    $_ = $term->readline($prompt.": ");
    $_ ||= $h->{d};

    if ( $_ ) {
        print $OUT "Your input: $_\n";
        $hh->{$h->{k}} = qq($_);
        my $ch = {
            $h->{k} => qq($_),
            comment => [ "# $comment" ],
        };
        push @$cc, $ch;
    } else {
        if ($h->{m}) {
                my $msg = "Error: your input is empty!";
                return { error => $msg, cc => $cc, h => $hh }
        } 
    }
}

{ cc => $cc, h => $hh }

