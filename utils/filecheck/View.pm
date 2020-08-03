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
    print _formatMessage($message), "\n";
}

sub showSearchStart {
    my ($self, $tcSearch, $message) = @_;
    print _formatMessage($message), "\n" if $message;
}

sub showSearchDone {
    my ($self, $tcSearch, $stats, $message) = @_;
    print _formatMessage($message), "\n" if $message;
}

sub showPartitionSearchStart {
    my ($self, $partition, $message) = @_;
    printf "╭╴%s\n", $partition;
    printf "╞> %s\n", _formatMessage($message) if $message;
}

sub showPartitionSearchDone {
    my ($self, $partition, $stats, $message) = @_;
    printf "╞> %s\n", _formatMessage($message) if $message;
    printf "╰╴%s\n", format_bytes($stats->{size});
}

sub showDirSearchStart {
    my ($self, $dir, $stat, $message) = @_;
    $self->{dir} = $dir;
    $self->{dirMessage} = $message;

    if ($message) {
        $self->_showDirHeader;
    } else {
        $self->{shownDirHeader} = 0;
    }
}

sub showDirSearchDone {
    my ($self, $dir, $stats, $message) = @_;

    printf "│╰╴%s\n", $dir->{path} if $self->{shownDirHeader};
    printf "╞> %s\n", _formatMessage($message) if $message;
}

sub showResult {
    my ($self, $file, $stat, $message) = @_;

    if ($stat->{isDir}) {
        printf "│%s\n", $file->{path};
        printf "╞> %s\n", _formatMessage($message) if $message;
        return;
    }

    $self->_showDirHeader if ! $self->{shownDirHeader};
    printf "││%4.4s %s\n", format_bytes($stat->{size}), $file->{path};
    printf "│╞> %s\n", _formatMessage($message) if $message;
}

sub _showDirHeader {
    my $self = shift;
    printf "├┬╴%s\n", $self->{dir}{path};
    printf "│╞> %s\n", _formatMessage($self->{dirMessage}) if $self->{dirMessage};
    $self->{shownDirHeader} = 1;
}

sub _formatMessage {
    my $message = shift;
    return $message if ! ref $message;
    return $message->{error}
        || $message->{warn}
        || $message->{info}
        || $message->{debug}
        || $message;
}

1;
