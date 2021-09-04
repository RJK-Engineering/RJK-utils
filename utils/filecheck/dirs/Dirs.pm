package Dirs;

use strict;
use warnings;

use Actions;
use RJK::Filecheck;
use RJK::TotalCmd::Utils;
use Win32::Clipboard;

my $opts;

sub execute {
    my $self = shift;
    $opts = shift;
    my $result = getResult();

    if (! $result) {
        print "No results.\n";
        return;
    }
    if ($opts->{tcOpen}) {
        tcOpen($result);
    }
    if ($opts->{addToDownloadList}) {
        addToDownloadList($result);
    }
    if ($opts->{setClipboard}) {
        my $clip = Win32::Clipboard();
        $clip->Set(join "\n", @$result);
    }
}

sub getResult {
    if ($opts->{getDirs}) {
        Actions::exec('GetDirs', $opts);
    } elsif ($opts->{listMultipleNames}) {
        Actions::exec('ListMultipleNames', $opts);
    } elsif ($opts->{listDupes}) {
        Actions::exec('FindDupes', $opts);
    } elsif ($opts->{filenameSearch}) {
        Actions::exec('FilenameSearch', $opts);
    } else {
        Actions::exec('NameSearch', $opts);
    }
}

sub tcOpen {
    my ($result) = @_;
    my $exist = getExistingPaths($result);
    exit 1 if !@$exist;

    my $exit = @$result > @$exist;
    if ($opts->{tcOpenAll}) {
        $result = $exist;
    } elsif (@$exist == 1) {
        $result = [ $exist->[0] ];
    } else {
        $exit = 0;
        $result = [ getUserSelection($exist) ];
    }

    foreach (@$result) {
        print "Result: $_\n";
        setTcPath($_);
    }
    exit 1 if $exit;
}

sub getExistingPaths {
    my $paths = shift;
    my @exist;
    foreach (@$paths) {
        my $rpath = RJK::Filecheck->getRealPath($_);
        if ($rpath && -e $rpath) {
            push @exist, $rpath;
        } else {
            print "Path does not exist: $_\n";
        }
    }
    return \@exist;
}

sub getUserSelection {
    my ($result) = @_;
    return $result->[0] if @$result == 1;
    printPathList($result);
    my $n = getUserInput("Number: ");
    return if $n !~ /^\d+$/;
    return $result->[$n-1];
}

sub printPathList {
    my $dirs = shift;
    my $i = 0;
    foreach (@$dirs) {
        print ++$i, " $_\n";
    }
}

sub getUserInput {
    my $label = shift;
    print "$label\n";
    return <STDIN>;
}

sub setTcPath {
    my ($path) = @_;

    RJK::TotalCmd::Utils->setPath(
        newInstance => $opts->{tcOpenNewInstance},
        newTab => $opts->{tcOpenAll} || $opts->{tcOpenNewTab},
        left   => $opts->{tcSetLeftPath} && $path,
        right  => $opts->{tcSetRightPath} && $path,
        source => $opts->{tcSetSourcePath} && $path,
        target => $opts->{tcSetTargetPath} && $path,
    );
}

1;
