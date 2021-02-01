package Visitors::VideoInfo;
use parent 'FileTypeVisitor';

use strict;
use warnings;

use RJK::Media::Info::FFmpeg;

my $mediaProps = [qw(format duration start bitrate framerate aspect)];
my $streamProps = [qw(format profile codec bitrate note)];
my $audioProps = [@$streamProps, qw(frequency channels language)];
my $videoProps = [@$streamProps, qw(colorspace width height sar dar tbr fps)];
my $chapterProps = [qw(start end title)];
my @ignoreMetadata = qw(compatible_brands encoder major_brand minor_version);

sub visitFile {
    my ($self, $file, $stat, $props) = @_;
    return if $props->{'media.format'};

    my $i = RJK::Media::Info::FFmpeg->info($file);

    map { $props->{"media.$_"} = $i->{$_} } @$mediaProps;

    map { $props->{"media.video.$_"} = $i->{video}[0]{$_} } @$videoProps if $i->{video}[0];
    delete $props->{"media.video.note"} if $props->{"media.video.note"} eq 'default';

    map { $props->{"media.audio.$_"} = $i->{audio}[0]{$_} } @$audioProps if $i->{audio}[0];

    $props->{"media.chapters"} = $i->{chapters};

    delete $i->{metadata}{$_} for @ignoreMetadata;
    foreach my $key (keys %{$i->{metadata}}) {
        $props->{"media.metadata.$key"} = $i->{metadata}{$key};
    }
    $props->{"media.video.streams"} = scalar @{$i->{video}};
    $props->{"media.audio.streams"} = scalar @{$i->{audio}};
    $props->{"media.video.metadata"} = $i->{video}[0]{metadata} if $i->{video}[0]{metadata};
    $props->{"media.audio.metadata"} = $i->{audio}[0]{metadata} if $i->{audio}[0]{metadata};
}

1;
