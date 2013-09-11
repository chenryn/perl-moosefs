#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Data::Dumper;
use lib '../lib';

BEGIN {
    use_ok( 'MooseFS::ChunkInfo' ) || print "Bail out!\n";
}

my $mfs = MooseFS::ChunkInfo->new(
    masterhost => '10.5.16.155'
);
print Dumper $mfs->chunk_info;

done_testing;
