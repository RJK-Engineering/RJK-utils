package Sync;

use Time::HiRes ();

use RJK::HumanReadable::Size;
use RJK::SimpleFileVisitor;
use RJK::Files;
use RJK::Win32::Console;

use SyncFileVisitor;

my $opts;
my $sizeFormatter = 'RJK::HumanReadable::Size';
my $console = new RJK::Win32::Console();

sub execute {
    my $self = shift;
    $opts = shift;

    opendir my $dh, $opts->{targetDir} or die "$!";
    my @dirs = grep { -d "$opts->{targetDir}\\$_" && ! /^\./ } readdir $dh;
    closedir $dh;

    if (! @dirs) {
        die "No dirs in target: $opts->{targetDir}";
    }

    foreach (@dirs) {
        print "Dir: $_\n";
    }

    my $filesInTarget = indexTarget(\@dirs);
    synchronize(\@dirs, $filesInTarget);
}

sub indexTarget {
    my $dirs = shift;
    my $lastDisplay = 0;

    my $filesInTarget = {
        name => {},
        size => {},
    };

    my $stats = RJK::Files->createStats();
    my $visitor = new RJK::SimpleFileVisitor(
        visitFile => sub {
            my ($file, $stat) = @_;
            my $time = Time::HiRes::gettimeofday;
            if ($lastDisplay < $time - $opts->{refreshInterval}) {
                DisplayStats($stats);
                $lastDisplay = $time;
            }
            $file->{stat} = $stat;
            push @{$filesInTarget->{name}{$file->{name}}}, $file;
            push @{$filesInTarget->{size}{$stat->size}}, $file;
        },
        visitFileFailed => sub {
            my ($file, $error) = @_;
            warn "$error: $file->{path}";
        },
    );

    foreach (@$dirs) {
        my $path = "$opts->{targetDir}\\$_";
        $console->updateLine("Indexing $path ...\n");
        DisplayStats($stats);
        RJK::Files->traverse($path, $visitor, {}, $stats);
    }
    DisplayStats($stats);
    $console->newline;

    return $filesInTarget;
}

sub synchronize {
    my ($dirs, $filesInTarget) = shift;

    my $totals = RJK::Files->createStats();
    my $visitor = new SyncFileVisitor($filesInTarget, \%opts);

    foreach my $dir (@$dirs) {
        print "\nSynchronizing $dir ...\n";

        if (! -e $dir) {
            print "Directory does not exist in source: $dir\n";
            next;
        } elsif (! -d $dir) {
            warn "Source is not a directory";
            exit;
        } elsif (! -r $dir) {
            warn "Source directory is not readable";
            exit;
        }

        my $stats = RJK::Files->traverseWithStats($dir, $visitor);
        $totals->update($stats);
        DisplayStats($totals);
    }
    return $totals;
}

sub DisplayStats {
    my $stats = shift;
    $console->updateLine(
        sprintf "%s in %s files",
            $sizeFormatter->get($stats->{size}),
            $stats->{visitFile}
    );
}

1;
