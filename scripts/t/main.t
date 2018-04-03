#!/usr/bin/perl

#
#
#   $URL$
#   $Rev$
#   $Author$
#   $Date$
#   $Id$
#
#
###############################################################################
#
# Description:
#
# NAME
#     init.t
# 
# SYNOPSIS
#         cd tcm/scripts/t
#         perl init.t
# 
# DESCRIPTION
#     This test script is included in test harness wrapper test. It will run
#     before the test scripts in the t/ directory.
# 
#     This test script simply tests the followings:
# 
#     *   The pre-requisite modules required to run the test scripts.
# 
#     *   The Perl build in module for all the test scripts running.
# 
# AUTHOR
#     See the svn header for the info
# 
#
###############################################################################

use strict;
use File::Basename;
use Test::Harness;
use Data::Dumper;
use lib dirname(__FILE__).'/../lib';

=head1 NAME

main.t

=head1 SYNOPSIS

    cd tcm/scripts/t
    perl main.t

=head1 DESCRIPTION

Main test script implements test harness to control and manage the tests. 

It will be called remotely by the run.pl in in the install to be part of
the installation processes. 

=over 4

=back

=head1 AUTHOR

See the svn header for the info

=cut


@ARGV || die "no tests found";

my $option = $ARGV[0];

if ( $option =~ /^all$/i ) {
    @ARGV = qw/
	db.t  elog.t  init.t  util.t  conf.t
    /;
}

foreach my $t (@ARGV) {
    runtests $t
}
