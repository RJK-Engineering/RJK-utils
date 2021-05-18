package Actions::FilenameSearch;

use strict;
use warnings;

use Win32::Clipboard;

use RJK::Filecheck;
use RJK::Filecheck::DirLists;
use RJK::Paths;
use RJK::TotalCmd::DownloadList;
use RJK::TotalCmd::Utils;

use Utils;

my $opts;
my $dlists;

sub execute {
    my $self = shift;
    $opts = shift;

    return if ! @{$opts->{args}};
    my $path = join " ", @{$opts->{args}};

    my $dirs = getDirList($opts->{list});
    my $matched = filenameMatch($dirs, $path);

    if (! @$matched) {
        print "No matches.\n";
        return;
    }

    if ($opts->{setTcTargetDir}) {
        my @matched = grep { -e $_->{path} } @$matched;
        if (! @matched) {
            printList([map { $_->{path} } @$matched]);
            print "None accessible.\n";
            exit 1;
        }
        $matched = \@matched;
    }

    printList([map { $_->{path} } @$matched]);

    my $selected = $matched->[0];
    if (@$matched > 1) {
        my $n = getUserInput("Number: ");
        return if $n !~ /^\d+$/;
        return if @$matched < $n;
        $selected = $matched->[$n-1];
    }
    return if ! $selected;

    print "$selected->{path}\n";

    if ($opts->{addToDownloadList}) {
        my $newdir = getNewdir($selected->{path});
        my $dlist = getDownloadList($selected->{volumeLabel});
        $dlist->addMove($path, $newdir->{path});

        while (my ($volumeLabel, $dlist) = each %$dlists) {
            $dlist->append("$opts->{downloadListDir}\\$volumeLabel.dl");
        }
    }

    if ($opts->{setClipboard}) {
        my $clip = Win32::Clipboard();
        $clip->Set(join "\n", map { $_->{path} } @$matched);
    }

    if ($opts->{setTcTargetDir}) {
        RJK::TotalCmd::Utils->setTargetPath($selected->{path});
    }
}

sub getDirList {
    my ($list) = @_;
    my %dirs;

    RJK::Filecheck::DirLists->traverse($list, sub {
        my $vpath = shift;
        my $rpath = RJK::Filecheck->getRealPath($vpath);
        my $names = Utils::getNames($vpath);

        foreach (map { [ /(\w+)/g ] } @$names) {
            my $regex = join ".?", @$_;
            push @{$dirs{"@$_"}}, {
                path => $rpath // $vpath,
                volumeLabel => $vpath->label,
                words => \@$_,
                regex => qr/$regex/i
            };
        }
    });
    return [ values %dirs ];
}

sub filenameMatch {
    my ($dirs, $match) = @_;
    my %matched;

    foreach my $dir (@$dirs) {
        foreach (values @$dir) {
            next if $match !~ /$_->{regex}/;
            $matched{$_->{path}} = {
                path => $_->{path}{path},
                volumeLabel => $_->{volumeLabel},
                words => $_->{words}
            };
        }
    }

    return [ values %matched ];
}

sub printList {
    my $list = shift;
    my $i = 0;
    foreach (@$list) {
        print ++$i, " $_\n";
    }
}

sub getUserInput {
    my $label = shift;
    print "$label\n";
    return <STDIN>;
}

sub getNewdir {
    my ($path, $dlist) = @_;
    my $emptyDir = Utils::getEmptyDir($opts->{tempDir});
    die if ! $opts->{newdirName} || ! $emptyDir;
    my $newdir = RJK::Paths->get($path, $opts->{newdirName});

    if ($dlist) {
        # can't mkdir using download list, workaround:
        $dlist->addFlags("136");                        # skip warnings
        $dlist->addCopy($emptyDir, $newdir->{path});    # copy an empty directory
        $dlist->addClearFlags();
    }

    return $newdir;
}

sub getDownloadList {
    my $label = shift;
    return $dlists->{$label} if $dlists->{$label};
    $dlists->{$label} = new RJK::TotalCmd::DownloadList();
}

1;
