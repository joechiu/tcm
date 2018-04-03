package conf;

#
#   $URL: http://theurl.link/tcm/scripts/lib/conf.pm $
#   $Rev: 131 $
#   $Author: JC $
#   $Date: 2017-07-24 11:15:37 +1000 (Mon, 24 Jul 2017) $
#   $Id: conf.pm 131 2017-07-24 01:15:37Z JC $
#
###############################################################################
#
# Description:
# TCM configuration module. It resolves the plain text config.ini under config
# to a hash with paired key and value and creates functions to return the 
# settings.
#
# Input: NA
# Output: NA
#
###############################################################################

use Exporter;
use File::Basename;
use POSIX qw/strftime/;
use Config::Tiny;
use vars qw/@ISA @EXPORT/;

@ISA = qw/Exporter/;
@EXPORT = qw/
    s2a s2r sda RUN LOOK
    comm sys cron mark path report file
    xml dbc table fmt stc regx mail logc
/;

sub s2a { split /\W\s*/, shift }
sub s2r { join '|', split /\W\s*/, shift }
sub sda { split /\,/, shift }

my $path = dirname(__FILE__)."/../../config";
my $file = "config.ini";

# Set for Hash: Config::TinyX::set;
our $C = Config::Tiny->read("$path/$file");

sub comm 	{ $C->{comm} }
sub sys	 	{ $C->{sys} }
sub cron	{ $C->{cron} }
sub mark 	{ $C->{mark} }
sub path	{ $C->{path} }
sub report	{ $C->{report} }
sub file 	{ $C->{file} }
sub xml 	{ $C->{xml} }
sub dbc		{ $C->{db} }
sub table	{ $C->{table} }
sub fmt		{ $C->{fmt} }
sub regx	{ $C->{fmt} }
sub stc		{ $C->{stc} }
sub mail 	{ $C->{mail} }
sub logc	{ $C->{log} }

sub RUN {
    my $p = shift; # process
    my $t = sys->{$p} || 60;
    my $tt = strftime("%H", localtime) * 60 + strftime("%M", localtime);
    my $pit = cron->{$p} || 0; # point in time 
    return ($tt % $t) == $pit;
}

sub LOOK {
    my $ID = shift;
    return () if -z cron->{LOCK};
    open FILE, '<', cron->{LOCK}; 
    my @pid = <FILE>; 
    close FILE;

    my @exists= ();
    foreach my $pid (@pid) {
	chomp $pid;
	$pid || next;
	my $exists = kill 0, $pid;
	if ($exists) {
	    push @exists, $pid;
	}
    }
    open FILE, '>', cron->{LOCK}; 
    print FILE join("\n", ( @exists, $ID ));
    close FILE;

    return @exists
}

1;
