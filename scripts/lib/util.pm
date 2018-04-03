package util;

#
#   $URL: http://theurl.link/tcm/scripts/lib/util.pm $
#   $Rev: 215 $
#   $Author: JC $
#   $Date: 2017-08-18 14:21:19 +1000 (Fri, 18 Aug 2017) $
#   $Id: util.pm 215 2017-08-18 04:21:19Z JC $
#
###############################################################################
#
# Description:
# TCM utility module: provide file transferring, verification, validation, 
# parsing and task transaction functions.
#
# Input: NA
# Output: NA
#
###############################################################################

use strict;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use File::Copy;
use POSIX qw/strftime/;
use Time::HiRes qw/gettimeofday tv_interval/;
use Data::Dumper;
use Exporter;
use conf;
use elog;
use vars qw/@ISA @EXPORT/;
@ISA = qw/Exporter/;
@EXPORT = qw/
    sorting
    plus
    gen
    keygen
    _gettime
    _timediff
/;

use constant DA => 'da';

sub sorting { return sort { $a cmp $b } @_ }
sub arr2arr { return sort keys %{{map {$_ => 1} @_}} }

our $sdir   = comm->{cdrpath}; # source directory in input dir
our $tdir   = comm->{zippath}; # target to converter zip diretory
our $prefix = ''; # same level of directory, no nodes structure anymore
our $xmlpre = file->{prefix}; # usage: different prefix can be separated by |, eg. FOO|BAR
our $xmlfmt = file->{format};
our $NEW    = [ s2a xml->{new} ]; # manually added new element list
our $filter = [ s2a xml->{filter} ];
our $ignore = [ s2a xml->{ignore} ];
our $need   = [ s2a xml->{prefix} ]; # regular express enabled
our $TSN    = file->{tsn}; # total sequential number chained in the file names
our $t2;

$|++;

my $e = new elog;
my $db;
my $ELEMENT = [];
my $IE = {}; # invalid and empty

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %c = @_;
    map { $self->{lc($_)} = $c{$_} } keys %c;
    $db = $self->{db} || warn $e->warn( "Warning: db object not assigned" );
    $self->{ignore} = [];
    $self->{dh} = [];
    $self->{fs} = [];
    $self->{err} = [];

    if ($db) {
	$self->element;
    }

    die $e->die("source directory '$sdir' not exists") if !-e $sdir;
    die $e->die("target directory '$tdir' not exists") if !-e $tdir;

    return $self;
}

sub element {
    my $u = shift;
    $db ||= shift;
    $db || exit $e->plog("MF Error: db object not found");
    @$ELEMENT = arr2arr @{$db->element}, @$NEW;
    @$ELEMENT || $e->warn("TCM elements not found");
    @$ELEMENT || return [];
    $ELEMENT
}

sub ignore_element_message {
    my $u =shift;
    my $ignore_list = join ", ", @{$util::ignore};
    $ignore_list || return '';
    return "Ignored Element: $ignore_list\n";
}

sub seq_missing {
    my $u = shift;
    $db ||= shift;
    $db || die $e->die("Error: db object not found");
    my $files = $db->missing_seq;
    my $elements = $ELEMENT || $u->element;
    my $h = { elements => $elements };
    
    foreach my $em (@$elements) {
	if ($u->ignore($em)) {
	    $h->{$em} = 'ignored element';
	    $e->info("missing seqnum: element $em ignored")
	} else {
	    my @m = @{$files->{$em}};
	    my $nn = @m;
	    if ($nn) {
		$h->{send} = 1;
		$h->{missing}++;
		my $msg = "$nn missing seqnums detected on this element for %s minutes.";
		$h->{$em}->{message} = sprintf $msg, sys->{seq_alert};
		$h->{$em}->{list} = \@m;
		$h->{$em}->{missing} = $nn;
	    }
	}
    }

    return $h;
}

sub seq_missing_rank {
    my $u = shift;
    $db ||= shift;
    $db || die $e->die("Error: db object not found");
    my $files = $db->missing_seq;
    my $elements = $ELEMENT || $u->element;
    my $h = { elements => $elements };
    
    foreach my $em (@$elements) {
	if ($u->ignore($em)) {
	    $h->{$em} = 'ignored element';
	    $e->info("missing seqnum: element $em ignored")
	} else {
	    my @m = $u->m1($files->{$em});
	    my $nn = @m;
	    if ($nn) {
		$h->{send} = 1;
		$h->{missing}++;
		my $msg = "$nn missing seqnums detected on this element for %s minutes.";
		$h->{$em}->{message} = sprintf $msg, sys->{seq_alert};
		$h->{$em}->{list} = \@m;
		$h->{$em}->{missing} = $nn;
	    }
	}
    }

    return $h;
}

sub file_missing {
    my $u = shift;
    $db ||= shift;
    $db || die $e->die("Error: db object not found");
    my $files = $db->group_tcmfile;
    my $elements = $ELEMENT || $u->element;
    my $h = { elements => $elements };
    
    foreach my $em (@$elements) {
	if ($u->ignore($em)) {
	    $h->{$em} = 'ignored element';
	    $e->info("missing element: $em ignored")
	} else {
	    my $nn = $files->{$em}->[0];
	    if ($nn) {
		$h->{$em} = "$nn files transferred";
		$h->{total} += $nn
	    } else {
		$h->{send} = 1;
		$h->{missing}++;
		my $msg = "No files received on this element for %s minutes.";
		$h->{$em} = sprintf $msg, sys->{file_alert};
	    }
	}
    }

    return $h;
}

sub data {
    my $file = shift;

    if ($file =~ /.gz$/) {
	open(FILE, "gunzip -c $file |") || return $e->err("can't open pipe to $file");
    } else {
	open(FILE, $file) || return $e->err("can't open $file");
    }

    my @d = <FILE>;

    my $nn = @d || return 0;

    close FILE;
    my @data = ( @d[1..30], ('-'x120)."\n", @d[-30..-1] );
    return join('', @data);
}

sub dirs {
    my $u = shift;
    my $sd = shift || $sdir;
    $u->set("sd", $sd);
    opendir DIR, $sd || die $e->die( "$! - $sd" );
    my @dir = grep { -d "$sd/$_" && /^($prefix)/i } readdir(DIR);
    return [ sorting @dir ];
}

sub files {
    my $u = shift;
    my $sd = shift || $sdir;
    my $da = [];
    my @f = sorting grep { !-d && m{^($sd/[$xmlpre])}gi } glob "$sd/*";
    my $nn = @f;
    foreach my $f (@f) {
	my $h = {
	    f => $f,
	    t => $u->ut2dt((stat ($f))[9]),
	    i => $u->info($f,$sd),
	    d => $sd,
	    c => $nn,
	};

        my $msg;
	# immediate alert
	my @a = s2a report->{alert};
	foreach my $k (@a) {
	    if ($h->{i}->{$k}) {
		$msg = sprintf "File %s is found %s.", f($f), $k;
		$e->err($msg);
	    }
	}

	push @$da, $h;
    }
    $u->set(DA,$da);
    return $da;
}

sub file_info {
    my $f = shift;
    my $d = shift;
    my @a = $f =~ /.*?$xmlfmt.*?/gi;
    $f =~ s/$d\///g;
    my $hh = {
	filename => $f,
	fileseq => $a[0],
	filedt => "$a[3]/$a[2]/$a[1] $a[4]:$a[5]:$a[6]",
    };
    return $hh;
}
sub info {
    my $u = shift;
    my $f = shift;
    my $d = shift; # directory
    my $retry = shift || 0;
    my @k = qw/
	element
	seqnum
	cdrnum
	createtime
    /;
    my $h;
    my $data = data $f;
    # valid xml: default = valid 
    $h->{vx} = 1; 

    $ELEMENT ||= $u->element;

    foreach my $k (@k) {
	my $r = regx->{$k};
	my $m = $data =~ /$r/is;
	my $v = $m ? $1 : $m;
	if ($v) {
	    $h->{$k} = $v;
	}

	if ($data) {
	    if ($h->{vx}) {
		# valid xml content
		$h->{vx} = $v ? 1 : 0; 
	    }
	} else {
	    # empty file
	    $h->{empty} = 1; 
	}

	if ($k eq 'element') {
	    my @a = arr2arr @$need, @$ELEMENT;
	    my $em = $h->{$k};
	    if (grep( /$em/, @a )) {
		$h->{new} = 0;
	    } else {
		$h->{new} = 1;
		push @$ELEMENT, $h->{$k};
	    }
	}

    }

    if ($h->{empty} || !$h->{vx}) {
	my $r = file->{retry} || 3;
	my $s = file->{sleeptime} || 3;
	
	$IE->{f($f)} = $h->{empty} ? ucfirst stc->{empty} : ucfirst stc->{invalid};

	if (++$retry <= $r and -e $f) {
	    $e->plog($e->f("- %s File: %s - try #$retry, waiting for $s sec", $IE->{f($f)}, f($f)),'warn');
	    sleep $s;
	    my $ff = f($f);
	    return $u->info($f, $d, $retry);
	} 
    }
    # log notify if empty or invalid files loaded or become valid 
    if (my $r = $IE->{f($f)}) {
	# empty to load
	if (!$h->{empty} and stc->{empty} =~ /$r/i) { 
	    $e->plog($e->f("- %s %s File - update status empty to load!", $r, f($f)));
	    delete $h->{empty};
	    $h->{load} = 1;
	} 
	# invalid to pass due to imcomplete loading
	if ($h->{vx} and stc->{invalid} =~ /$r/i) {
	    $e->plog($e->f("- %s %s File - update status invalid to pass!", $r, f($f)));
	    delete $h->{vx};
	    $h->{pass} = 1;
	}
	delete $IE->{f($f)};
    }

    if (defined $h->{vx}) {
	$h->{invalid} = 1 if not $h->{vx};
    }

    $h->{file} = file_info $f, $d;
    return $h;
}

sub f {
    my $f = shift;
    $f =~ s/$sdir\///gi;
    return $f;
}

sub cp {
    my $u = shift;
    my $da = shift || $u->get(DA);
    $u->clserr;
    @$da || return $u->reterr( "invalid dir array" ); 
    my $td = shift || $tdir; # target directory
    $u->set("td", $td);
    foreach my $h (@$da) {
	my $f = $h->{f};
	eval { 
	    copy( $f, "$td/." ) || 
	    return $u->reterr( "cannot copy $f to $td/." )
	};
	if ($@) {
	    $u->seterr( "$@ - $f" );
	    return 0;
	}
    }
    return 1;
}

sub mv {
    my $u = shift;
    my $da = shift || [];
    $u->clserr;
    @$da || return $u->reterr( "invalid dir array" ); 
    my $td = shift || $tdir; # target directory
    $u->set("td", $td);
    foreach my $h (@$da) {
	my $f = $h->{f};
	eval { 
	    move( $f, "$td/." ) || 
	    return $u->reterr( "cannot move $f to $td/." );
	};
	if ($@) {
	    return $u->reterr( "$@ - $f" );
	}
    }
    return 1;
}

sub restore {
    my $u = shift;
    my $da = shift || [];
    $u->clserr;
    @$da || return $u->reterr( "invalid dir array" ); 
    # change source to target 
    my $td = shift || $sdir; 
    $u->set("td", $td);
    foreach my $h (@$da) {
	my $f = $h->{f};
	eval { 
	    copy( $f, "$td/." ) ||
		return $u->reterr( "cannot copy $f $td/.\n" ); 
	};
	if ($@) {
	    return $u->reterr( $@ );
	}
    }
    return 1;
}

sub ok {
    my $u = shift;
    my $da = shift || [];
    @$da || return $u->reterr( "empty diretory array, no files found - it's OK..." ); 
    $u->clserr;
    my @a;
    foreach my $h (@$da) {
	my $em = $h->{i}->{element};
	if ($u->ignore( $em )) {
	    $h->{i}->{ignored} = 1;
	} else {
	    $h->{i}->{ignored} = 0;
	}
	push @a, $h;
    }
    # grouped the errors
    if (scalar @{$u->{ignore}}) {
        $e->info( "Equip ID: [".join(', ', @{$u->{ignore}})."] ignored" );
    }
    $u->set(DA, \@a);
    return 1;
}

sub trans {
    my $u = shift;
    $db ||= shift;
    $db || exit $e->plog("MF Error: db object not found");

    $u->{ha} = {};
    $u->{cc} = {};

    foreach my $h (@{$u->{da}}) {
	my $t = dbc->{tcmfile};
	my $ih = $h->{i}; # info hash
	my $fh = $h->{i}->{file}; # file info hash
	my $id = $ih->{id} = $db->nextid($t)->{id};
	$id || die $e->die("ID not generated");
	my @c = (split ',',table->{tcmfile});
	my @v = ( 
	    (map { $ih->{$c[$_]} } (0..3)), 
	    (map { $fh->{$c[$_]} } (4..6)), 
	    $h->{t} 
	);

	my $element = $ih->{element};
	my $seqnum  = $ih->{seqnum};

	# insert into tcmfile
	my $r = $db->tcmfile($id, \@v);

	$u->{cc}->{collected}++;

	if ($r) {
	    $u->{cc}->{tcmfile}++;
	    $e->db("1. $element: insert into tcmfile");
	} else {
	    $u->{cc}->{tcmdump}++;
	    $e->dump("1. $fh->{filename}(ID: $id) - ".$db->errstr);
	}

	if ($element) {
	    push @{$u->{ha}->{$element}}, $seqnum;
	}
	
	$ih->{ignored} && $u->{cc}->{ignored}++;

	# insert into stat
	my $s = {
	    em => $ih->{empty} ? stc->{empty} : 0,
	    lo => $ih->{load} ? stc->{load} : 0,
	    in => $ih->{invalid} ? stc->{invalid} : 0,
	    pa => $ih->{pass} ? stc->{pass} : 0,
	    ne => $ih->{new} && $element ? stc->{new} : 0,
	    ig => $ih->{ignored} ? stc->{ignored} : 0,
	};
	foreach my $k (keys %$s) {
	    $s->{$k} || next;
	    my $p = [ $id, $element, $seqnum, $s->{$k} ];
	    my $r = $db->tcmstat($id, $p);

	    if ($ih->{$s->{$k}}) {
		$u->{cc}->{$s->{$k}}++;
		$e->info("- ID $id: $s->{$k} XML file - $fh->{filename}");
	    }

	    if ($r) {
		$e->db("2. $element(ID: $id) - inserted into tcmstat");
		$u->{cc}->{tcmstat}++;
	    } else {
		$e->dump("2. $element(ID: $id): [".join(',',@$p)."] - ".$db->errstr);
	    }
	}
	$u->{cc}->{element}++;
    }

    # list the element seqnum array
    $e->dump("element list: ".Dumper($u->{ha}));
}

sub missing_found {
    my $u = shift;
    $db ||= shift;
    $db || exit $e->plog("MF Error: db object not found");

    my $regx = s2r xml->{ignore};
    # missing or found/present

    # hash of all element seqnums
    my $esh = $db->element_seq;

    foreach my $em (sorting keys %{$u->{ha}}) {
	if ($regx && $em =~ /$regx/i) {
	    next;
	}

	$esh->{$em} ||= [];
	# missing seqnum list
	my @seq = arr2arr ( @{$u->{ha}->{$em}}, @{$esh->{$em}} );
	$e->dump("RAW SEQNUM LIST: ".Dumper \@seq);
	my @a = @seq;
	my @m = $u->m1([ @a ]);

	$e->dump("ALL SEQNUM of $em: ".Dumper(\@a));

	my $nn = @m;
	if ($nn > 20) {
	    $e->err("Error: too many missing seqnums - $nn found, talk to engineers to fix this issue");
	    next
	}

	# checking missing status
	foreach my $sn (@m) {
	    my $s;
	    if (grep /$sn/, @m) {
		$s = stc->{missing};
	    }
	    $s || next;
	    my $p = [ 0, $em, $sn, $s ];
	    my $r = $db->tcmstat($sn, $p);
	    if ($r) {
		$u->{cc}->{missing}++;
		$e->db("3. $em(SN: $sn) - inserted into tcmstat");
		$u->{cc}->{tcmstat}++;
	    } else {
		$e->dump("3. $em(SN: $sn): [".join(',',@$p)."] - ".$db->errstr);
	    }
	}

	# checking found status
	foreach my $sn (@{$u->{ha}->{$em}}) {
	    my $s;
	    if ($db->exists_seq($em,$sn)) {
		$s = stc->{found};
	    }
	    $s || next;
	    my $p = [ 0, $em, $sn, $s ];
	    my $r = $db->tcmstat($sn, $p);
	    if ($r) {
		$u->{cc}->{found}++;
		$e->db("3. $em(SN: $sn) - inserted into tcmstat");
		$u->{cc}->{tcmstat}++;
	    } else {
		$e->dump("3. $em(SN: $sn): [".join(',',@$p)."] - ".$db->errstr);
	    }
	}

    }
}

# coverage counter
sub cc {
    my $u = shift;
    # my @k = qw/collected tcmfile tcmdump tcmstat empty load invalid pass ignored found missing/;
    my @cc = s2a report->{cc};
    foreach my $k (@cc) {
	my $count = $u->{cc}->{$k} || '0';
	$e->plog(" .\ttotal $k: $count");
    }
}

# report content 
sub rc {
    my $u = shift;
    my $type = shift;
    my $stid = shift;
    $db ||= shift;
    $db || exit $e->plog("RC Error: db object not found");

    my $c = '';
    my @list;

    my $h;
    if ($stid) {
	$h = $db->daily_stat_id($type);
    } else {
	$h = $db->daily_stat_list($type);
    }

    foreach my $k (sorting keys %$h) {
	my $nn = scalar( @{$h->{$k}} );
	push @list, "$k: $nn found";
    }

    $c .= report->{$type}."\n";
    if (@list) {
	$c .= join "\n", @list;
    } else {
	$c .= "No $type elements found\n";
    }

    $c .= "\n\n";

    return $c;
}

# missing method 2
sub m2 {
    my $u = shift;
    my $a = shift;
    $a = [ sort @$a ];
    my %h = ();
    my @m = ();
    @h{@$a} = ();
    my $s = $a->[0];
    while ( $s <= $a->[-1] ) {
	exists $h{$s} || push(@m, $s);
        $s++;
    }
    @m;
}
# missing method 1
sub m1 {
    my $u = shift;
    my $a = shift || [];
    $a = [ sort @$a ];
    $e->dump("The seqnum list for missing: ".Dumper( $a ));
    my @m = map { 
	(@$a[$_-1]+1)..(@$a[$_]-1) 
    } 1..@$a;
    $e->dump("Missing:\n".Dumper( \@m ));
    @m
}


sub ignore {
    my $u = shift;
    my $em = shift;
    return grep( /$em/, @$ignore ) 
}
sub filter {
    my $u = shift;
    my $e = shift;
    @$filter || return 1;
    map { return 1 if $e =~ /$_/i } @$filter; 
    return 0;
}

sub total {
    my $u = shift;
    @{$u->{da}} || return 0;
    return @{$u->{da}}+0;
}

sub ut2dt {
    my $u = shift;
    my $ut = shift || time;
    my $dt = strftime(fmt->{dt}, localtime($ut));
    return $dt;
}
sub now {
    my $u = shift;
    return $u->ut2dt;
}
sub time {
    my $u = shift;
    return strftime(fmt->{t}, localtime(time));
}

sub _gettime {
    return [ gettimeofday ];
}

sub _timediff {
    my $t1 = shift || _gettime;
    my $diff = abs(tv_interval($t1, $t2));
    $t2 = _gettime;
    return $diff;
}


sub dhinfo {
    my $u = shift;
    my $msg = shift;
    @{$u->{dh}} || return "no dh info found";
    my $info = join ", ", map { "$_->{d}: $_->{c}" } @{$u->{dh}};
    return ($msg ? "$msg: " : '')."[$info] processed";
}

sub set {
    my ($u, $k, $v) = @_;
    $u->{$k} = $v;
}
sub get {
    my ($u, $k) = @_;
    return $u->{$k};
}
sub push {
    my ($u, $k, $v) = @_;
    push @{$u->{$k}}, $v;
}

sub clserr {
    my $u = shift;
    $u->set("err", undef);
    $u->set("errstr", '');
}

sub seterr {
    my $u = shift;
    $u->push('err', shift);
}
sub geterr {
    my $u = shift;
    return $u->{err}; 
}
sub reterr {
    my $u = shift;
    my $msg = shift;
    $u->seterr( $msg ); 
    return 0
}

sub err {
    my $u = shift;
    $u->{err} && return 1;
    return 0;
}

sub errstr {
    my $u = shift;
    $u->{err} || return undef;
    return join ", ", @{$u->{err}};
}

sub die {
    my $u = shift;
    print Dumper $u;
    die shift;
}

sub gen {
    return md5_hex( shift );
}

sub keygen {
    my $dh = shift;
    my $keys = shift;
    my $k = join "", 
	    map { Dumper $dh->{$_} } 
	    @$keys;
    return gen($k);
}

sub plus {
    my $no = shift;
    return sprintf "%03d", substr(++$no, -($TSN));
}

sub p {
    print '-'x90,"\n";
    print @_;
    print '-'x90,"\n";
}

sub pp {
    print @_,"\n"
}

1;

__END__
