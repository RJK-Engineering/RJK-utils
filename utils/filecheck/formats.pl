use strict;
use warnings;

use RJK::Files;
use RJK::SimpleFileVisitor;

my %opts = (
    #~ verbose => 1
);

$opts{sourceDir} = shift;

my $formats;
my (@exist, @failed, $renamedExt);

my $visitor = new RJK::SimpleFileVisitor(
    visitFileFailed => sub {
        my ($file, $error) = @_;
        print "$error: $file->{path}\n";
    },
    visitFile => sub {
        my ($file, $stat) = @_;
        my $path = $file->{path};
        print "$path\n" if $opts{verbose};

        my $o = `ffprobe "$path" 2>&1`;
        my $format = ($o =~ /^Input #0, (.+?), /m)[0];
        if (! $format) {
            print "No format for: $path\n" if $opts{verbose};
            return;
        }

        # combined format strings:
        # "matroska,webm"
        # "mov,mp4,m4a,3gp,3g2,mj2"
        $formats->{$format} //= $path;
        $format = ($format =~ /(avi|mpeg|mp4|flv|matroska)/)[0];
        return if ! $format;

        my $ext = $format;
        $ext = 'mpg' if $format eq 'mpeg';

        if ($format eq 'matroska') {
            return if $file->{name} =~ /\.webm$/i;
            $ext = 'mkv';
        }
        return if $file->{name} =~ /\.$ext/;

        my $newName = $path =~ s/(?:\.(\w+))?$/.$ext/r;
        print "No extension: $path\n" if ! $1;
        $renamedExt->{$1}{$ext} //= 1;

        #~ print "$path\n";
        print "Rename $path -> $newName\n";
        if (-e $newName) {
            print "File exists: $newName\n";
            push @exist, $path;
            return;
        }
        rename($path, $newName) || push @failed, $path;
    }
);

$opts{sourceDir} || die "No source directory specified";
RJK::Files->traverse($opts{sourceDir}, $visitor);

use Data::Dump;
dd $formats;
dd $renamedExt;

print "failed\n" if @failed;
foreach (@failed) {
    print "$_\n";
}

print "exist\n" if @exist;
foreach (@exist) {
    print "$_\n";
}
