package DdfVisitor;
use parent 'RJK::FileVisitor';

use strict;
use warnings;

use RJK::TotalCmd::Searches;
use RJK::TreeVisitResult;

sub new {
    my $self = bless {}, shift;
    $self->{view} = shift;
    $self->{search} = shift;
    $self->{opts} = shift;
    $self->{results} = { traverseStats => shift };

    $self->{opts}{numberOfResults} //= 0;
    $self->{numberOfResults} = 0;
    return $self;
}

sub visitFile {
    my ($self, $file, $stat) = @_;
    return if $self->{opts}{searchDirs};
    return $self->_match($file, $stat);
}

sub preVisitFiles {
    my ($self, $dir, $stat, $files, $dirs) = @_;
    $self->{view}->showDirSearchStart($dir, $stat);
    $self->{results}{dir} = {};
    return if $self->{opts}{searchFiles};
    return $self->_match($dir, $stat);
}

sub postVisitFiles {
    my ($self, $dir, $error, $files, $dirs) = @_;
    $self->{view}->showDirSearchDone($dir);
}

sub resetPartitionStats {
    my $self = shift;
    $self->{results}{part} = {};
}

sub _match {
    my ($self, $file, $stat) = @_;

    my $result = RJK::TotalCmd::Searches->match($self->{search}, $file, $stat);
    return if ! $result->{matched};

    $self->{results}{size} += $stat->{size};
    $self->{results}{dir}{size} += $stat->{size};
    $self->{results}{part}{size} += $stat->{size};

    $self->{view}->showResult($file, $stat);
    return if ++$self->{numberOfResults} < $self->{opts}{numberOfResults};

    $self->{view}->showDirSearchDone($file, {
        info => "Maximum of $self->{numberOfResults} results reached."
    });
    return TERMINATE;
}

1;
