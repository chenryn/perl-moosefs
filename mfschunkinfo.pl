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

print $s pack('(LL)>', 514, 0);
$header = myrecv($s, 8);
my ($cmd, $length) = unpack('(LL)>', $header);
if ( $cmd == 515 and $length == 52 or $length == 76 ) {
    $data = myrecv($s, $length);
    my $d = substr($data, 0, 52);
    my ($loopstart, $loopend, $del_invalid, $ndel_invalid, $del_unused, $ndel_unused, $del_dclean, $ndel_dclean, $del_ogoal, $ndel_ogoal, $rep_ugoal, $nrep_ugoal, $rebalance) = unpack('(LLLLLLLLLLLLL)>', $d);
    my $info = {
        loop_start => $loopstart,
        loop_end => $loopend,
        invalid_deletions => $del_invalid,
        invalid_deletions_out_of => $del_invalid+$ndel_invalid,
        unused_deletions => $del_unused,
        unused_deletions_out_of => $del_unused+$ndel_unused,
        disk_clean_deletions => $del_dclean,
        disk_clean_deletions_out_of => $del_dclean+$ndel_dclean,
        over_goal_deletions => $del_ogoal,
        over_goal_deletions_out_of => $del_ogoal+$ndel_ogoal,
        replications_under_goal => $rep_ugoal,
        replications_under_goal_out_of => $rep_ugoal+$nrep_ugoal,
        replocations_rebalance => $rebalance,
    };
    print Dumper $info;
}
