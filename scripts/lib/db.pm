#!/usr/bin/perl
package db;

#
#   $URL: http://theurl.link/tcm/scripts/lib/db.pm $
#   $Rev: 206 $
#   $Author: JC $
#   $Date: 2017-08-18 10:15:56 +1000 (Fri, 18 Aug 2017) $
#   $Id: db.pm 206 2017-08-18 00:15:56Z JC $
#
###############################################################################
#
# Description:
# DB module for TCM to make the db connection and data retrive functions.
#
# Input: NA
# Output: NA
#
###############################################################################

use strict;
use File::Basename;
use POSIX qw/strftime _exit/;
use lib dirname(__FILE__);
use DBLib;

use Data::Dumper;

use vars qw/
    @ISA
    @EXPORT
    $sql
    $errors
/;
require Exporter;
@ISA = qw/ Exporter /;
@EXPORT = qw/
    $dbh
    $table
/;

use conf;
use elog;

our $dbh;
our $table;
my $e = new elog;
my $query;
my $host = comm->{dbhost};
my $sid  = comm->{dbsid};
my $user = comm->{dbuser};
my $pass = comm->{dbpass};
my $port = dbc->{port};
my $timefmt = dbc->{timefmt};
my $ERRDEBUG = 0;
my $DEBUG;
my $DAY = 1;

sub logit;

my $dbi;

sub new {
    my $class = shift;
    my $db = bless {}, $class;
    my %c = @_;
    map { $db->{lc($_)} = $c{$_} } keys %c;

    $db->{errstr} = undef;
    $db->{errarr} = [];
    $db->{TIMEOUT} ||= dbc->{timeout};
    $host = $db->{host} || $host;
    $sid  = $db->{sid}  || $sid;
    $port = $db->{port} || $port;
    $user = $db->{user} || $user;
    $pass = $db->{pass} || $pass;
    $DAY  = $db->{day} if defined $db->{day};
    $DEBUG = $db->{debug};

    local $SIG{ALRM} = sub { $db->dblp("db connection timeout") };
    alarm($db->{TIMEOUT});
    $db->dbh;
    alarm(0);

    return $db;
}

sub dbh {
    my $db = shift;

    my $dsn = "dbi:Oracle:host=$host;sid=$sid;port=$port";

# get dbh
    my $attr = {
	AutoCommit => 1,
	PrintError => 0,
	RaiseError => 0
    };

    eval  {
	$dbh = DBI->connect( 
		$dsn, 
		$user, 
		$pass, 
		$attr 
	) || return $db->retnull;
    };

    $dbh || die $e->die( "Fatal: cannot connect to db" );

    $db->retnull( "cannot connect to db - $@" ) if $@;

    $query = "alter session set nls_timestamp_format = '$timefmt'";
    $dbh->do($query);

    $dbh->{FetchHashKeyName} = 'NAME_lc';
    # $dbh->{ora_check_sql} = 0;
    # $dbh->{LongReadLen}   = 512 * 1024; # 512KB, change the size if need
    # $dbh->{LongTruncOk}   = 1;

    return $dbh;
}

# the transaction function 
sub tt {
    my $db = shift;
    my $sqls = shift || [];

	$db->clserr;

    $dbh->{AutoCommit} = 0;

    unless (@$sqls) {
		return $db->retnull( "no sql found!" );
    }

    eval {
		my $nn;
		foreach my $sql (@$sqls) {
			my $m = sprintf "%02d. ", ++$nn;
			$dbh->do($sql) || $db->dblp($m.$dbh->errstr);
		}
		$dbh->commit unless $db->err;
    };

    if ( $@ || $db->err ) {
		$dbh->rollback;
		my $msg = $@ ? " - $@" : ''; 
		return $db->retnull("transaction rollbacked".$msg);
    }

	my $msg = @$sqls.(@$sqls>1?" queries":" query");
	logit sprintf "transaction committed - %s", $msg;

    $dbh->{AutoCommit} = 1;

    1;
}

sub nextid {
    my $db = shift;
    my $t = shift;
    my $sql = "select $t"."_seq.nextval id from dual";
    return $db->row($sql);
}

sub row {
    my $db = shift;
    my $sql = shift;
    my $r = $dbh->selectrow_hashref($sql);
    return $db->retnull if $dbh->errstr;
    return $r;
}

sub array {
    my $db = shift;
    my $sql = shift;
    my $arr = [];
    $arr= $dbh->selectall_arrayref($sql, { Slice => {} });
    return $db->retnull if $dbh->errstr;
    return $arr;
}
sub arr { # one col array
    my $db = shift;
    my $sql = shift;
    my $arr = $dbh->selectcol_arrayref($sql);
    return $db->retnull if $dbh->errstr;
    return $arr;
}

sub hash {
    my $db = shift;
    my $sql = shift;
    my $key = shift || return undef;
    my $h = {};
    $h = $dbh->selectall_hashref($sql, $key);
    return $db->retnull if $dbh->errstr;
    return $h;
}

sub kvhash {
    my $a = shift || [];
    my $k = shift;
    my $ah = {};
    foreach my $h (@$a) {
	if (ref $ah->{$h->{k}} ne 'ARRAY') {
	    $ah->{$h->{k}} = [];
	}
	push @{$ah->{$h->{k}}}, $h->{v};
    }
    return $ah;
}

sub prepare {
    my $db = shift;
    my $sql = shift;
    my $sth = $dbh->prepare($sql) || return $db->retnull;
    return $sth;
}

sub query {
    my $db = shift;
    my $sql = shift;
    my $p = shift;
    @$p || return $db->retnull( "params not found"); 
    my $sth = $dbh->prepare($sql) || return $db->retnull;
    $sth->execute(@$p) || return $db->retnull;
    return 1;
}

sub isdev {
    return $conf::ENV =~ /pc|dev/i;
}
sub dev {
    my $min = shift || 60;
    return $min;
}

sub group_tcmfile {
    my $db = shift;
    my $min = shift || sys->{file_alert};

    my $q = "select element as k, count(*) as v from tcmfile 
            where created >= sysdate - $min/(24*60) 
            group by element
	    union
	    select element as k, count(*) as v from tcmdump
            where created >= sysdate - $min/(24*60) 
            group by element"; 

    return kvhash $db->array($q);
}

# report / alert
sub missing_seq_report {
    my $db = shift;
    my $min = shift || sys->{min};

    $min = dev $min;

    my $q = "select (select count(*) from tcmstat where state = 'missing') nn, 
	    element, seqnum, state, created from tcmstat 
	    where created >= sysdate - $min/(24*60) 
	    and state in ('missing', 'found') 
	    order by element, seqnum, state desc";
    return $db->array($q) || [];
}

# daily report
sub day {
    $DAY ? "-$DAY" : '';
}

sub daily_stat_id {
    my $db = shift;
    my $tag = shift || return $db->retnull('daily: no tag');
    my $day = day;
    my $q = "select concat('ID ',fid) k, created v
	    from tcmstat 
	    where state = '$tag'
	    and trunc(created) = trunc(sysdate$day)
	    order by fid, created";
    return kvhash $db->array($q);
}
sub daily_stat_list {
    my $db = shift;
    my $tag = shift || return $db->retnull('daily: no tag');
    my $day = day;
    my $q = "select element k, seqnum v
	    from tcmstat 
	    where state = '$tag'
	    and trunc(created) = trunc(sysdate$day)
	    order by element, seqnum";
    return kvhash $db->array($q);
}
sub daily_x_report { # exception report
    my $db = shift;
    my $day = day;
    my $q = sprintf "select ts.*, td.filename from tcmstat ts, tcmdump td
	    where trunc(ts.created) = trunc(sysdate$day)
	    and ts.state in ('%s', '%s') 
	    and ts.fid = td.id
	    order by ts.element, ts.seqnum, ts.state desc", 
	    stc->{invalid}, stc->{empty};

    return $db->array($q) || [];
}
sub daily_missing_report {
    my $db = shift;
    my $day = day;
    my $q = sprintf "select * from tcmstat 
	    where trunc(created) = trunc(sysdate$day)
	    and state in ('%s', '%s') 
	    order by element, seqnum, state desc", 
	    stc->{missing}, stc->{found};

    return $db->array($q) || [];
}


sub marked {
    my $db = shift;
    my $tag = shift;
    # my $q = "select max(created) tt from tcmmark where tag = '$tag' and env = '$ENV' group by tag,env";
    my $q = "SELECT * FROM ( 
		SELECT t.created,
		    rank() over (partition by tag, env order by created desc) rnk
		FROM tcmmark t
		WHERE tag='missing_new' and env='pc'
	    )
	    WHERE rnk = 1";
    return $db->row($q)->{created};
}

sub missing_seq {
    my $db = shift;
    my $min = shift || sys->{min};
    my $cn = shift || 'created';
    my $sql;
    $min = dev $min;

    # my $tt = $db->marked(mark->{mn}); # tag created time 
    $sql = "$cn >= sysdate - $min/(24*60)";

    my $q = "select element k, seqnum v from tcmstat 
            where $sql
            and state='missing' 
            and seqnum not in (select seqnum from tcmstat where state='found')
            group by element, seqnum 
            order by element, seqnum";

    return kvhash $db->array($q);
}   
sub element_seq {
    my $db = shift;
    my $rank = shift || sys->{rank};
    my $q = "select element k, seqnum v from
	    (
		select element, seqnum, id, rank()
		over ( partition by element order by seqnum desc) rank
		from tcmfile
	    )
	    where rank <= $rank
	    group by element, seqnum
	    order by element, seqnum";

    return kvhash $db->array($q);
}

sub element_new {
    my $db = shift;
    my $min = shift || sys->{min};
    my $cn = shift || 'created';
    # JC: testing only
    my $tf = 'tcmfile';

    $min = dev $min;

    my $q = "select element k, seqnum v
	    from tcmstat 
	    where state = 'new'
	    and $cn >= sysdate - $min/(24*60)"; 
    return kvhash $db->array($q);
}

# get data hash array by minutes interval
sub data_array {
    my $db = shift;
    # table
    my $t = shift || return undef;
    my $c = shift || '*';
    my $min = shift || sys->{min};
    # column for matching
    my $cn = shift || 'created';
    my $sql = "select $c from $t where $cn >= sysdate - $min/(24*60) order by created";
    return $db->array($sql) || [];
}
# get data column array by minutes interval
sub data_arr {
    my $db = shift;
    # table
    my $t = shift || return undef;
    my $c = shift || 'seqnum';
    my $min = shift || sys->{min};
    # column for matching
    my $cn = shift || 'created';
    my $sql = "select $c from $t where $cn >= sysdate - $min/(24*60) order by $c";
    return $db->arr($sql);
}
# get yesterday's data
sub yesterday_data {
    my $db = shift;
    # table
    my $t = shift || return undef;
    my $c = shift || '*';
    # column for matching
    my $cn = shift || 'created';
    my $sql = "select $c from $t where trunc($cn) = trunc(sysdate)-1";
    return $db->array($sql) || [];
}

# get min and max seqnums
sub mm {
    my $db = shift;
    # table
    my $t = shift || return undef;
    # column for matching
    my $c = shift || 'seqnum';
    my $min = shift || sys->{min};
    my $sql = "select min($c) min, max($c) max from $t where created >= sysdate - $min/(24*60)";
    my $r = $db->row($sql);
    return $r;
}


# inserts
sub insert {
    my $db = shift;
    my $t = shift || return $db->retnull("no table");
    my $p = shift || return $db->retnull("no params");
    my @c = (s2a table->{$t});
    my $q = shift || "insert into $t (%s) values (%s)";
    $q = sprintf $q, join(',',@c), join(',',map {'?'} @c);
    $e->dump($q);
    my $r = $db->query($q, $p);
    $r || return 0;
    1;
}
sub tcmfile {
    my $db = shift;
    my $id = shift || return $db->retnull("tcmfile: no id");
    my $p = shift || return $db->retnull("tcmfile($id): no params");
    my $t = 'tcmfile';
    my $r = $db->insert($t, $p);
    if ($r) {
	$e->db("ID $id inserted");
    } else {
	logit "ID: $id - ".$DBI::errstr;
	# dump to db
	my $r = $db->tcmdump($id, $p);
	return 0;
    }
    1;
}
sub tcmdump {
    my $db = shift;
    my $id = shift || "000000"; # not right
    my $p = shift || return $db->retnull("tcmdump($id): no params");
    my $t = 'tcmdump';
    my $r = $db->insert($t, $p);
    if ($r) {
	$e->db("ID $id dumped");
    } else {
	logit "ID: $id - ".$DBI::errstr;
	$e->dump('tcmdump insert failed - '.Dumper($p));
	return 0;
    }
    1;
}
sub tcmstat {
    my $db = shift;
    my $id = shift || "'unknown'";
    my $p = shift || return $db->retnull("tcmstat: no params");
    my $t = 'tcmstat';
    my $r = $db->insert($t, $p) || return $db->retnull("STAT $id - ".$DBI::errstr);
    return 1;
}
sub tcmmark {
    my $db = shift;
    my $p = shift || return $db->retnull("tcmmark: no params");
    my $t = 'tcmmark';
    my $r = $db->insert($t, $p) || return $db->retnull;
    return 1;
}

# tools
sub element {
    my $db = shift;
    my $q = "select e from tcmelement";
    return $db->arr($q) || [];
}

# to unixtime
sub now2ut {
    my $db = shift;
    my $ut = shift || localtime;
    my $sql = "SELECT (SYSDATE - TO_DATE('01-01-1970 00:00:00', '$timefmt')) * 24 * 60 * 60 FROM DUAL";
    return $db->row($sql);
}
# unixtime to date time
sub ut2dt {
    my $db = shift;
    my $ut = shift || localtime;
    my $sql = "select to_char(to_date('1970-01-01','YYYY-MM-DD') + numtodsinterval($ut,'SECOND'),'$timefmt') dt from dual";
    return $db->row($sql);
}
# get now with format from oracle
sub now {
    my $db = shift;
    my $sql = "SELECT TO_CHAR(SYSDATE, '$timefmt') now FROM DUAL";
    return $db->row($sql);
}

# sql
sub nowsql {
    my $db = shift;
    return strftime(fmt->{dt}, localtime);
}

sub desc {
    my $db = shift;
    my $t = shift || return undef;
    my $sql = "SELECT * FROM $t WHERE 1=0";
    my $sth = $db->prepare($sql) || $db->retnull;
    return $sth->{NAME};
}

sub exists_seq {
    my $db = shift;
    my $em = shift;
    my $sn = shift;
    my $st = shift || 'missing';
    my $q = "select count(*) nn from tcmstat 
	    where element = '$em' 
	    and seqnum = $sn 
	    and state = '$st'";
    my $r = $db->row($q);
    return $r->{nn};
}
sub seq_list {
    my $db = shift;
    my $t = shift || 'tcmfile'; # table
    my $min = shift || 60;

    my $sql = $min ? "where created >= sysdate - $min/(24*60)" : '';
    my $q = qq(SELECT * FROM $t $sql order by element, seqnum, filename);
    return $db->array($q) || [];
}

sub count {
    my $s = shift;
    my $t = shift || return; # table
    my $min = shift || 60;

    $min = dev $min;

    my $q = $min ? "where created >= sysdate - $min/(24*60)" : '';
    my $sql = qq(SELECT count(*) "nn" FROM $t $q);
    my $r = $s->row($sql);
    return $r->{nn};
}

# oracle tools
sub cat {
    my $db = shift;
    my $query = "select * from cat";
    return $db->array($query) || [];
}
sub showtables {
    my $db = shift;
    my $o = shift || $user;
    my $query = "SELECT table_name FROM all_tables WHERE owner = '$o'";
    return $db->arr($query);
}
sub nls {
    my $db = shift;
    my $query = "select * from nls_session_parameters";
    return $db->array($query) || [];
}

sub exists {
    my $db = shift;
    my $t = shift;
    my $tables = $db->showtables;
    return grep /$t/, @$tables;
}

sub version {
    my $db = shift;
    return $db->row("SELECT * FROM V\$VERSION");
}
sub v {
    my $db = shift;
    return $db->version;
}

sub disc {
    my $db = shift;
    $dbh->disconnect if $dbh;
}
sub close {
    my $db = shift;
    $dbh->disconnect if $dbh;
}

sub DESTROY { $dbh->disconnect }

# db log print
sub dblp {
    my $db = shift;
    my $msg = shift || $db->errstr;
    $db->seterr($msg);
    logit $msg if $msg;
    return $msg;
}

sub get_time_diff {
    my $db = shift;
    my $atime = shift;
    my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
    $sql = "select TIMEDIFF('$now','$atime') as time_diff";
    my $r = $db->row($sql);
    return $db->fmt_time_diff($r->{time_diff});
}

sub timeout {
    my $db = shift;
    my $t = shift;
    my $NOW = strftime("%H:%M:%S", localtime(time));
    if ( $NOW ge $t->{t1} or $NOW le $t->{t2} ) {
		return undef;
    }
    $t->{msg} = "$NOW is out of ".$t->{t1}." and ".$t->{t2}." - cron stopped";
    return $t->{msg};
}

sub h2h { # hash to hash
    my $db = shift;
    my $h = shift;
    my $hh;
    foreach my $k ( keys %$h ) {
		$hh = $h->{$k} if $h->{$k};
    }
    return $hh;
}

sub logit {
    $e->dberr(shift);
}

sub neatit {
    my $db = shift;
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

sub errstr {
    my $db = shift;
    return $db->{errstr};
}
sub err {
    my $db = shift;
    return $db->{errstr};
}
sub clserr {
	my $db = shift;
	$db->{errstr} = undef;
}
sub seterr {
    my $db = shift;
    my $msg = shift;
    $db->{errstr} = $msg;
}
sub reterr {
    my $db = shift;
    my $err = shift || $dbh->errstr || $DBI::errstr;
    $err ||= "no errors";
    $db->seterr($err);
    logit $err;
    return $err;
}
sub retnull {
    my $db = shift;
    $dbh || return undef;
    my $err = shift || $dbh->errstr || $DBI::errstr;
    $err ||= "no errors";
    $db->seterr($err);
    logit $err;
    return undef;
}

sub errhash {
    my $db = shift;
    my $hash = shift;
    push @{$db->{errarr}}, $hash;
}

sub usage {
    my $db = shift;
    print qq(Usage: $0 \n);
    exit(1);
}

1;
