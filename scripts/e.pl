#!/usr/bin/perl

use strict;
use File::Basename;
use Data::Dumper;
use lib dirname(__FILE__).'/lib';
use elog;

my $e = new elog;

# $e->smtp('','','yourname@yourmail.domain,j.chiu@yourmail.domain');
# $e->sendmail('','','yourname@yourmail.domain,henry.he@yourmail.domain');
$e->sendmail('test from dev server','','yourname@yourmail.domain,yourname@xxx.com.au');
# $e->smtp('','','yourname@yourmail.domain,henry.he@yourmail.domain');

