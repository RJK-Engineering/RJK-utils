package DdfSearch;

use FileSearchVisitor;
use RJK::File::TraverseStats;
use RJK::Filecheck::Config;
use RJK::FileVisitor::StatsWrapper;
use RJK::IO::File;
use RJK::TotalCmd::DiskDirFiles;

use Win32::Clipboard;

use strict;
use warnings;

sub execute {
    my ($class, $view, $tcSearch, $partitions, $opts) = @_;
    my $ddfLstDir = RJK::Filecheck::Config->get('ddf.lst.dir');

    my $lstDir = new RJK::IO::File($ddfLstDir);
    my @files = getDdfFiles($lstDir, $partitions);
    my $traverseStats = new RJK::File::TraverseStats();
    my $visitor = new FileSearchVisitor($view, $tcSearch, $opts, $traverseStats);
    my $visitorWithStats = new RJK::FileVisitor::StatsWrapper($visitor, $traverseStats);
    $view->{results} = $visitor->{results};

    $view->showSearchStart($tcSearch);
    foreach (@files) {
        $view->showPartitionSearchStart($_);
        my $terminated = RJK::TotalCmd::DiskDirFiles->traverse("$ddfLstDir\\$_", $visitorWithStats, { nostat => 0 });
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
