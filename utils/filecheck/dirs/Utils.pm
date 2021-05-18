package Utils;

use strict;
use warnings;

use RJK::Env;

sub getNames {
    my ($path) = @_;
    my $basename = $path->basename;
    while ($basename =~ s/\s*\(.*\)\s*//g) {};
    while ($basename =~ s/\s*\[.*\]\s*//g) {};
    while ($basename =~ s/\s*\{.*\}\s*//g) {};
    return [ split /\s*\W+\s+/, $basename ];
}

sub getEmptyDir {
    my ($tempDir) = @_;
    my $emptyDir = RJK::Env->subst("$tempDir\\z");
    -e $emptyDir || mkdir $emptyDir or die "Could not create directory: $!";
    return $emptyDir;
}

1;
