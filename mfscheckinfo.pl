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

print $s pack('(LL)>', 512, 0);
$header = myrecv($s, 8);
my ($cmd, $length) = unpack('(LL)>', $header);
if ( $cmd == 513 and $length >= 36 ) {
    $data = myrecv($s, $length);
    my $d = substr($data, 0, 36);
    my ($loopstart, $loopend, $files, $ugfiles, $mfiles, $chunks, $ugchunks, $mchunks, $msgbuffleng) = unpack('(LLLLLLLLL)>', $d);
    my ($messages, $truncated);
    if ($loopstart > 0) {
        if ($msgbuffleng > 0 ) {
            if ($msgbuffleng == 100000) {
                $truncated = 'first 100k';
            } else {
                $truncated = 'no';
            };
            $messages = substr($data, 36);
        };
    } else {
        $messages = 'no data';
    };
    my $info = {
        check_loop_start_time => $loopstart,
        check_loop_end_time => $loopend,
        files => $files,
        under_goal_files => $ugfiles,
        missing_files => $mfiles,
        chunks => $chunks,
        under_goal_chunks => $ugchunks,
        missing_chunks => $mchunks,
        msgbuffleng => $msgbuffleng,
        important_messages => $messages,
        truncated => $truncated,
    };
    print Dumper $info;
}
