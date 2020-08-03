package DdfSearch;

use DdfVisitor;
use RJK::IO::File;
use RJK::TotalCmd::DiskDirFiles;

use strict;
use warnings;

sub execute {
    my ($class, $view, $tcSearch, $partitions, $opts) = @_;

    my $lstDir = new RJK::IO::File($opts->{lstDir});
    my @files = getDdfFiles($lstDir, $partitions);
    my $visitor = new DdfVisitor($view, $tcSearch, $opts);

    $view->showSearchStart($tcSearch);
    foreach (@files) {
        $view->showPartitionSearchStart($_);
        my $terminated = RJK::TotalCmd::DiskDirFiles->traverse("$opts->{lstDir}\\$_", $visitor);
        $view->showPartitionSearchDone($_, { size => $visitor->{size} });
        last if $terminated;
    }
    $view->showSearchDone($tcSearch);
}

sub getDdfFiles {
    my ($lstDir, $partitions) = @_;

    return $lstDir->filenames(sub { /\.lst$/i }) if ! @$partitions;

    my @files;
    foreach (@$partitions) {
        my $f = new RJK::IO::File($lstDir, "$_.lst");
        if ($f->exists) {
            push @files, $f->name;
        } else {
            die "No such file: $f->{path}";
        }
    }
    return @files;
}

1;
