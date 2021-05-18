package Actions::GetDirs;

use strict;
use warnings;

use RJK::Filecheck;
use RJK::Filecheck::DirLists;
use RJK::SimpleFileVisitor;

my $opts;
my $fh;
my $currVol;
my $currDir;

sub execute {
    my $self = shift;
    $opts = shift;
    my %volumes;

    RJK::Filecheck::DirLists->traverse($opts->{list}, sub {
        my $vpath = shift;
        $volumes{$vpath->label}{dirs}{$vpath->relative} = 1;
        return 0;
    });

    $fh = *STDOUT;
    open $fh, '>', $opts->{outputFile}
        or die "$!: $opts->{outputFile}"
            if $opts->{outputFile};

    foreach my $label (sort keys %volumes) {
        $currVol = $volumes{$label};
        $currVol->{label} = $label;
        getStore()->traverse(
            new RJK::SimpleFileVisitor(
                preVisitDir => \&preVisitDir
            ),
            $label
        );
    }

    close $fh;
}

sub preVisitDir {
    my $dir = shift;
    my $relative = "$dir->{directories}\\$dir->{name}";
    if ($currDir) {
        my $dirnameRe    = qr/[^\[\d] [^\\]+/x;
        my $subdirnameRe = qr/\[{1,2} \w+ \]{1,2}/x;

        if ($relative      =~ /^$currDir\\$subdirnameRe\\($dirnameRe)$/) {
            print $fh "$currVol->{label}:$relative\n";
        } elsif ($relative =~ /^$currDir\\($dirnameRe)$/) {
            print $fh "$currVol->{label}:$relative\n";
        } elsif ($relative !~ /^$currDir\\/) {
            $currDir = undef;
        } elsif ($relative =~ /^$currDir\\(\[[^\\]*)\\.*\[/) {
            print STDERR "$relative\n";
        }
    }
    if (! $currDir && $currVol->{dirs}{$relative}) {
        $currDir = quotemeta $relative;
    }
}

sub getStore {
    return RJK::Filecheck->getStore("RJK::Filecheck::Store::DiskDirFiles")
}

1;
