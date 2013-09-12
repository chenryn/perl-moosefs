package MooseFS::Info;
use strict;
use warnings;
use IO::Socket::INET;
use Moo;

extends 'MooseFS';

has info => (
    is => 'ro',
    lazy => 1,
    builder => '_get_info',
);

has version => (
    is => 'ro',
    default => sub { shift->info->{version} }
);

sub _get_info {
    my $self = shift;
    my $s = $self->sock;
    print $s pack('(LL)>', 510, 0); 
    my $header = $self->myrecv($s, 8); 
    my ($cmd, $length) = unpack('(LL)>', $header);
    my $data = $self->myrecv($s, $length);
    my ($v1, $v2, $v3, $memusage, $total, $avail, $trspace, $trfiles, $respace, $refiles, $nodes, $dirs, $files, $chunks, $allcopies, $tdcopies) = unpack('(SCCQQQQLQLLLLLLL)>', $data); 
    close($s);
    return {
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
};

1;
