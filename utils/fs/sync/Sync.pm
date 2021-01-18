package Sync;

use RJK::Files;

use IndexFileVisitor;
use SyncFileVisitor;
use Display;

my $opts;
my $display = new Display;

sub execute {
    my $self = shift;
    $opts = shift;

    opendir my $dh, $opts->{targetDir} or die "$!";
    my @dirs = grep { -d "$opts->{targetDir}\\$_" && ! /^\./ } readdir $dh;
    closedir $dh;

    die "No dirs in target: $opts->{targetDir}" if ! @dirs;
    $display->info("Dir: $_") foreach @dirs;

    my $filesInTarget = indexTarget(\@dirs);
    synchronize(\@dirs, $filesInTarget);
}

sub indexTarget {
    my $dirs = shift;

    my $filesInTarget = {};
    my $stats = RJK::Files->createStats();
    $display->setStats($stats);
    my $visitor = new IndexFileVisitor($opts, $filesInTarget, $display);

    foreach (@$dirs) {
        my $path = "$opts->{targetDir}\\$_";
        $display->info("Indexing $path ...");
        $display->stats;
        RJK::Files->traverse($path, $visitor, {}, $stats);
    }
    $display->stats;

    return $filesInTarget;
}

sub synchronize {
    my ($dirs, $filesInTarget) = shift;

    my $totals = RJK::Files->createStats();
    my $visitor = new SyncFileVisitor($filesInTarget, $opts);

    foreach my $dir (@$dirs) {
        $display->info("Synchronizing $dir ...");

        if (! -e $dir) {
            $display->info("Directory does not exist in source: $dir");
            next;
        } elsif (! -d $dir) {
            $display->warn("Source is not a directory");
            exit;
        } elsif (! -r $dir) {
            $display->warn("Source directory is not readable");
            exit;
        }

        my $stats = RJK::Files->traverseWithStats($dir, $visitor);
        $totals->update($stats);
        $display->stats($totals);
    }
    return $totals;
}

1;
