package View;

use strict;
use warnings;

use Number::Bytes::Human qw(format_bytes);

sub new {
    my $self = bless {}, shift;
    #~ $self->{} = shift;
    return $self;
}

sub showMessage {
    my ($self, $message) = @_;
    print "$message\n";
}

sub showParitionSearchStart {
    my ($self, $partition) = @_;
    print "╭╴$partition\n";
}

sub showParitionSearchDone {
    my ($self, $partition, $size) = @_;
    printf "╰╴%s\n", format_bytes($size);
}

sub showResult {
    my ($self, $file, $stat, $result) = @_;
    if ($stat->{isDir}) {
        printf "│%4.4s %s\n", "", $file->{path};
    } else {
        printf "│%4.4s %s\n", format_bytes($stat->{size}), $file->{path};
    }
}

1;
