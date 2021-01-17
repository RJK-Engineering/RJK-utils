=begin TML

---+ package FileSearchVisitor

=cut
###############################################################################

package FileSearchVisitor;
use parent 'RJK::FileVisitor';

use strict;
use warnings;

use RJK::TotalCmd::Searches;
use RJK::TreeVisitResult;

###############################################################################
=pod

---+++ FileSearchVisitor->new($view, $search, \%opts) -> $fileSearchVisitor
   * =$view= - =View= object.
   * =$search= - =RJK::TotalCmd::Search= object.
   * =%opts= - option hash.
      * =$opts{numberOfResults}= - Stop searching after n results.
   * =$stats= - =RJK::File::TraverseStats= object.
   * =$fileSearchVisitor= - New =FileSearchVisitor= object.

=cut
###############################################################################

sub new {
    my $self = bless {}, shift;
    $self->{view} = shift;
    $self->{search} = shift;
    $self->{opts} = shift;
    $self->{results} = { traverseStats => shift };
    $self->{matched} = [];

    $self->{opts}{numberOfResults} //= 0;
    $self->{numberOfResults} = 0;
    return $self;
}

sub visitFile {
    my ($self, $file, $stat) = @_;
    return if $self->{search}{flags}{directory} == 1;
    return $self->_match($file, $stat);
}

sub preVisitFiles {
    my ($self, $dir, $stat) = @_;
    $self->{view}->showDirSearchStart($dir, $stat);
    $self->{results}{dir} = {};
    return if $self->{search}{flags}{directory} == 0;
    return $self->_match($dir, $stat);
}

sub postVisitFiles {
    my ($self, $dir, $error) = @_;
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

    $self->{results}{size} += $stat->size || 0;
    $self->{results}{dir}{size} += $stat->size || 0;
    $self->{results}{part}{size} += $stat->size || 0;

    push @{$self->{matched}}, $file->{path};
    $self->{view}->showResult($file, $stat);
    return if ++$self->{numberOfResults} < $self->{opts}{numberOfResults};

    $self->{view}->showDirSearchDone($file, {
        info => "Maximum of $self->{numberOfResults} results reached."
    });
    return TERMINATE;
}

1;
