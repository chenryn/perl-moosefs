package MooseFS::Matrix;
use strict;
use warnings;
use IO::Socket::INET;
use Moo;

extends 'MooseFS';

sub _get_matrix {
    my $self = shift;
    my $s = IO::Socket::INET->new(
        PeerAddr => $self->masterhost,
        PeerPort => $self->masterport,
        Proto    => 'tcp',
    );
    print $s pack('(LL)>', 510, 0);
    my $header = $self->myrecv($s, 8);
    my ($cmd, $length) = unpack('(LL)>', $header);
    my $data = $self->myrecv($s, $length);
    my ($v1, $v2, $v3, $memusage, $total, $avail, $trspace, $trfiles, $respace, $refiles, $nodes, $dirs, $files, $chunks, $allcopies, $tdcopies) = unpack('(SCCQQQQLQLLLLLLL)>', $data);
    
    if ($v2 > 5 and $v3 > 9) {
        print $s pack('(LLS)>', 516, 1, 0);
    } elsif ($v2 > 4 and $v3 > 12) {
        print $s pack('(LL)>', 516, 0);
    } else {
        die 'Too old version';
    };
    my $nheader = $self->myrecv($s, 8);
    my $info = [];
    my ($ncmd, $nlength) = unpack('(LL)>', $nheader);
    if ($ncmd == 517 and $nlength == 484) {
        for my $i ( 0 .. 10 ) {
            my $ndata = $self->myrecv($s, 44);
            push @$info, [ unpack("(LLLLLLLLLLL)>", $ndata) ];
        };
    };
    return $info;
};

1;
