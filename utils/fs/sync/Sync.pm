package Sync;

use File::Copy ();
use File::Path ();

use RJK::Files;
use RJK::Path;
use RJK::Paths;
use RJK::Stat;

use Display;
use IndexVisitor;

my $opts;
my $display;

sub execute {
    my $self = shift;
    $opts = shift;
    $display = new Display($opts);

    opendir my $dh, $opts->{targetDir} or die "$!";
    my @dirs = grep { -d "$opts->{targetDir}\\$_" && ! /^\./ } readdir $dh;
    closedir $dh;

    die "No dirs in target: $opts->{targetDir}" if ! @dirs;
    $display->info("Dir: $_") foreach @dirs;

    $opts->{sourceDir} = ".";
    my $left = indexDirs($opts->{sourceDir}, \@dirs);
    my $right = indexDirs($opts->{targetDir}, \@dirs, $left);

    $display->info("Synchronizing ...");
    foreach (values %$left) {
        synchronize($_, $right);
    }
}

sub indexDirs {
    my ($parent, $dirs, $left) = @_;

    my $stats = RJK::Files->createStats();
    $display->setStats($stats);
    my $visitor = new IndexVisitor($display, $parent, $left);

    foreach my $dir (@$dirs) {
        my $path = "$parent\\$dir";
        $display->info("Reading $path ...");
        $display->stats;
        RJK::Files->traverse($path, $visitor, {}, $stats);
    }
    $display->totals;

    return $visitor->index;
}

sub synchronize {
    my ($file, $right) = @_;
    my $sizeMatch = $right->{$file->{stat}->size} or return;

    my $match;
    foreach (@$sizeMatch) {
        if ($match) {
            print "Multimatch!\n";
            return;
        }
        $match = $_ if sameDate($file, $_);
    }

    if ($file->name eq $match->name)  {
        moveFile($file, $match);
    } else {
        renameFile($file, $match);
    }
}

sub renameFile {
    my ($inSource, $inTarget) = @_;
    my $targetFile = RJK::Paths->get($inTarget->parent->{path}, $inSource->{name});

    $display->info("-$inTarget");
    $display->info("+$targetFile");
    return if $opts->{simulate};

    File::Copy::move("$inTarget", "$targetFile") or die "$!: $inTarget -> $targetFile";
}

sub moveFile {
    my ($inSource, $inTarget) = @_;
    my $targetDir = RJK::Paths->get($opts->{targetDir}, $inSource->{subdirs});

    if (! $opts->{simulate} && ! -e $targetDir) {
        File::Path::make_path("$targetDir") or die "$!: $targetDir";
    }

    $display->info("<$inTarget");
    $display->info(">$targetDir\\");
    return if $opts->{simulate};

    File::Copy::move("$inTarget", "$targetDir") or die "$!: $inTarget -> $targetDir";
}

sub sameDate {
    my ($inSource, $inTarget) = @_;
    return abs($inSource->{stat}->modified - $inTarget->{stat}->modified) < 3;
}

1;
