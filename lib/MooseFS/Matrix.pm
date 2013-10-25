package MooseFS::Matrix;
use strict;
use warnings;
use IO::Socket::INET;
use MooseFS::Communication;
use Moo;

extends 'MooseFS';

has info => (
    is => 'rw',
    default => sub { [] }
);
 
sub BUILD {
    my $self = shift;
    my $ver = $self->masterversion;
    my $s = $self->sock;
    if ($ver > 1509) {
        print $s pack('(LLS)>', CLTOMA_CHUNKS_MATRIX, 1, 0);
    } elsif ($ver > 1412) {
        print $s pack('(LL)>', CLTOMA_CHUNKS_MATRIX, 0);
    } else {
        die 'Too old version';
    };
    my $nheader = $self->myrecv($s, 8);
    my ($ncmd, $nlength) = unpack('(LL)>', $nheader);
    if ($ncmd == MATOCL_CHUNKS_MATRIX and $nlength == 484) {
        for my $i ( 0 .. 10 ) {
            my $ndata = $self->myrecv($s, 44);
            push @{ $self->info }, [ unpack("(LLLLLLLLLLL)>", $ndata) ];
        };
    };
    for  my $goal ( 0 .. $#{ $self->info } ) {
        has "goal$goal" => (is => 'ro', lazy => 1, default => sub {
             my $self = shift;
             my $info;
             for my $valid ( 0 .. $#{ $self->info->[$goal] } ) {
                 $info->{"valid$valid"} = $self->info->[$goal]->[$valid];
             };
             return $info;
        });
    };
};

1;
