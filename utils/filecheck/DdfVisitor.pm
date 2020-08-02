package DdfVisitor;

use strict;
use warnings;

use RJK::TotalCmd::Searches;
use RJK::TreeVisitResult;

sub new {
    my $self = bless {}, shift;
    $self->{search} = shift;
    $self->{opts} = shift;
    $self->{opts}{numberOfResults} //= 0;
    $self->{numberOfResults} = 0;
    return $self;
}

sub visitFile {
    my ($self, $file, $stat) = @_;
    return if $self->{opts}{searchDirs};

    my $result = RJK::TotalCmd::Searches->match($self->{search}, $file, $stat);
    if ($result->{matched}) {
        print "$stat->{size}\t$stat->{modified}\t$file->{path}\n";
        return TERMINATE if ++$self->{numberOfResults} == $self->{opts}{numberOfResults};
    }
}

sub preVisitFiles {
    my ($self, $dir, $stat, $files, $dirs) = @_;
    return if $self->{opts}{searchFiles};

    my $result = RJK::TotalCmd::Searches->match($self->{search}, $dir, $stat);
    if ($result->{matched}) {
        print "$stat->{modified}\t$dir->{path}\n";
        return TERMINATE if ++$self->{numberOfResults} == $self->{opts}{numberOfResults};
    }
    #~ return TERMINATE;
    #~ return SKIP_SIBLINGS;
    #~ return SKIP_SUBTREE;
    #~ print "---> $dir->{path}\t$stat->{modified}\n";
}

sub postVisitFiles {
    my ($self, $dir, $error, $files, $dirs) = @_;
    #~ print "<--- $dir->{path}\n";
    #~ return TERMINATE;
    #~ return SKIP_SIBLINGS;
}

1;
