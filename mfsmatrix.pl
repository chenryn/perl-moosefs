#!/usr/bin/env perl
use strict;
use warnings;
use IO::Socket::INET;
use Data::Dumper;
use 5.012;

sub myrecv {
my ($socket, $len) = @_;
    my $msg = '';
    while ( length($msg) < $len ) {
        my $chunk;
        sysread $socket, $chunk, $len-length($msg);
        die "Socket Close." if $chunk eq '';
        $msg .= $chunk;
    }
    return $msg;
};

my $s = IO::Socket::INET->new(
              PeerAddr=>'10.23.16.104',
              PeerPort=>9421,
              Proto=>"tcp",
);
my ($header, $data);

print $s pack('(LL)>', 510, 0);
$header = myrecv($s, 8);
my ($cmd, $length) = unpack('(LL)>', $header);
# say $cmd, $length; # 511 76
$data = myrecv($s, $length);
my ($v1, $v2, $v3, $memusage, $total, $avail, $trspace, $trfiles, $respace, $refiles, $nodes, $dirs, $files, $chunks, $allcopies, $tdcopies) = unpack('(SCCQQQQLQLLLLLLL)>', $data);
if ($v2 > 5 and $v3 > 9) {
    print $s pack('(LLS)>', 516, 1, 0);
} elsif ($v2 > 4 and $v3 > 12) {
    print $s pack('(LL)>', 516, 0);
} else {
    die 'Too old version';
};
my $nheader = myrecv($s, 8);
my $info = [];
my ($ncmd, $nlength) = unpack('(LL)>', $nheader);
if ($ncmd == 517 and $nlength == 484) {
    for my $i ( 0 .. 10 ) {
        my $ndata = myrecv($s, 44);
        push @$info, [ unpack("(LLLLLLLLLLL)>", $ndata) ];
    };
};

print Dumper $info;
