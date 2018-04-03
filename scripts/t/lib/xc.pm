package xc;

#
#   $URL: 
#   $Rev: 
#   $Author: 
#   $Date: 
#   $Id: 
#
###############################################################################
#
# Description:
# 
# NAME
#     xc.pm
# 
# DESCRIPTION
#
#     For manually change common configurations including loading and pushing.
#
# AUTHOR
#     See the svn header for the info
# 
# 
#
###############################################################################

use Exporter;
use Sys::Hostname;
use File::Basename;
use POSIX qw/strftime/;
use Config::TinyX;
use vars qw/@ISA @EXPORT/;

@ISA = qw/Exporter/;
@EXPORT = qw/
    UPDATE
/;

my $path = dirname(__FILE__)."/../../../config";
my $file = "config.ini";

# Set for Hash: Config::TinyX::set;
our $O = Config::TinyX->read("$path/$file");

our $C = Config::TinyX::set;

sub UPDATE {
    my $k = shift;
    my $h = shift;
    $O->{$k} = $h;
    return $O->write("$path/$file");
}

1;
