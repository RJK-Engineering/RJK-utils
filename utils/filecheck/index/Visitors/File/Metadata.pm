package Visitors::File::Metadata;
use parent 'FileTypeVisitor';

use strict;
use warnings;

sub visitFile {
    my ($self, $file, $stat, $props) = @_;

    if (defined $props->{"file.size"}) {
        if ($props->{"file.size"} != $stat->size) {
            warn "File size changed";
        }
    } else {
        $props->{"file.size"} = $stat->size;
    }

    if (defined $props->{"file.date.created"}) {
        if ($props->{"file.date.created"} != $stat->created) {
            warn "File date created changed";
        }
    } else {
        $props->{"file.date.created"} = $stat->created;
    }

    if (defined $props->{"file.date.modified"}) {
        if ($props->{"file.date.modified"} != $stat->modified) {
            warn "File date modified changed";
        }
    } else {
        $props->{"file.date.modified"} = $stat->modified;
    }
}

1;
