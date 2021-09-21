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

    my $dirs = getDirs();
    my $left = createIndex($opts->{sourceDir} // ".", $dirs);
    my $right = createIndex($opts->{targetDir}, $dirs, $left);

    $display->info("Synchronizing ...");
    if ($opts->{visitDirs}) {
        foreach (values %{$left->dirs}) {
            synchronizeDirs($_, $right->dirs);
        }
    } else {
        foreach (values %{$left->files}) {
            synchronize($_, $right->files);
        }
    }
}

sub getDirs {
    -e $opts->{targetDir} or die "Target dir does not exist: $opts->{targetDir}";
    -d $opts->{targetDir} or die "Target is not a directory: $opts->{targetDir}";
    -r $opts->{targetDir} or die "Target dir is not readable: $opts->{targetDir}";

    opendir my $dh, $opts->{targetDir} or die "$!";
    my @dirs = grep { -d "$opts->{targetDir}\\$_" && ! /^\./ } readdir $dh;
    closedir $dh;

    @dirs or die "No dirs in target dir: $opts->{targetDir}";
    $display->info("Dir: $_") foreach @dirs;
    return \@dirs;
}

sub createIndex {
    my ($parent, $dirs, $left) = @_;

    my $stats = RJK::Files->createStats();
    $display->setStats($stats);
    my $visitor = new IndexVisitor($opts, $display, $parent, $left);

    foreach my $dir (@$dirs) {
        my $path = "$parent\\$dir";
        $display->info("Reading $path ...");
        $display->stats;
        RJK::Files->traverse($path, $visitor, {}, $stats);
    }
    $display->totals;

    return $visitor;
}

sub synchronizeDirs {
    my ($dir, $right) = @_;
    my $nameMatch = $right->{$dir->{name}} or return;

    if (@$nameMatch > 1) {
        $display->info("Multimatch for name: $dir->{name}");
        return;
    }
    moveDir($dir, $nameMatch->[0]);
}

sub moveDir {
    my ($inSource, $inTarget) = @_;
    my $targetDir = RJK::Paths->get($opts->{targetDir}, $inSource->{subdirs});
    my $target = RJK::Paths->get($opts->{targetDir}, $inSource->{subpath});

    $display->info("<$inTarget");
    $display->info(">$target");
    return if $opts->{simulate};

    move($inTarget, $targetDir, $target);
}

sub move {
    my ($source, $destinationDir, $destination) = @_;
    if (! -e $destinationDir) {
        File::Path::make_path("$destinationDir") or die "$!: $destinationDir";
    }
    File::Copy::move("$source", "$destination") or die "$!: $source -> $destination";
}

sub synchronize {
    my ($file, $right) = @_;
    my $sizeMatch = $right->{$file->{stat}->size} or return;

    my $match;
    foreach (@$sizeMatch) {
        if ($match) {
            $display->info("Multimatch for size: $file->{stat}->size");
            return;
        }
        $match = $_ if sameDate($file, $_);
    }

    if ($file->{subdirs} eq $match->{subdirs})  {
        renameFile($file, $match);
    } else {
        moveFile($file, $match);
    }
}

sub renameFile {
    my ($inSource, $inTarget) = @_;
    my $targetFile = RJK::Paths->get($inTarget->parent->path, $inSource->name);

    $display->info("-$inTarget");
    $display->info("+$targetFile");
    return if $opts->{simulate};

    File::Copy::move("$inTarget", "$targetFile") or die "$!: $inTarget -> $targetFile";
}

sub moveFile {
    my ($inSource, $inTarget) = @_;
    my $target = my $targetDir = RJK::Paths->get($opts->{targetDir}, $inSource->{subdirs});

    $display->info("<$inTarget");
    if ($inSource->name eq $inTarget->name)  {
        $display->info(">$target\\");
    } else {
        $target = RJK::Paths->get($targetDir, $inSource->name);
        $display->info(">$target");
    }
    return if $opts->{simulate};

    move($inTarget, $targetDir, $target);
}

sub sameDate {
    my ($inSource, $inTarget) = @_;
    if ($opts->{useFatDateResolution}) {
        return abs($inSource->{stat}->modified - $inTarget->{stat}->modified) < 3;
    } else {
        return $inSource->{stat}->modified == $inTarget->{stat}->modified;
    }
}

1;
