package ProdLib;

#
#   $URL: http://theurl.link/tcm/scripts/lib/ProdLib.pm $
#   $Rev: 78 $
#   $Author: JC $
#   $Date: 2017-05-31 17:00:55 +1000 (Wed, 31 May 2017) $
#   $Id: ProdLib.pm 78 2017-05-31 07:00:55Z JC $
#
###############################################################################
#
# Description:
# DB lib under production environment
#
# Input: NA
# Output: NA
#
###############################################################################

my $LIBPATH;

BEGIN {
    $ENV{ORACLE_HOME} = '/opt/oracle/product/10.2.0/client_1';
    my $ldlib= '/opt/oracle/product/10.2.0/client_1/lib32';
    my $ld= $ENV{LD_LIBRARY_PATH};

    if (!$ld) {
        $ENV{LD_LIBRARY_PATH} = $ldlib;
    } elsif(  $ld !~ m#(^|:)\Q$ldlib\E(:|$)#  ) {
        $ENV{LD_LIBRARY_PATH} .= ':' . $ldlib;
    } else {
        $ldlib= "";
    }
    if(  $ldlib  ) {
        exec 'env', $^X, $0, @ARGV;
    }

	$LIBPATH = "/the/oracle/lib/lib";
}

use lib "$LIBPATH/DBDORA/lib/site_perl/5.8.4/sun4-solaris-64int/";
use DBI;
use DBD::Oracle;
use DBI qw(:sql_types);

1;
