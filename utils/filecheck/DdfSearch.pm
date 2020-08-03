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
    foreach (@files) {
        $view->showParitionSearchStart($_);
        if (RJK::TotalCmd::DiskDirFiles->traverse("$opts->{lstDir}\\$_", $visitor)) {
            $view->showMessage("Maximum of $opts->{numberOfResults} results reached.")
                if $opts->{numberOfResults} == $visitor->{numberOfResults};
            last;
        }
        $view->showParitionSearchDone($_, $visitor->{size});
    }
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
