#!/usr/bin/perl

#
#
#   $URL: http://theurl.link/tcm/scripts/t/comm.t $
#   $Rev: 136 $
#   $Author: JC $
#   $Date: 2017-08-01 15:09:47 +1000 (Tue, 01 Aug 2017) $
#   $Id: comm.t 136 2017-08-01 05:09:47Z JC $
#
#
###############################################################################
#
# Description:
#
#  
#
# AUTHOR
#     See the svn header for the info
# NAME
#     comm.t
# 
# SYNOPSIS
#         cd tcm/scripts/t
#         perl comm.t
#	  or
#         ./comm.t
# 
# DESCRIPTION
#     Runs comm module test scripts in the t/ directory.
# 
#     comm.t will allow users to input the settings and update the changes to
#     the main configuration file in conft directory It implements the test
#     more to check the errors without plan and tt module to do the
#     validations and database connecting tests.
# 
#     This test script simply tests the followings:
# 
#     *   The pre-requisite modules required to run the test.
# 
#     *   The Perl build in module for its own running.
# 
#     *   The manual input process.
# 
#     *   Validations for directory, email and database account settings.
# 
#     *   The module methods.
# 
#     *   The syntax in the codes.
# 
#     *   Basic validation for the returns
#
# ISSUE
#
#     * Test::Builder has versioin incompatibility issues among the environments 
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
use Test::Builder;
use db;

=head1 NAME

comm.t

=head1 SYNOPSIS

    cd tcm/scripts/t
    perl comm.t

=head1 DESCRIPTION

Runs comm module test scripts in the t/ directory. 

comm.t will allow users to input the settings and update the changes 
to the main configuration file in conft directory It implements the test 
more to check the errors without plan and tt module to do the validations
and database connecting tests.

This test script simply tests the followings: 

=over 4

=item *

The pre-requisite modules required to run the test.

=item *

The Perl build in module for its own running.

=item *

The manual input process.

=item *

Validations for directory, email and database account settings.

=item *

The module methods.

=item *

The syntax in the codes.

=item *

Basic validation for the returns

=back

=head1 ISSUE

Test::Builder has incompatibility issues among the environments 

=head1 AUTHOR

See the svn header for the info

=cut

START:
my $tb = Test::Builder->new;
$tb->reset;

diag "Manual Configuration starts";

use_ok( 'xc' );
use_ok( 'tt' );
my $t = new tt;

use_ok( 'db' );
can_ok('db', ('new'));

pass("required modules preloaded");

my $c = $t->conftest;
ok( !$c->{error}, "input values updated" );

exit print $c->{error},"\n" if $c->{error};

my $h = $c->{h};

# CDR repository existence
ok( $t->is_exist($h->{cdrpath}), "Test the existence of $h->{cdrpath}" );

# converter zip path existence
ok( $t->is_exist($h->{zippath}), "Test the existence of $h->{zippath}" );

# Email address validation
push @{$t->{PASS}}, like( $h->{to}, qr/.+?@.+?/, "validation for email address '$h->{to}'");

# Database connection test
push @{$t->{PASS}}, ok( !$t->dbconnect($h), "test database connection");

pass("common configuration completed");

# db module - method tests
can_ok( 'db', $t->methods('db'));
# foreach my $m ($t->methods('db')) {
#     can_ok( 'db', ($m) );
# }

pass("passed db module method tests");

my $PASS = $t->PASS;
goto START if !$PASS;

pass("common configuration validated");

use Term::ReadLine;
my $term = Term::ReadLine->new('Write and Save');
my $ans = $term->readline("Save to config [Y/n]? ") || 'n';

if ($ans eq 'Y') {
    UPDATE( 'comm', $c->{cc} )
} else {
    goto START if $ans
}

$tb->done_testing();

print "Manual Setting is done\n";

__END__
