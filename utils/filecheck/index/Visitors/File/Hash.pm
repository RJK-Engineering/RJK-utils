package Visitors::File::Hash;
use parent 'FileTypeVisitor';

use strict;
use warnings;

sub isFileType {
    my ($self, $file, $type) = @_;
    grep { $_ eq $type } @{$file->{type}};
}

sub visitFile {
    my ($self, $file, $stat, $props) = @_;
    my @hashTypes = 'crc32';
    push @hashTypes, 'edonkey' if $self->isFileType($file, 'video');
    return if not grep { ! $props->{"file.hash.$_"} } @hashTypes;

    my $hashes = calcHash($file);
    foreach (@hashTypes) {
        $props->{"file.hash.$_"} = $hashes->{$_};
    }
}

sub calcHash {
    my ($file) = @_;
    my $executable = 'fsum';
    open my $fh, "$executable -crc32 -edonkey \"$file->{name}\" 2>NUL|" or die "$!";
    my %hashes;

    while (<$fh>) {
        next if /^;/;
        my ($hash, $type) = /^(\w+) \?(\w+)\*/;
        $hashes{lc $type} = $hash;
    }
    close $fh;
    return \%hashes;
}

1;
