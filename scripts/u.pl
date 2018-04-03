#!/usr/bin/perl

use strict;
use File::Basename;
use Data::Dumper;
use lib dirname(__FILE__).'/lib';
use db;
use util;
use conf;


my $db = new db;
my $u = new util(db=>$db);

my $f = $db->element_seq;
# my $f = $u->seq_missing;

print Dumper $f;

my $content .= "MISSING SEQNUM:\n";

if ($f->{missing}) {
    foreach my $em (@{$f->{elements}}) {
        $f->{$em}->{missing} || next;
        $content .= "$em: $f->{$em}->{message}\n";
        $content .= "[".join(", ", @{$f->{$em}->{list}})."]\n\n";
    }
} else {
    $content .= "no missing seqnums found\n";
}

print "$content\n";
