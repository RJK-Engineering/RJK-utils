package Visitors::Media::ImageInfo;
use parent 'FileTypeVisitor';

use strict;
use warnings;

use RJK::Media::Info::FFmpeg;

my $imageProps = [qw(format colorspace width height)];

sub visitFile {
    my ($self, $file, $stat, $props) = @_;
    return if $props->has('image.format');

    my $i = RJK::Media::Info::FFmpeg->info($file);
    if (! @{$i->{video}}) {
        warn "Failed to retrieve image info";
        return;
    }
    map { $props->set("image.$_", $i->{video}[0]{$_}) } @$imageProps;
}

1;
