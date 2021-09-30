package Actions::FilenameSearch;

use strict;
use warnings;

use RJK::Filecheck::DirLists;
use Utils;

my $opts;

sub execute {
    my $self = shift;
    $opts = shift;
    @{$opts->{args}} or throw Exception("No search arguments");

    my $string = join " ", @{$opts->{args}};
    print "Search in string: $string\n";

    my $dirs = getDirList($opts->{list});
    my $matched = match($dirs, $string);
    return [sort map {$_->{vpath}} @$matched] if @$matched;
}

sub getDirList {
    my ($list) = @_;
    my %dirs;

    RJK::Filecheck::DirLists->traverse($list, sub {
        my $vpath = shift;
        my $names = Utils::getNames($vpath);

        foreach (map { [ /(\w+)/g ] } @$names) {
            my $regex = join ".?", @$_;
            push @{$dirs{"@$_"}}, {
                vpath => $vpath,
                words => \@$_,
                regex => qr/$regex/i
            };
        }
    });
    return [ values %dirs ];
}

sub match {
    my ($dirs, $match) = @_;
    my %matched;

    foreach my $dir (@$dirs) {
        foreach (values @$dir) {
            next if $match !~ /$_->{regex}/;
            $matched{$_->{vpath}} = $_;
        }
    }
    return [ values %matched ];
}

1;
