package DBLib;

#
#   $URL: http://theurl.link/tcm/scripts/lib/DBLib.pm $
#   $Rev: 135 $
#   $Author: JC $
#   $Date: 2017-08-01 11:14:00 +1000 (Tue, 01 Aug 2017) $
#   $Id: DBLib.pm 135 2017-08-01 01:14:00Z JC $
#
###############################################################################
#
# Description:
# A DB lib module to implement the oracle modules among different environments
#
# Input: NA
# Output: NA
#
###############################################################################

use Sys::Hostname;
use conf;
BEGIN {
    my $prod = comm->{hostname};
    if (hostname !~ /pc/i) {
        if (hostname =~ /prd/i) {
            use ProdLib;
        } else {
            use DevLib;
        }
    }
};
use Text::Wrap;
use Time::HiRes qw/gettimeofday tv_interval time/;
use File::Spec;
use Text::Tabs; $tabstop = 6;  # default = 8

1;
