#!/usr/bin/perl

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
#  
#
# AUTHOR
#     See the svn header for the info
# NAME
#     os-comm.t
# 
# SYNOPSIS
#         cd tcm/scripts/t
#         perl os-comm.t
#         or
#         ./os-comm.t
# 
# DESCRIPTION
#     Runs comm module test scripts in the t/ directory.
# 
#     This test script simply demonstrates how to fix the Test::Builder has versioin 
#     incompatibility issues.
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

os-comm.t

=head1 SYNOPSIS

    cd tcm/scripts/t
    perl os-comm.t

=head1 DESCRIPTION

Runs comm module test scripts in the t/ directory.

This test script simply demonstrates how to fix the Test::Builder has versioin 
incompatibility issues.

=head1 ISSUE

Test::Builder has incompatibility issues among the environments 

=head1 AUTHOR

See the svn header for the info

=cut

my $tb = Test::Builder->new;

START:
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

if (!$PASS) {
    goto START;
}

pass("common configuration validated");

UPDATE( 'comm', $c->{cc} );

$tb->_ending;

print "Manual Setting is done\n";

__END__
