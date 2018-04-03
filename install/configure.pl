#!/usr/bin/perl -w

#
#
#   $URL: http://theurl.link/tcm/install/run.pl $
#   $Rev: 111 $
#   $Author: JC $
#   $Date: 2017-07-20 14:27:12 +1000 (Thu, 20 Jul 2017) $
#   $Id: run.pl 111 2017-07-20 04:27:12Z JC $
#
#
###############################################################################
#
# Description:
#
# NAME
#     run.pl
# 
# SYNOPSIS
#         cd tcm/install
#         ./configure.pl
#         or
#         perl configure.pl
# 
# DESCRIPTION
#     Runs all the tests in the t/ directory. This is just a really simplistic
#     wrapper around Test::Harness.
# 
#     This differs from the test-runner that's part of the test in the
#     following ways:
# 
#     *   It controls an input process to update the common settings to the
#         main configuration file.
# 
#     *   It's slightly easier to run without mucking around, while you're
#         developing/working on tcm.
# 
#     *   It generates a coverage report which includes all the test-runner
#         results.
# 
#     *   It allows you to limit the tests run using an argument on the
#         command line. This is a simple substring of the test name, eg
#         "init.t" or "all".
# 
# AUTHOR
#     See the svn auto generated info instead
# 
#
###############################################################################

use strict;
use File::Basename;

my $PATH = dirname(__FILE__).'/../scripts/t';
my $COMM = 'comm.t';
my $MAIN = 'main.t';

=head1 NAME

configure.pl

=head1 SYNOPSIS

    cd tcm/install
    configure.pl
    or
    perl configure.pl

=head1 DESCRIPTION

Runs all the tests in the t/ directory.  This is just a really
simplistic wrapper around Test::Harness.

This differs from the test-runner that's part of the test in the
following ways:

=over 4

=item *

It controls an input process to update the common settings to the main
configuration file.

=item *

It's slightly easier to run without mucking around, while you're
developing/working on tcm.

=item *

It generates a coverage report which includes all the test-runner
results. 

=item *

It allows you to limit the tests run using an argument on the command
line.  This is a simple substring of the test name, eg "init.t" or
"all".

=back

=head1 AUTHOR

See the svn auto generated info instead

=cut

$ARGV[0] || usage();

eval {
    # do manual input for the common conf
    require "$PATH/$COMM";
    print "\n";
};

print "Coverage report: \n";

eval {
    chdir $PATH;
    # run another wrapper
    do $MAIN;
};

if ($@) {
    print $@;
    print "\nNo coverage report generated.  Fix failing tests first.\n";
}

sub usage {
    print "Usage: perl $0 [all [test-runner(s)]]\n";
    exit
}
