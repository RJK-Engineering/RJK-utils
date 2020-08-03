package PrintView;

use strict;
use warnings;

use Number::Bytes::Human qw(format_bytes);

sub new {
    my $self = bless {}, shift;
    return $self;
}

sub showMessage {
    my ($self, $message) = @_;
    $self->_writeMessage($message);
}

sub showSearchStart {
    my ($self, $tcSearch, $message) = @_;
    $self->_writeMessage($message) if $message;
}

sub showSearchDone {
    my ($self, $tcSearch, $stats, $message) = @_;
    $self->_writeMessage($message) if $message;
}

sub showPartitionSearchStart {
    my ($self, $partition, $message) = @_;

    print "+- ";
    print "$partition\n";

    if ($message) {
        print "|> ";
        $self->_writeMessage($message);
    }
}

sub showPartitionSearchDone {
    my ($self, $partition, $stats, $message) = @_;

    if ($message) {
        print "|> ";
        $self->_writeMessage($message);
    }

    print "+- ";
    print format_bytes($stats->{size}) . "\n";
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

    if ($self->{shownDirHeader}) {
        print "|+- ";
        print format_bytes($stats->{size}) . "\n";
    }

    if ($message) {
        print "|> ";
        $self->_writeMessage($message);
    }
}

sub showResult {
    my ($self, $file, $stat, $message) = @_;

    if ($stat->{isDir}) {
        print "|";
        print "$file->{path}\n";
    } else {
        $self->_showDirHeader if ! $self->{shownDirHeader};
        print "||";
        print sprintf " %4.4s ", format_bytes $stat->{size};
        print "$file->{path}\n";
    }

    if ($message) {
        print "|" if ! $stat->{isDir};
        print "|> ";
        $self->_writeMessage($message);
    }
}

sub _showDirHeader {
    my $self = shift;

    print "|+- ";
    print "$self->{dir}{path}\n";

    if ($self->{dirMessage}) {
        print "||> ";
        $self->_writeMessage($self->{dirMessage});
    }
    $self->{shownDirHeader} = 1;
}

sub _writeMessage {
    my ($self, $message) = @_;

    if (ref $message) {
        if ($message->{error}) {
            print $message->{error};
        } elsif ($message->{warn}) {
            print $message->{warn};
        } elsif ($message->{info}) {
            print $message->{info};
        } elsif ($message->{debug}) {
            print $message->{debug};
        }
    } else {
        print $message;
    }
    print "\n";
}

1;
