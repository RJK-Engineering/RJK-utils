use strict;
use warnings;

use Data::Dump;
use File::Copy ();
use RJK::Files;
use RJK::SimpleFileVisitor;
use RJK::File::Path::Util;
use RJK::File::Stats;

my %opts = (
    sourceDir =>'c:\download\2',
    targetDir => 'c:\temp\tdsst',
    keepNotOk => 1,
    copyNotOk => 0,
    dryRun => 1,
    sizePercentage => .99
);

my (@failed, @bigger, @toosmall);

my $visitor = new RJK::SimpleFileVisitor(
    visitFileFailed => sub {
        my ($file, $error) = @_;
        print "$error: $file->{path}\n";
    },
    preVisitDir => sub {
        my ($file, $stat) = @_;
        my $targetDir = "$opts{targetDir}\\$file->{path}";
        checkdir($targetDir);
    },
    visitFile => sub {
        my ($file, $stat) = @_;
        return if $file->{name} !~ /\.(mp4|flv)$/i;

        my $sourceFile = "$opts{sourceDir}\\$file->{path}";
        my $targetFile = "$opts{targetDir}\\$file->{directories}$file->{basename}.mp4";

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
        } elsif (-s $targetFile > -s $sourceFile) {
            push @bigger, [ $sourceFile, $targetFile ];
            unlink $targetFile unless $opts{keepNotOk} || $opts{dryRun};
        } elsif (-s $targetFile / -s $sourceFile < $opts{sizePercentage}) {
            push @toosmall, [ $sourceFile, $targetFile ];
            unlink $targetFile unless $opts{keepNotOk} || $opts{dryRun};
        } else {
            $ok = 1;
        }
        File::Copy::copy $sourceFile, $targetFile if !$ok && $opts{copyNotOk} && !$opts{dryRun};
    }
);

chdir $opts{sourceDir};
my $stats = RJK::File::Stats->traverse(".", $visitor);

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

sub checkdir {
    my $dir = shift;
    print "checkdir $dir\n";
    RJK::File::Path::Util::checkdir($dir) unless $opts{dryRun};
}
