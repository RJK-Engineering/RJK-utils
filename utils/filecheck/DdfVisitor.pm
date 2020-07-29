package DdfVisitor;

use strict;
use warnings;

use RJK::TotalCmd::Searches;
#~ use RJK::TreeVisitResult;

sub new {
    my $self = bless {}, shift;
    $self->{search} = shift;
    return $self;
}

sub visitFile {
    my ($self, $file, $stat) = @_;
    my $result = RJK::TotalCmd::Searches->match($self->{search}, $file, $stat);
    if ($result->{matched}) {
        print "$stat->{size}\t$stat->{modified}\t$file->{path}\n";
    }
    #~ return TERMINATE;
    #~ return SKIP_SIBLINGS;
}

sub preVisitFiles {
    my ($self, $dir, $stat, $files, $dirs) = @_;
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
