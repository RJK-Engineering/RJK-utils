package DdfVisitor;

use strict;
use warnings;

use RJK::TotalCmd::Searches;
use RJK::TreeVisitResult;

sub new {
    my $self = bless {}, shift;
    $self->{view} = shift;
    $self->{search} = shift;
    $self->{opts} = shift;
    $self->{opts}{numberOfResults} //= 0;
    $self->{numberOfResults} = 0;
    $self->{stats}{size} = 0;
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
    $self->{dirStats}{size} = 0;
    return if $self->{opts}{searchFiles};
    return $self->_match($dir, $stat);
}

sub postVisitFiles {
    my ($self, $dir, $error, $files, $dirs) = @_;
    $self->{view}->showDirSearchDone($dir, $self->{dirStats});
}

sub _match {
    my ($self, $file, $stat) = @_;

    my $result = RJK::TotalCmd::Searches->match($self->{search}, $file, $stat);
    return if ! $result->{matched};

    $self->{stats}{size} += $stat->{size} // 0;
    $self->{dirStats}{size} += $stat->{size} // 0;
    $self->{view}->showResult($file, $stat);
    return if ++$self->{numberOfResults} < $self->{opts}{numberOfResults};

    $self->{view}->showDirSearchDone($file, $self->{dirStats}, {
        info => "Maximum of $self->{numberOfResults} results reached."
    });
    return TERMINATE;
}

1;
