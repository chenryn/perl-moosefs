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
              PeerAddr=>'10.5.16.155',
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

my $info = {
     version => "$v1.$v2.$v3",
     total_space => $total,
     avail_space => $avail,
     trash_space => $trspace,
     trash_files => $trfiles,
     reserved_space => $respace,
     reserved_files => $refiles,
     all_fs_objects => $nodes,
     directories => $dirs,
     files => $files,
     chunks => $chunks,
     all_chunk_copies => $allcopies,
     regular_chunk_copies => $tdcopies,
     memusage => $memusage,
};
say Dumper $info;
