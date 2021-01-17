use strict;
use warnings;

use Data::Dump;
use File::Copy ();

use RJK::File::Path::Util;
use RJK::Path;
use RJK::Files;
use RJK::SimpleFileVisitor;

my %opts = (
    dryRun => 0,
    overwrite => 0,
    keepBigger => 0,
    copyNotOk => 1,
    sizePercentage => .96
);

$opts{sourceDir} = shift || die "No source directory specified";
$opts{targetDir} = shift || die "No target directory specified";

my (@failed, @bigger, @toosmall);
chdir $opts{sourceDir} || die "$!: $opts{sourceDir}";
RJK::Files->traverse(".", getVisitor());

print "failed\n" if @failed;
foreach (@failed) {
    print "$_\n";
}
print "bigger\n" if @bigger;
foreach (@bigger) {
    print "$_->[0]\n";
    print "$_->[1]\n";
}
print "toosmall\n" if @toosmall;
foreach (@toosmall) {
    print "$_->[0]\n";
    print "$_->[1]\n";
}

sub getVisitor {
    return new RJK::SimpleFileVisitor(
        visitFileFailed => sub {
            my ($file, $error) = @_;
            print "$error: $file->{path}\n";
        },
        preVisitDir => sub {
            my ($dir, $stat) = @_;
            my $targetDir = "$opts{targetDir}\\$dir->{path}";
            print "$targetDir\n";
            RJK::File::Path::Util::checkdir($targetDir) unless $opts{dryRun};
        },
        visitFile => sub {
            my ($file, $stat) = @_;
            return if $file->{name} !~ /\.(mp4|flv)$/;

            my $ext = $1;
            my $source = "$opts{sourceDir}\\$file->{path}";
            my $mp4    = "$file->{directories}\\" . $file->basename . ".mp4";
            my $target = "$opts{targetDir}\\$mp4";
            my $copy   = "$opts{targetDir}\\$file->{path}";

            if ($ext eq 'flv' && -e "$opts{sourceDir}\\$mp4") {
                print "Mp4 exists in source: $mp4\n";
                copyFile($source, $copy);
                return;
            }

            if (-e $copy) {
                print "Copy exists: $copy\n";
            } elsif (! $opts{overwrite} && -e $target) {
                print "Target exists: $target\n";
                checkTargetFile($source, $target, $copy, $stat);
            } else {
                createTargetFile($source, $target, $copy, $stat);
            }
        }
    );
}

sub createTargetFile {
    my ($source, $target, $copy, $sourceStat) = @_;
    my @cmd = (
        "avidemux_cli", "--force-alt-h264",
        "--load", "\"$source\"",
        "--output-format", "MP4v2",
        "--save", "\"$target\"",
        "--quit", ">NUL"
    );
    print "@cmd\n";

    # can't suppress stdout using system() (>NUL doesn't work)
    # avidemux doesn't return an exit code :/$@#%$%@!&*^%!
    `@cmd` unless $opts{dryRun};

    if (-e $target) {
        checkTargetFile($source, $target, $copy, $sourceStat);
    } else {
        push @failed, $source;
        copyFile($source, $copy);
    }
}

sub checkTargetFile {
    my ($source, $target, $copy, $sourceStat) = @_;

    if ((-s $target) > (-s $source)) {
        push @bigger, [ $source, $target ];
        if (! $opts{keepBigger}) {
            unlink $target unless $opts{keepBigger} || $opts{dryRun};
            copyFile($source, $copy);
        }
    } elsif ((my $pct = (-s $target) / (-s $source)) < $opts{sizePercentage}) {
        print "Too small: $pct\n";
        push @toosmall, [ $source, $target ];
    } else {
        copyModifiedTime($target, $sourceStat);
    }
}

sub copyFile {
    my ($source, $target) = @_;
    if (-e $target) {
        print "Exists: $target\n";
    } else {
        File::Copy::copy $source, $target if $opts{copyNotOk} && !$opts{dryRun};
    }
}

sub copyModifiedTime {
    my ($targetFile, $stat) = @_;
    my $atime = time;
    my $mtime = $stat->{modified};
    utime $atime, $mtime, $targetFile or warn "$!: $atime, $mtime, $targetFile";
}
