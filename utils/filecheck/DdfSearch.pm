package DdfSearch;

use DdfVisitor;
use RJK::File::TraverseStats;
use RJK::FileVisitor::StatsWrapper;
use RJK::IO::File;
use RJK::TotalCmd::DiskDirFiles;

use Win32::Clipboard;

use strict;
use warnings;

sub execute {
    my ($class, $view, $tcSearch, $partitions, $opts) = @_;

    my $lstDir = new RJK::IO::File($opts->{lstDir});
    my @files = getDdfFiles($lstDir, $partitions);
    my $traverseStats = new RJK::File::TraverseStats();
    my $visitor = new DdfVisitor($view, $tcSearch, $opts, $traverseStats);
    my $visitorWithStats = new RJK::FileVisitor::StatsWrapper($visitor, $traverseStats);
    $view->{results} = $visitor->{results};

    $view->showSearchStart($tcSearch);
    foreach (@files) {
        $view->showPartitionSearchStart($_);
        my $terminated = RJK::TotalCmd::DiskDirFiles->traverse("$opts->{lstDir}\\$_", $visitorWithStats, $opts);
        $view->showPartitionSearchDone($_);

        $visitor->resetPartitionStats();
        last if $terminated;
    }
    $view->showSearchDone($tcSearch);

    if ($opts->{setClipboard} && @{$visitor->{matched}}) {
        Win32::Clipboard()->Set(join "\n", @{$visitor->{matched}});
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
