package Visitors::Media::Info;
use parent 'FileTypeVisitor';

use strict;
use warnings;

use RJK::Media::Info::FFmpeg;

my $mediaProps = [qw(format duration start bitrate)];
my $streamProps = [qw(format profile codec bitrate note)];
my $audioProps = [@$streamProps, qw(frequency channels language)];
my $videoProps = [@$streamProps, qw(framerate aspect colorspace width height sar dar tbr fps)];
my $chapterProps = [qw(start end title)];
my @ignoreMetadata = qw(compatible_brands encoder major_brand minor_version);

sub visitFile {
    my ($self, $file, $stat, $props) = @_;
    return if $props->has('media.file.format');

    my $i = RJK::Media::Info::FFmpeg->info($file);

    $props->set("media.file.streams.video", scalar @{$i->{video}}) if @{$i->{video}};
    $props->set("media.file.streams.audio", scalar @{$i->{audio}}) if @{$i->{audio}};
    map { $props->set("media.file.$_", $i->{$_}) } @$mediaProps;

    if ($i->{video}[0]) {
        map { $props->set("media.video.$_", $i->{video}[0]{$_}) } @$videoProps;
        $props->delete("media.video.note") if $props->get("media.video.note") eq 'default';
    }

    if ($i->{audio}[0]) {
        map { $props->set("media.audio.$_", $i->{audio}[0]{$_}) } @$audioProps;
        $props->delete("media.audio.note") if $props->get("media.audio.note") eq 'default';
        $props->delete("media.audio.language") if $props->get("media.audio.language") eq 'und';
    }

    $props->set("media.file.chapters", $i->{chapters});

    if ($i->{metadata}) {
        delete $i->{metadata}{$_} for @ignoreMetadata;
        foreach my $key (keys %{$i->{metadata}}) {
            $props->set("media.metadata.$key", $i->{metadata}{$key});
        }
    }
    $props->set("media.video.metadata", $i->{video}[0]{metadata}) if $i->{video}[0]{metadata};
    $props->set("media.audio.metadata", $i->{audio}[0]{metadata}) if $i->{audio}[0]{metadata};
}

1;
