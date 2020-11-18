use strict;
use warnings;

use Data::Dump;
use File::Copy ();
use RJK::Files;
use RJK::SimpleFileVisitor;
use RJK::File::Path::Util;

my %opts = (
    dryRun => 0,
    keepNotOk => 1,
    copyNotOk => 0,
    sizePercentage => .99
);

$opts{sourceDir} = shift;
$opts{targetDir} = shift;

my (@failed, @bigger, @toosmall);

my $visitor = new RJK::SimpleFileVisitor(
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
        return if $file->{name} !~ /\.(mp4|flv)$/i;

        my $sourceFile = "$opts{sourceDir}\\$file->{path}";
        my $targetDir = "$opts{targetDir}\\$file->{directories}";
        my $targetFile = "$targetDir$file->{basename}.mp4";

        my @cmd = (
            "avidemux_cli", "--force-alt-h264",
            "--load", "\"$sourceFile\"",
            "--output-format", "MP4v2",
            "--save", "\"$targetFile\"",
            "--quit", ">NUL"
        );

        print "@cmd\n";
        # can't suppress stdout using system() (>NUL doesn't work)
        # avidemux doesn't return an exit code :/$@#%$%@!&*^%!
        `@cmd` unless $opts{dryRun};

        my $ok = 0;
        if (! -e $targetFile) {
            push @failed, $sourceFile;
        } elsif ((-s $targetFile) > (-s $sourceFile)) {
            push @bigger, [ $sourceFile, $targetFile ];
            unlink $targetFile unless $opts{keepNotOk} || $opts{dryRun};
        } elsif ((-s $targetFile) / (-s $sourceFile) < $opts{sizePercentage}) {
            push @toosmall, [ $sourceFile, $targetFile ];
            unlink $targetFile unless $opts{keepNotOk} || $opts{dryRun};
        } else {
            # copy modified time
            my $atime = time;
            my $mtime = $stat->{modified};
            utime $atime, $mtime, $targetFile or warn "$!: $atime, $mtime, $targetFile";
            $ok = 1;
        }
        File::Copy::copy $sourceFile, $targetDir if !$ok && $opts{copyNotOk} && !$opts{dryRun};
    }
);

$opts{sourceDir} || die "No source directory specified";
$opts{targetDir} || die "No target directory specified";
chdir $opts{sourceDir} || die "$!: $opts{sourceDir}";
RJK::Files->traverse(".", $visitor);

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
