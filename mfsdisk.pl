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
my $HDtime = 'max';
my $HDperiod ='min';

print $s pack('(LL)>', 500, 0);
$header = myrecv($s, 8);
my ($cmd, $length) = unpack('(LL)>', $header);
# say $cmd, $length; # 501 216
if ( $cmd == 501 and $length % 54 == 0 ) {
    $data = myrecv($s, $length);
    for my $num ( 0 .. $length / 54 - 1 ) {
        my $d = substr($data, $num*54, 54);
        my ($v1, $v2, $v3, $ip1, $ip2, $ip3, $ip4, $port, $used, $total, $chunks, $tdused, $tdtotal, $tdchunks, $errcnt) = unpack('(SCCCCCCSQQLQQLL)>', $d);
        my $ip  = "$ip1.$ip2.$ip3.$ip4";
        if ( $v2 > 5 and $v3 > 8 ) {
            my $ns = IO::Socket::INET->new(
                PeerAddr => $ip,
                PeerPort => $port,
                Proto => 'tcp',
            );
            print $ns pack('(LL)>', 600, 0);
            my $nheader = myrecv($ns, 8);
            my ($ncmd, $nlength) = unpack('(LL)>', $nheader);
            if ( $ncmd == 601 ) {
                my $data = myrecv($ns, $nlength);
                while ( $nlength > 0 ) {
                    my ($entrysize) = unpack("S>", substr($data, 0, 2));
                    my $entry = substr($data, 2, $entrysize);
                    $data = substr($data, 2+$entrysize);
                    $nlength -= 2 + $entrysize;
                
                    my $plen = ord(substr($entry, 0, 1));
                    my $ip_path = sprintf "%s:%u:%s", $ip, $port, substr($entry, 1, $plen);
                    my ($flags, $errchunkid, $errtime, $used, $total, $chunkscnt) = unpack("(CQLQQL)>", substr($entry, $plen+1, 33));
                    my ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $usecfsyncsum, $rops, $wops, $fsyncops, $usecreadmax, $usecwritemax, $usecfsyncmax);

                    if ($entrysize == $plen + 34 + 144 ) {
                
                        if ($HDperiod eq 'min' ) {
                            ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $rops, $wops, $usecreadmax, $usecwritemax) = unpack("(QQQQLLLL)>", substr($entry, $plen+34, 48));
                        } elsif ($HDperiod eq 'hour') {
                            ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $rops, $wops, $usecreadmax, $usecwritemax) = unpack("(QQQQLLLL)>", substr($entry, $plen+34+48, 48));
                        } elsif ($HDperiod eq 'day') {
                            ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $rops, $wops, $usecreadmax, $usecwritemax) = unpack("(QQQQLLLL)>", substr($entry, $plen+34+48+48, 48));
                        }
                
                    } elsif ( $entrysize == $plen + 34 + 192 ) {
                
                        if ($HDperiod eq 'min' ) {
                            ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $usecfsyncsum, $rops, $wops, $fsyncops, $usecreadmax, $usecwritemax, $usecfsyncmax) = unpack("(QQQQQLLLLLL)>", substr($entry, $plen+34, 64));
                        } elsif ($HDperiod eq 'hour') {
                            ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $usecfsyncsum, $rops, $wops, $fsyncops, $usecreadmax, $usecwritemax, $usecfsyncmax) = unpack("(QQQQQLLLLLL)>", substr($entry, $plen+34+64, 64));
                        } elsif ($HDperiod eq 'day') {
                            ($rbytes, $wbytes, $usecreadsum, $usecwritesum, $usecfsyncsum, $rops, $wops, $fsyncops, $usecreadmax, $usecwritemax, $usecfsyncmax) = unpack("(QQQQQLLLLLL)>", substr($entry, $plen+34+64+64, 64));
                        }
                
                    }
                
                    my ($rtime, $wtime, $fsynctime);
                    if ($HDtime eq 'avg') {
                        if ($rops > 0) {
                            $rtime = $usecreadsum/$rops;
                        } else {
                            $rtime = 0;
                        };
                
                        if ($wops > 0) {
                            $wtime = $usecwritesum/$wops;
                        } else {
                            $wtime = 0;
                        };
                
                        if ($fsyncops > 0) {
                            $fsynctime = $usecfsyncsum/$fsyncops;
                        } else {
                            $fsynctime = 0;
                        };
                    } else {
                        $rtime = $usecreadmax;
                        $wtime = $usecwritemax;
                        $fsynctime = $usecfsyncmax;
                    };
                
                    my $status;
                    if ($flags == 1) {
                        $status = 'marked for removal';
                    } elsif ($flags == 2) {
                        $status = 'damaged';
                    } elsif ($flags == 3) {
                        $status = 'damaged, marked for removal';
                    } else {
                        $status = 'ok';
                    };
                
                    my $lerror;
                    if ($errtime == 0 and $errchunkid == 0) {
                        $lerror = 'no errors';
                    } else {
                        $lerror = localtime($errtime);
                    };
                
                    my $rbsize = $rops > 0 ? $rbytes / $rops : 0;
                    my $wbsize = $wops > 0 ? $wbytes / $wops : 0;
                    my $percent_used = $total > 0 ? ($used * 100.0) / $total : '-';
                    my $rbw = $usecreadsum > 0 ? $rbytes * 1000000 / $usecreadsum : 0;
                    my $wbw = $usecwritesum + $usecfsyncsum > 0 ? $wbytes *1000000 / ($usecwritesum + $usecfsyncsum) : 0;
                
                    my $info = {
                        ip_path => $ip_path,
                        flags => $flags,
                        errchunkid => $errchunkid,
                        errtime => $errtime,
                        used => $used,
                        total => $total,
                        chunkscount => $chunkscnt,
                        rbw => $rbw,
                        wbw => $wbw,
                        rtime => $rtime,
                        wtime => $wtime,
                        fsynctime => $fsynctime,
                        read_ops => $rops,
                        write_ops => $wops,
                        fsyncops => $fsyncops,
                        read_bytes => $rbytes,
                        write_bytes => $wbytes,
                        usecreadsum => $usecreadsum,
                        usecwritesum => $usecwritesum,
                        status => $status,
                        lerror => $lerror,
                        rbsize => $rbsize,
                        wbsize => $wbsize,
                        percent_used => $percent_used,
                    };
                    print Dumper $info;
                };
            }
        }
    }
}
