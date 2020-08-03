package View;

use strict;
use warnings;

use Number::Bytes::Human qw(format_bytes);
use Win32::Console;
Win32::Console::OutputCP(65001);

sub new {
    my $self = bless {}, shift;
    $self->{console} = new Win32::Console(STD_OUTPUT_HANDLE);
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
    my $c = $self->{console};

    $c->Attr($FG_WHITE);
    $c->Write("╭╴");
    $c->Attr($FG_LIGHTRED);
    $c->Write("$partition\n");
    $c->Attr($ATTR_NORMAL);

    if ($message) {
        $c->Write("╞> ");
        $self->_writeMessage($message);
    }
}

sub showPartitionSearchDone {
    my ($self, $partition, $stats, $message) = @_;
    my $c = $self->{console};

    if ($message) {
        $c->Attr($FG_WHITE);
        $c->Write("╞> ");
        $c->Attr($ATTR_NORMAL);
        $self->_writeMessage($message);
    }

    $c->Attr($FG_WHITE);
    $c->Write("╰╴");
    $c->Attr($ATTR_NORMAL);
    $c->Write(format_bytes($stats->{size}) . "\n");
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
    my $c = $self->{console};

    if ($self->{shownDirHeader}) {
        $c->Attr($FG_WHITE);
        $c->Write("│╰╴");
        $c->Attr($ATTR_NORMAL);
        $c->Write(format_bytes($stats->{size}) . "\n");
    }

    if ($message) {
        $c->Attr($FG_WHITE);
        $c->Write("╞> ");
        $c->Attr($ATTR_NORMAL);
        $self->_writeMessage($message);
    }
}

sub showResult {
    my ($self, $file, $stat, $message) = @_;
    my $c = $self->{console};

    if ($stat->{isDir}) {
        $c->Attr($FG_WHITE);
        $c->Write("│");
        $c->Attr($FG_BLUE);
        $c->Write("$file->{path}\n");
        $c->Attr($ATTR_NORMAL);
    } else {
        $self->_showDirHeader if ! $self->{shownDirHeader};
        $c->Attr($FG_WHITE);
        $c->Write("││");
        $c->Attr($ATTR_NORMAL);
        $c->Write(sprintf " %4.4s ", format_bytes $stat->{size});
        $c->Write("$file->{path}\n");
    }

    if ($message) {
        $c->Attr($FG_WHITE);
        $c->Write("│") if ! $stat->{isDir};
        $c->Write("╞> ");
        $c->Attr($ATTR_NORMAL);
        $self->_writeMessage($message);
    }
}

sub _showDirHeader {
    my $self = shift;
    my $c = $self->{console};

    $c->Attr($FG_WHITE);
    $c->Write("├┬╴");
    $c->Attr($FG_BLUE);
    $c->Write("$self->{dir}{path}\n");
    $c->Attr($ATTR_NORMAL);

    if ($self->{dirMessage}) {
        $c->Attr($FG_WHITE);
        $c->Write("│╞> ");
        $c->Attr($ATTR_NORMAL);
        $self->_writeMessage($self->{dirMessage});
    }
    $self->{shownDirHeader} = 1;
}

sub _writeMessage {
    my ($self, $message) = @_;
    my $c = $self->{console};

    if (ref $message) {
        if ($message->{error}) {
            $c->Attr($FG_RED);
            $c->Write($message->{error});
        } elsif ($message->{warn}) {
            $c->Attr($FG_LIGHTRED);
            $c->Write($message->{warn});
        } elsif ($message->{info}) {
            $c->Attr($FG_LIGHTGREEN);
            $c->Write($message->{info});
        } elsif ($message->{debug}) {
            $c->Attr($FG_GRAY);
            $c->Write($message->{debug});
        }
        $c->Attr($ATTR_NORMAL);
    } else {
        $c->Write($message);
    }
    $c->Write("\n");
}

1;
