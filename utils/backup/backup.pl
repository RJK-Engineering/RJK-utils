=pod

backup.pl [options] [volume] [directory]

=cut

use strict;
use warnings;

use Number::Bytes::Human qw(format_bytes);
use Try::Tiny;

use RJK::Exception;
use RJK::File::Stats;
use RJK::Filecheck;
use RJK::LocalConf;
use RJK::Options::Pod;
use RJK::TableRowFormatter;
use RJK::Util::JSON;
use RJK::Win32::VolumeInfo;

my %opts = RJK::LocalConf::GetOptions("backup/backup.properties");
@ARGV || RJK::Options::Pod::ShortHelp;

RJK::Options::Pod::GetOptions(
    ['OPTIONS'],
    "volumes" => \$opts{procVolumes}, "",
    "a|all-backup-dirs" => \$opts{allBackupDirs}, "",
    "b|backup-ok|ok=s" => \$opts{backupOk}, "Mark backup to {volume} as completed.",
    "location=s" => \$opts{location}, "",

    "ignore-drives" => \$opts{ignoreDrives}, "Comma-separated list of drives to ignore.",
    "s|calculate-usage" => \$opts{calculateUsage}, "Traverse directories and calculate size.",

    "c|create" => \$opts{create}, "",
    "u|update" => \$opts{update}, "",

    ['POD'],
    RJK::Options::Pod::Options,
    ['Help'],
    RJK::Options::Pod::HelpOptions
);

$opts{volume} = shift;
$opts{dir} = shift;

my $sizeFormatter = sub { $_[0] && format_bytes $_[0] };
my $backupDirRow = new RJK::TableRowFormatter(
    format => "%volume=-10 %name=-30 %size=4 %files=10 %backupLocation=-10 %lastBackup=8 %state",
    filters => { size => $sizeFormatter },
    header => {
        name => 'Directory',
        backupLocation => 'Backup',
        lastBackup => 'Date'
    }
);
my $volumeRow = new RJK::TableRowFormatter(
    format => "%serial=-9 %label=-12 %size=5 %used=5 %free=5",
    filters => { serial => sub { $_[0] && sprintf "0x%x", $_[0] },
        size => $sizeFormatter, used => $sizeFormatter, free => $sizeFormatter }
);

$opts{ignoreDrives} = { map { $_ => 1 } split(/\W+/, $opts{ignoreDrives}) };

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
    if ($opts{procVolumes}) {
        main->procVolumes();
    } elsif (defined $opts{backupOk}) {
        if ($opts{volume} && $opts{backupOk}) {
            main->backupOk();
        } else {
            print "Volume label and backup location required\n";
        }
    } else {
        main->procBackupDirs();
    }
    getStore()->commit();
}

sub procVolumes {
    my ($self) = @_;
    if ($opts{create}) {
        if ($opts{volume}) {
            $self->createVolume();
        } else {
            print "Drive letter required\n";
        }
    } else {
        $self->listVolumes();
    }
}

sub procBackupDirs {
    my ($self) = @_;
    if ($opts{create}) {
        if ($opts{volume} && defined $opts{dir}) {
            $self->createBackupDir();
        } else {
            print "Drive letter and directory name required\n";
        }
    } else {
        $self->listBackupDirs() if $opts{allBackupDirs} || $opts{volume};
    }
}

sub backupOk {
    my ($self) = @_;
    my $dirs = getStore()->getBackupDirs({
        volume => $opts{volume}
    });

    print $backupDirRow->header;
    foreach my $dir (@$dirs) {
        next if ! grep { /^$opts{backupOk}$/i } split /\s*,\s*/, $dir->{backupLocation};
        $dir->{state} = "OK";
        $dir->{lastBackup} = $self->formattedDate;
        getStore()->updateBackupDir($dir);
        print $backupDirRow->format($dir);
    }
}

sub createVolume {
    my ($self) = @_;
    my $activeVol = $self->getActiveVolumes->{$opts{volume}};
    if (! $activeVol) {
        print "Active volume required\n";
        return;
    }
    my $vol = {
        serial => $activeVol->{serial},
        letter => $opts{volume},
        label => $opts{dir},
    };
    $self->updateVolume($vol);
    getStore()->addVolume($vol);
    print $volumeRow->format($vol);
}

sub listVolumes {
    my ($self) = @_;
    my @volumes = sort {
        lc $a->{label} cmp lc $b->{label}
    } @{getStore()->getVolumes};

    print $volumeRow->header;
    foreach my $vol (@volumes) {
        next if $opts{volume} && $vol->{label} ne $opts{volume};
        $self->updateVolume($vol) if $vol->{letter};
        print $volumeRow->format($vol);
        getStore()->updateVolume($vol) if $opts{update};
    }
}

sub updateVolume {
    my ($self, $vol) = @_;
    my $activeVol = $self->getActiveVolumes->{$vol->{letter}};
    return if !$activeVol;

    $vol->{label} = $activeVol->{label};
    $vol->{serial} = $activeVol->{serial};

    my ($free, $total) = RJK::Win32::VolumeInfo->getUsage($vol->{letter});
    $vol->{size} = $total;
    $vol->{used} = $total - $free;
    $vol->{free} = $free;
}

sub createBackupDir {
    my ($self) = @_;
    my $dir = {
        volume => $opts{volume},
        name => $opts{dir},
    };
    $self->updateBackupDir($dir);
    if (! $dir->{exists}) {
        print "Directory does not exist\n";
        return;
    }
    getStore()->addBackupDir($dir);
    print $backupDirRow->format($dir);
}

sub listBackupDirs {
    my ($self) = @_;
    my @dirs = sort {
        lc $a->{volume} cmp lc $b->{volume} or
        lc $a->{name} cmp lc $b->{name}
    } @{getStore()->getBackupDirs};

    print $backupDirRow->header;
    foreach my $dir (@dirs) {
        next if $opts{volume} && $dir->{volume} ne $opts{volume};
        next if $opts{location} && ($dir->{backupLocation}//"") ne $opts{location};
        $self->updateBackupDir($dir);
        print $backupDirRow->format($dir);
        getStore()->updateBackupDir($dir) if $opts{update};
    }
}

sub updateBackupDir {
    my ($self, $dir) = @_;
    $dir->{path} = "$dir->{volume}:\\$dir->{name}" if $dir->{volume} && defined $dir->{name};
    return if ! $dir->{path} || !-e $dir->{path};

    $dir->{exists} = 1;
    return unless $opts{calculateUsage};

    my $stats = RJK::File::Stats->traverse($dir->{path});
    $dir->{files} = $stats->{files};
    $dir->{size} = $stats->{size};
}

my $activeVolumes;
sub getActiveVolumes {
    my ($self) = @_;
    return $activeVolumes //= RJK::Win32::VolumeInfo->getVolumes;
}

sub formattedDate {
    my @d = localtime;
    $d[5] -= 100 if $d[5] >= 100;
    return sprintf "%02u-%02u-%02u", $d[3], $d[4]+1, $d[5];
}

sub getStore {
    return RJK::Filecheck->getStore('RJK::Filecheck::Store::Foswiki');
}
