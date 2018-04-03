#!/usr/bin/perl

#
#
#   $URL: http://theurl.link/tcm/scripts/t/init.t $
#   $Rev: 135 $
#   $Author: JC $
#   $Date: 2017-08-01 11:14:00 +1000 (Tue, 01 Aug 2017) $
#   $Id: init.t 135 2017-08-01 01:14:00Z JC $
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
use Data::Dumper;
use File::Basename;
use lib dirname(__FILE__).'/lib';
use lib dirname(__FILE__).'/../lib';
use Test::More 'no_plan';


=head1 NAME

init.t

=head1 SYNOPSIS

    cd tcm/scripts/t
    perl init.t

=head1 DESCRIPTION

This test script is included in test harness wrapper test. It will run before 
the test scripts in the t/ directory.  

This test script simply tests the followings: 

=over 4

=item *

The pre-requisite modules required to run the test scripts.

=item *

The Perl build in module for all the test scripts running.

=back

=head1 AUTHOR

See the svn header for the info

=cut

use_ok( 'DBLib' );
use_ok( 'util' );
can_ok('util', ('new'));
use_ok( 'elog' );
can_ok('elog', ('new'));
use_ok( 'conf' );
use_ok( 'db' );
can_ok('db', ('new'));

use_ok( 'Data::Dumper' );
use_ok( 'DBI' );
use_ok( 'Digest::MD5' );
use_ok( 'Exporter' );
use_ok( 'Fcntl' );
use_ok( 'File::Copy' );
use_ok( 'Config::Tiny' );
use_ok( 'File::Spec' );
use_ok( 'IO::File' );
use_ok( 'List::Util' );
use_ok( 'Net::SMTP' );
use_ok( 'POSIX' );
use_ok( 'Sys::Hostname' );
use_ok( 'Text::Tabs' );
use_ok( 'Text::Wrap' );
use_ok( 'Time::HiRes' );
use_ok( 'Term::ReadLine' );





__END__


