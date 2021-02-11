package Visitors::File::Metadata;
use parent 'RJK::FileVisitor';

use strict;
use warnings;

sub visitFile {
    my ($self, $file, $stat, $props) = @_;

    if ($props->has("file.size")) {
        if ($props->get("file.size") != $stat->size) {
            warn "File size changed";
        }
    } else {
        $props->set("file.size", $stat->size);
    }

    if ($props->has("file.date.created")) {
        if ($props->get("file.date.created") != $stat->created) {
            warn "File date created changed";
        }
    } else {
        $props->set("file.date.created", $stat->created);
    }

    if ($props->has("file.date.modified")) {
        if ($props->get("file.date.modified") != $stat->modified) {
            warn "File date modified changed";
        }
    } else {
        $props->set("file.date.modified", $stat->modified);
    }
}

1;
