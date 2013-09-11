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

print $s pack('(LL)>', 500, 0);
$header = myrecv($s, 8);
my ($cmd, $length) = unpack('(LL)>', $header);
# say $cmd, $length; # 501 216
if ( $cmd == 501 and $length % 54 == 0 ) {
    $data = myrecv($s, $length);
    for my $num ( 0 .. $length / 54 - 1 ) {
        my $d = substr($data, $num*54, 54);
        my ($v1, $v2, $v3, $ip1, $ip2, $ip3, $ip4, $port, $used, $total, $chunks, $tdused, $tdtotal, $tdchunks, $errcnt) = unpack('(SCCCCCCSQQLQQLL)>', $d);
        my $ver = "$v1.$v2.$v3";
        my $ip  = "$ip1.$ip2.$ip3.$ip4";
        my $percent = $total > 0 ? ($used * 100)/$total : '';
        my $tdpercent = $tdtotal > 0 ? ($tdused * 100)/$tdtotal : '';
        my $info = {
             version => $ver,
             ip => $ip,
             port => $port,
             used => $used,
             total => $total,
             chunks => $chunks,
             percent_used => $percent,
             tdused => $tdused,
             tdtotal => $tdtotal,
             tdchunks => $tdchunks,
             tdpercent_used => $tdpercent,
             errcnt => $errcnt,
        };
        say Dumper $info;
    }

}
