#!/usr/bin/perl

#
#
#   $URL: http://theurl.link/tcm/scripts/t/elog.t $
#   $Rev: 135 $
#   $Author: JC $
#   $Date: 2017-08-01 11:14:00 +1000 (Tue, 01 Aug 2017) $
#   $Id: elog.t 135 2017-08-01 01:14:00Z JC $
#
#
###############################################################################
#
# Description:
#
# NAME
#     elog.t
# 
# SYNOPSIS
#         cd tcm/scripts/t
#         perl elog.t
# 
# DESCRIPTION
#     Runs elog module test scripts in the t/ directory. This is just a test
#     more function without plan.
# 
#     This test script simply tests the followings:
# 
#     *   The pre-requisite modules required to run the test.
# 
#     *   The Perl build in module for its own running.
# 
#     *   The validation of the db account and the connection.
# 
#     *   The module methods in the module.
# 
#     *   The syntax in the codes.
# 
#     *   Basic validation for the returns
# 
# AUTHOR
#     See the svn header for the info
# 
# 
#
###############################################################################

use strict;
use Data::Dumper;
use File::Basename;
use lib dirname(__FILE__).'/lib';
use lib dirname(__FILE__).'/../lib';
use Test::More 'no_plan';
use elog;
use conf;

=head1 NAME

elog.t

=head1 SYNOPSIS

    cd tcm/scripts/t
    perl elog.t

=head1 DESCRIPTION

Runs elog module test scripts in the t/ directory.  This is just a test
more function without plan.

This test script simply tests the followings: 

=over 4

=item *

The pre-requisite modules required to run the test.

=item *

The Perl build in module for its own running.

=item *

The validation of the db account and the connection.

=item *

The module methods in the module.

=item *

The syntax in the codes.

=item *

Basic validation for the returns

=back

=head1 AUTHOR

See the svn header for the info

=cut

diag "elog module tests";

use_ok( 'tt' );
my $t = new tt;
my $e = new elog;

use_ok( 'elog' );
can_ok('elog', ('new'));
use_ok( 'conf' );

pass("required modules preload");

# SKIP{ }
# elog module - method tests
foreach my $m ($t->methods('elog')) {
    can_ok( 'elog', ($m) ) if $e->can($m)
}

pass("passed elog module method tests");

pass("elog worked");


__END__
