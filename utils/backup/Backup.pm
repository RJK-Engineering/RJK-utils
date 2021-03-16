package Backup;

use strict;
use warnings;

use Number::Bytes::Human qw(format_bytes);

use RJK::Files;
use RJK::Filecheck;
use RJK::TableRowFormatter;
use RJK::Win32::VolumeInfo;

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
my $opts;

sub execute {
    my $self = shift;
    $opts = shift;

    if ($opts->{procVolumes}) {
        &procVolumes;
    } elsif (defined $opts->{backupOk}) {
        if ($opts->{volume} && $opts->{backupOk}) {
            &backupOk;
        } else {
            print "Volume label and backup location required\n";
        }
    } else {
        &procBackupDirs;
    }
    &getStore->commit();
}

sub procVolumes {
    if ($opts->{create}) {
        if ($opts->{volume}) {
            &createVolume;
        } else {
            print "Volume name required\n";
        }
    } else {
        &listVolumes;
    }
}

sub procBackupDirs {
    if ($opts->{create}) {
        if ($opts->{volume} && defined $opts->{dir}) {
            &createBackupDir;
        } else {
            print "Volume and directory name required\n";
        }
    } else {
        &listBackupDirs if $opts->{allBackupDirs} || $opts->{volume};
    }
}

sub backupOk {
    my $dirs = &getStore->getBackupDirs({
        volume => $opts->{volume}
    });

    print $backupDirRow->header;
    foreach my $dir (@$dirs) {
        next if ! grep { /^$opts->{backupOk}$/i } split /\s*,\s*/, $dir->{backupLocation};
        $dir->{state} = "OK";
        $dir->{lastBackup} = &formattedDate;
        &getStore->updateBackupDir($dir);
        print $backupDirRow->format($dir);
    }
}

sub createVolume {
    my $activeVol = &getActiveVolumes->{$opts->{volume}};
    if (! $activeVol) {
        print "Active volume required\n";
        return;
    }
    my $vol = {
        serial => $activeVol->{serial},
        drive => $opts->{volume},
        label => $opts->{dir},
    };
    updateVolume($vol);
    &getStore->addVolume($vol);
    print $volumeRow->format($vol);
}

sub listVolumes {
    my @volumes = sort {
        lc $a->{label} cmp lc $b->{label}
    } @{&getStore->getVolumes};

    print $volumeRow->header;
    foreach my $vol (@volumes) {
        next if $opts->{volume} && $vol->{label} ne $opts->{volume};
        updateVolume($vol) if $vol->{drive};
        print $volumeRow->format($vol);
        &getStore->updateVolume($vol) if $opts->{update};
    }
}

sub updateVolume {
    my ($vol) = @_;
    my $activeVol = &getActiveVolumes->{$vol->{drive}};
    return if !$activeVol;

    $vol->{label} = $activeVol->{label};
    $vol->{serial} = $activeVol->{serial};

    my ($free, $total) = RJK::Win32::VolumeInfo->getUsage($vol->{drive});
    $vol->{size} = $total;
    $vol->{used} = $total - $free;
    $vol->{free} = $free;
}

sub createBackupDir {
    my $dir = {
        volume => $opts->{volume},
        name => $opts->{dir},
    };
    updateBackupDir($dir);
    if (! $dir->{exists}) {
        print "Directory does not exist\n";
        return;
    }
    &getStore->addBackupDir($dir);
    print $backupDirRow->format($dir);
}

sub listBackupDirs {
    my @dirs = sort {
        lc $a->{volume} cmp lc $b->{volume} or
        lc $a->{name} cmp lc $b->{name}
    } @{&getStore->getBackupDirs};

    print $backupDirRow->header;
    foreach my $dir (@dirs) {
        next if $opts->{volume} && $dir->{volume} ne $opts->{volume};
        next if $opts->{location} && ($dir->{backupLocation}//"") ne $opts->{location};
        updateBackupDir($dir);
        print $backupDirRow->format($dir);
        &getStore->updateBackupDir($dir) if $opts->{update};
    }
}

sub updateBackupDir {
    my ($dir) = @_;
    $dir->{path} = "$dir->{volume}:\\$dir->{name}" if $dir->{volume} && defined $dir->{name};
    return if ! $dir->{path} || !-e $dir->{path};

    $dir->{exists} = 1;
    return unless $opts->{calculateUsage};

    my $stats = RJK::Files->traverseWithStats($dir->{path});
    $dir->{files} = $stats->{files};
    $dir->{size} = $stats->{size};
}

my $activeVolumes;
sub getActiveVolumes {
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

1;
