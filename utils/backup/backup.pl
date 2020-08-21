=pod

backup.pl [drive] [directory]

=cut

use strict;
use warnings;

use File::Basename;
use lib dirname (__FILE__);
use Number::Bytes::Human qw(format_bytes);
use Try::Tiny;

use RJK::Exception;
use RJK::Filecheck;
use RJK::TableRowFormatter;
use RJK::LocalConf;
use RJK::Options::Pod;
use RJK::Util::JSON;
use RJK::Win32::VolumeInfo;

my %opts = RJK::LocalConf::GetOptions("backup/backup.properties", (unknown => 1));

RJK::Options::Pod::GetOptions(
    ['OPTIONS'],
    "a|all" => \$opts{all}, "List all directories on all accessible drives.",
    "b|backup-ok|ok:s" => \$opts{backupOk}, "Mark backup ok - set date to current local date, set state to \"OK\".",
    "s|state=s" => \$opts{state}, "Set backup {state} - state should be set to \"Incomplete\" if dir changes.",
    "r|remove" => \$opts{remove}, "Remove dir from list - set removed date to current local date, set state to \"Removed\".",
    "m|move=s" => \$opts{move}, "Move backup to {drive}.",
    "u|unknown!" => \$opts{unknown}, "List unknown directories, default enabled, can be negated C<--no-unknown>.",
    "ignore-drives" => \$opts{ignoreDrives}, "Comma-separated list of drives not to include in C<--all> list.",
    ['POD'],
    RJK::Options::Pod::Options,
    ['Help'],
    RJK::Options::Pod::HelpOptions
);

@ARGV || $opts{all} || RJK::Options::Pod::ShortHelp;
$opts{driveLabel} = shift;
$opts{dir} = shift;

my $rowFormatter = new RJK::TableRowFormatter(
    format => "%Name=-30 %Size=4 %Files=10 %'Backup Location'=-10 %'Last Backup'=8 %State",
    filters => { Size => sub { $_[0] && format_bytes $_[0] } },
    header => {
        'Name' => 'Directory',
        'Backup Location' => 'Backup',
        'Last Backup' => 'Date'
    }
);

try {
    go();
} catch {
    if ($opts{verbose}) {
        RJK::Exception->verbosePrintAndExit;
    } else {
        RJK::Exception->printAndExit;
    }
};

sub go {
    my $backupDirs = RJK::Filecheck->getBackupDirs;

    if ($opts{all}) {
        $opts{ignoreDrives} = { map { $_ => 1 } split(/,/, $opts{ignoreDrives}) };
        main->listAll($backupDirs);
    } elsif ($opts{dir}) {
        main->processDir($backupDirs, $opts{driveLabel}, $opts{dir});
    } else {
        main->processDrive($backupDirs, $opts{driveLabel});
    }

    if ($opts{_dirty}) {
        RJK::Filecheck->storeBackupDirs($backupDirs);
    }
}

sub processDir {
    my ($self, $backupDirs, $driveLabel, $dir) = @_;
    my $d = $backupDirs->{$driveLabel}{$dir};

    if ($opts{state}) {
        if ($d->{State} eq $opts{state}) {
            print "State already set to \"$opts{state}\"\n";
        } else {
            $d->{State} = $opts{state};
            $opts{_dirty} = 1;
        }
    }

    if (defined $opts{backupOk}) {
        $d = $backupDirs->{$driveLabel}{$dir} //= { Name => $dir };
        $self->backupOk($d);
    } else {
        if (! $d) {
            print "Unknown dir: $dir\n";
            return;
        } elsif ($opts{move}) {
            if ($d->{'Backup Location'} eq $opts{move}) {
                print "Location already set to $opts{move}\n";
                return;
            } else {
                printf "Previous location: %s, New location: %s\n", $d->{'Backup Location'}, $opts{move};
                $d->{'Backup Location'} = $opts{move};
            }
        } elsif ($opts{remove}) {
            delete $backupDirs->{$driveLabel}{$dir};
            $opts{_dirty} = 1;
        }
    }

    printf "%s%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\n%s%s\n",
        "Name: ", $d->{Name},
        "Files: ", $d->{Files}//'',
        "Size: ", $d->{Size}//'',
        "Backup location: ", $d->{'Backup Location'}//'',
        "Last backup: ", $d->{'Last Backup'}//'',
        "Removed: ", $d->{Removed}//'',
        "State: ", $d->{State}//'';
}

sub processDrive {
    my ($self, $backupDirs, $driveLabel) = @_;
    my $dirs = $backupDirs->{$driveLabel};
    if ($dirs) {
        if (defined $opts{backupOk}) {
            if (! $opts{backupOk}) {
                print "Backup drive argument required\n";
                return;
            }
            $self->showHeader();
            foreach (sort { $a->{Name} cmp $b->{Name} } values %$dirs) {
                next if $_->{'Backup Location'} ne $opts{backupOk};
                $self->backupOk($_);
                $self->showRow($_);
            }
            return;
        }
    } else {
        print "No data for drive: $driveLabel\n";
    }

    try {
        my @dirs = main->readDirs($driveLabel);
        foreach (@dirs) {
            next if $dirs->{$_->{name}};
            $dirs->{$_->{name}} = {
                Volume => $driveLabel,
                Name => $_->{name}
            };
        }
    } catch {
        print "$_";
    };

    if ($opts{state}) {
        foreach (values %$dirs) {
            next if $opts{state} eq $_->{State};
            $_->{State} = $opts{state};
            $opts{_dirty} = 1;
        }
    }

    $self->showHeader() if keys %$dirs;
    foreach (sort keys %$dirs) {
        my $d = $dirs->{$_};
        next unless $opts{unknown} || exists $d->{State};
        $self->showRow($d);
    }
}

sub showHeader {
    print $rowFormatter->header(), "\n";
}

sub showRow {
    my ($self, $d) = @_;
    print $rowFormatter->format($d), "\n";
}

sub backupOk {
    my ($self, $d) = @_;
    $d->{State} = "OK";
    $d->{'Last Backup'} = main->formattedDate;
    $opts{_dirty} = 1;
}

sub formattedDate {
    my @d = localtime;
    $d[5] -= 100 if $d[5] >= 100;
    return sprintf "%02u-%02u-%02u", $d[3], $d[4]+1, $d[5];
}

sub listAll {
    my ($self, $dirs) = @_;
    my $volumes = RJK::Win32::VolumeInfo->getVolumes();

    foreach my $vol (keys %$volumes) {
        next if $opts{ignoreDrives}{$vol};
        my $drive = $dirs->{$vol};
        my @dirs = main->readDirs($vol);

        foreach (@dirs) {
            my $dir = $drive->{$_->{name}};
            if ($dir) {
                if ($dir->{'Last Backup'}) {
                    printf "Last backup: %s\n", $dir->{'Last Backup'};
                } elsif (! $dir->{'Backup Location'}) {
                    printf "No backup location for %s\n", $_->{path};
                } else {
                    printf "No last backup: %s => %s\n", $_->{path}, $dir->{'Backup Location'};
                }
                $dir->{_exists} = 1;
            } elsif ($opts{unknown}) {
                print "Unknown: $_->{path}\n";
            }
        }

        foreach (values %$drive) {
            if (! $_->{_exists}) {
                printf "Dir no longer exists: %s => %s\n",
                    $_->{Name}, $_->{'Backup Location'}||'(no backup location)';
            }
        }
    }
}

sub readDirs {
    my ($self, $driveLabel) = @_;

    my $driveLetter = main->getDriveLetter($driveLabel) || $driveLabel;
    my $dir = "$driveLetter:\\";
    my @dirs;

    opendir my $dh, $dir or die "$!: $dir";
    while (readdir $dh) {
        my $path = "$dir$_";
        next if !-d $path;
        if (! -x $path) {
            warn "Not accessible: $path";
            next;
        }
        push @dirs, { driveLetter => $driveLetter, dir => $dir, name => $_, path => $path };
    }
    closedir $dh;

    return @dirs;
}

sub getDriveLetter {
    my ($self, $driveLabel) = @_;
    $opts{_drives} //= RJK::Filecheck->getDrives;
    return $opts{_drives}{$driveLabel}{Letter};
}
