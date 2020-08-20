package Store;

use strict;
use warnings;

use RJK::Filecheck::Config;

sub getDrives {
    my $class = shift;
    my $file = RJK::Filecheck::Config->get('foswiki.drives.table.file');
    my %drives;

    $class->_fetchTableRows($file, sub {
        my $row = shift;
        $drives{$row->{Label}} = $row;
    });

    return \%drives;
}

sub getBackupDirs {
    my $class = shift;
    my $file = RJK::Filecheck::Config->get('foswiki.backup.dirs.table.file');
    my %dirs;

    $class->_fetchTableRows($file, sub {
        my $row = shift;
        $dirs{$row->{Volume}}{$row->{Name}} = $row;
    });

    return \%dirs;
}

sub storeBackupDirs {
    my ($class, $list) = @_;
    my $file = RJK::Filecheck::Config->get('foswiki.backup.dirs.table.file');

    open my $fh, '<', $file or die "$!: $file";
    open my $fhw, '>', "$file~" or die "$!: $file~";
    while (<$fh>) {
        chomp;
        my @row = split /\s*\|\s*/;
        if (@row > 1) {
            shift @row;
            print $fhw "| ", join(" | ", @row), " |\n";
            last;
        } else {
            print $fhw "$_\n";
        }
    }
    close $fh;

    foreach my $vol (sort { lc $a cmp lc $b } keys %$list) {
        foreach (sort { lc $a cmp lc $b } keys %{$list->{$vol}}) {
            my $dir = $list->{$vol}{$_};
            my @row = ($vol, $_, $dir->{Files}, $dir->{Size}, $dir->{'Backup Location'},
                $dir->{'Last Backup'}, $dir->{Removed}, $dir->{State});
            print $fhw "| ", join(" | ", map { $_ // "" } @row), " |\n";
        }
    }
    close $fhw;
}

sub _fetchTableRows {
    my ($class, $file, $callback) = @_;
    my @header;

    open my $fh, '<', $file or die "$!: $file";
    while (<$fh>) {
        chomp;
        my @row = split /\s*\|\s*/;
        if (@row > 1) {
            shift @row;
            if (@header) {
                my %row;
                @row{@header} = @row;
                $callback->(\%row);
            } else {
                @header = map { s/\*//gr } @row;
            }
        }
    }
    close $fh;
}

1;
