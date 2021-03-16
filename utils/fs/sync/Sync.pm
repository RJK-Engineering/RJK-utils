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
    my $filesInSource = indexDirs($opts->{sourceDir}, \@dirs);
    my $filesInTarget = indexDirs($opts->{targetDir}, \@dirs);
    synchronize(\@dirs, $filesInSource, $filesInTarget);
}

sub indexDirs {
    my ($parent, $dirs) = @_;

    my $stats = RJK::Files->createStats();
    $display->setStats($stats);
    my $visitor = new IndexVisitor($display, $parent);

    foreach my $dir (@$dirs) {
        my $path = "$parent\\$dir";
        $display->info("Reading $path ...");
        $display->stats;
        RJK::Files->traverse($path, $visitor, {}, $stats);
    }
    $display->totals;

    my $index = $visitor->getIndex;
    $index->{stats} = $stats;
    return $index;
}

sub synchronize {
    my ($dirs, $filesInSource, $filesInTarget) = @_;

    my $progress = {total => $filesInSource->{stats}{files}};
    $display->setProgressBar($progress);

    $display->info("Finding moved files ...");
    $display->start();

    foreach my $filename (keys %{$filesInSource->{name}}) {
        my $inSource = $filesInSource->{name}{$filename};
        $progress->{done} += @$inSource;
        $display->progress();
        next if @$inSource > 1;

        my $inTarget = $filesInTarget->{name}{$filename};
        next if ! $inTarget || @$inTarget > 1;
        next if $inSource->[0]{subdirs} eq $inTarget->[0]{subdirs};
        next if ! sameSize($inSource->[0], $inTarget->[0]);
        next if ! sameDate($inSource->[0], $inTarget->[0]);

        moveFile($inSource->[0], $inTarget->[0]);
    }
    $display->done();

    $display->info("Finding renamed files ...");
    $display->start();

    foreach my $dir (keys %{$filesInSource->{size}}) {
        foreach my $size (keys %{$filesInSource->{size}{$dir}}) {
            my $inSource = $filesInSource->{size}{$dir}{$size};
            $progress->{done} += @$inSource;
            $display->progress();
            next if @$inSource > 1;

            my $inTarget = $filesInTarget->{size}{$dir}{$size};
            next if ! $inTarget || @$inTarget > 1;
            next if $inSource->[0]{name} eq $inTarget->[0]{name};
            next if ! sameDate($inSource->[0], $inTarget->[0]);

            renameFile($inSource->[0], $inTarget->[0]);
        }
    }
    $display->done();
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
    $display->info(">$targetDir");
    return if $opts->{simulate};

    File::Copy::move("$inTarget", "$targetDir") or die "$!: $inTarget -> $targetDir";
}

sub sameDate {
    my ($inSource, $inTarget) = @_;
    return abs($inSource->{stat}->modified - $inTarget->{stat}->modified) < 3;
}

sub sameSize {
    my ($inSource, $inTarget) = @_;
    return $inSource->{stat}->size == $inTarget->{stat}->size;
}

1;
