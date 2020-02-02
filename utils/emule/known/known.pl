use strict;
use warnings;

use RJK::Options::Pod;

use DBI;
use DBD::mysql;

use RJK::DbTable;
use RJK::LocalConf;

###############################################################################
=head1 DESCRIPTION

Store F<known.met> CVS data exported by I<eMule MET Viewer> in a database table.

=head1 SYNOPSIS

known.pl [options]

=head1 DISPLAY EXTENDED HELP

script.pl -h

=for options start

=head1 HELP OPTIONS

=over 4

=item B<-h -help -?>

Display this extended help.

=item B<-hh "-help -help" -??>

Display message options.

=item B<-hhh "-help -help -help" -???>

Display POD options.

=item B<-hhhh "-help -help -help -help" -????>

Display complete help.

=back

=head1 CONFIGURATION OPTIONS

=over 4

=item B<-i -input-file [path]>

Input CSV file exported by eMule MET Viewer.

=item B<-o -output-file [path]>

Write database contents to CVS file.

=item B<-f -force>

Force file overwrite.

=item B<-n -no-commit>

Do not commit database changes and don't write anything to disk.

=item B<-c -commit-size [n]>

Commit after [n] database inserts/updates. Default: 100

=item B<-s -show-info-after [n]>

Show process information after each [n] lines processed. Default: 100

=item B<-l -log [path]>

Append to log. Optional [path] to file, default: write log file to cwd using filename format: "known-[timestamp].log". Ignored when using <-n>.

=item B<-db-host [string]>

Database host.

=item B<-db-user [string]>

Database user.

=item B<-db-pass [string]>

Database password.

=item B<-db-name [string]>

Database name.

=back

=head1 MESSAGE OPTIONS

=over 4

=item B<-v -verbose>

Be verbose.

=item B<-q -quiet>

Be quiet.

=item B<-debug>

Display debug information.

=back

=head1 POD OPTIONS

=over 4

=item B<-podcheck>

Run podchecker.

=item B<-pod2html -html [path]>

Run pod2html. Writes to [path] if specified. Writes to
F<[path]/{scriptname}.html> if [path] is a directory.
E.g. C<--html .> writes to F<./{scriptname}.html>.

=item B<-genpod>

Generate POD for options.

=item B<-writepod>

Write generated POD to script file.
The POD text will be inserted between C<=for options start> and
C<=for options end> tags.
If no C<=for options end> tag is present, the POD text will be
inserted after the C<=for options start> tag and a
C<=for options end> tag will be added.
A backup is created.

=back

=for options end

=cut
###############################################################################

my %opts = RJK::LocalConf::GetOptions("emule-known.conf");

RJK::Options::Pod::GetOptions(
    ['HELP OPTIONS'],
    RJK::Options::Pod::HelpOptions([
        [ "DESCRIPTION|SYNOPSIS|HELP OPTIONS|CONFIGURATION OPTIONS", "Display this extended help." ],
        [ "MESSAGE OPTIONS", "Display message options." ],
        [ "POD OPTIONS", "Display POD options." ],
        [ "", "Display complete help." ]
    ]),

    ['CONFIGURATION OPTIONS'],
    'i|input-file=s' => \$opts{inputFile}, [ "Input CSV file exported by eMule MET Viewer.", "path" ],
    'o|output-file=s' => \$opts{outputFile}, [ "Write database contents to CVS file.", "path" ],
    'f|force' => \$opts{force}, "Force file overwrite.",
    'n|no-commit' => \$opts{noCommit}, "Do not commit database changes and don't write anything to disk.",
    'c|commit-size=i' => \$opts{commitSize}, "Commit after [{n}] database inserts/updates. Default: 100",
    's|show-info-after=i' => \$opts{showInfoAfterLinesProcessed},
        "Show process information after each [{n}] lines processed. Default: 100",
    'l|log:s' => \$opts{log},
        "Append to log. Optional [{path}] to file, default: write log file to cwd using".
        " filename format: \"known-[timestamp].log\". Ignored when using <-n>.",

    'db-host=s' => \$opts{host}, "Database host.",
    'db-user=s' => \$opts{user}, "Database user.",
    'db-pass=s' => \$opts{password}, "Database password.",
    'db-name=s' => \$opts{database}, "Database name.",

    ['MESSAGE OPTIONS'],
    RJK::Options::Pod::MessageOptions(\%opts),

    ['POD OPTIONS'],
    RJK::Options::Pod::Options
);

$opts{inputFile} //
$opts{outputFile} // RJK::Options::Pod::pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

# quiet!
$opts{verbose} = 0 if $opts{quiet};

$opts{commitSize} ||= 100;
$opts{showInfoAfterLinesProcessed} ||= 100;

###############################################################################

my $header = 'Filename;File Size;Temporary Filename;Last Written (UTC);'
    .'Last Posted (UTC);Last Shared (UTC);Requests Total;Requests Accepted;'
    .'Bytes Uploaded;Upload Priority;Artist;Album;Title;Length (sec);'
    .'Bitrate;Codec;File Type;File Hash';

my $stats = {
    inserts => 0, updates => 0, total => 0,
    different => 0, missing => 0, identical => 0, changed => 0
};

my $dbh = dbConnect();

my $table = new RJK::DbTable(
    dbh => $dbh,
    table => "known_met",
    cols => [qw(Filename File_Size Temporary_Filename Last_Written
        Last_Posted Last_Shared Requests_Total Requests_Accepted
        Bytes_Uploaded Upload_Priority Artist Album Title Length
        Bitrate Codec File_Type File_Hash)],
    pkCol => "File_Hash",
    eventHandlers => {
        postInsert => sub { $stats->{inserts}++ },
        postUpdate => sub { $stats->{updates}++ },
        onDifferent => sub {
            my ($id, $object, undef, $changes) = @_;
            info(sprintf "U %s %s", $id, $object->{Filename});
            foreach (@$changes) {
                info(sprintf "%s:%s->%s", $_->{column}, $_->{dbValue}, $_->{value});
            }
            $stats->{different}++;
            return $opts{noCommit};
        },
        onMissing => sub {
            my ($id, $object) = @_;
            info(sprintf "I %s %s", $id, $object->{Filename});
            $stats->{missing}++;
            return $opts{noCommit};
        },
        onIdentical => sub { $stats->{identical}++ },
        onChange => sub { $stats->{changed}++ },
    }
);

my $logFh;
if (! $opts{noCommit} && defined $opts{log}) {
    if ($opts{log} eq '') {
        open $logFh, '>', "known-". time() . ".log" or die "$!";
    } else {
        open $logFh, '>>', $opts{log} or die "$!";
    }
}

$SIG{INT} = sub {
    my ($signal) = @_;
    exit;
};

END {
    dbDisconnect();
    print "Bye!\n" if $opts{verbose} && ! $opts{help};
}

if ($opts{outputFile}) {
    if (-e $opts{outputFile}) {
        if ($opts{force}) {
            print "Output file exists, forced overwrite.\n";
        } else {
            print "Output file exists, use -f to overwrite.\n";
            exit;
        }
    }
    createCSV();
}
if ($opts{inputFile}) {
    updateDb();
}

dbDisconnect();

sub createCSV {
    my $fh;
    if ($opts{noCommit}) {
        $fh = *STDOUT;
    } else {
        open $fh, '>:encoding(utf8)', $opts{outputFile} or die "$!";
    }

    print $fh $header, "\n";

    foreach my $row (@{$dbh->selectall_arrayref($table->{selectStatement})}) {
        $row->[0] = "\"$row->[0]\"" if $row->[0] =~ /;/;
        $row->[$_] =~ s/[- :]//g for 3..5;
        print $fh join(";", map { $_ // '' } @$row), "\n";

        if (++$stats->{total} % $opts{showInfoAfterLinesProcessed} == 0) {
            print "$stats->{total} lines processed\n";
        }
    }
    close $fh;

    if ($stats->{total} % $opts{showInfoAfterLinesProcessed}) {
        print "$stats->{total} lines processed\n";
    }
}

sub updateDb {
    open my $fh, '<:encoding(utf8)', $opts{inputFile} or die "$!";
    while (<$fh>) {
        chomp;
        if ($. == 1) {
            if (substr($_, 1) ne $header and $_ ne $header) {
                die "Header check failed";
            }
            next;
        }

        my @values;
        if (s/^"(.*)";//) {
            $values[0] = $1;
        }
        push @values, split /;/;

        foreach (@values) {
            $_ = undef if $_ eq '';
        }
        dateFormat(\$values[$_]) for 3..5;

        my $changes = $table->sync(\@values);
        if (@$changes && $stats->{changed} % $opts{commitSize} == 0) {
            commit();
        }

        $stats->{total}++;
        if ($stats->{total} % $opts{showInfoAfterLinesProcessed} == 0) {
            printInfo();
        }
    }
    close $fh;

    if ($stats->{changed} && $stats->{changed} % $opts{commitSize}) {
        commit();
    }

    if ($stats->{total} % $opts{showInfoAfterLinesProcessed}) {
        printInfo();
    }

    print "$stats->{total} lines processed, ";
    if ($opts{noCommit}) {
        print "no rows committed\n";
    } else {
        print "$stats->{changed} rows committed\n";
    }
}

sub printInfo {
    print "T:$stats->{total} I:$stats->{inserts} U:$stats->{updates} O:$stats->{identical} C:$stats->{changed}\n";
}

sub info {
    my $msg = shift;
    print "$msg\n";
    print $logFh "$msg\n" if $logFh;
}

sub commit {
    if ($opts{noCommit}) {
        print "Skipping commit\n" if $opts{verbose};
        return;
    }
    print "Commit\n" if $opts{verbose};
    $dbh->commit;
}

sub dateFormat {
    my $str = shift;
    $$str =~ s/(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/$1-$2-$3 $4:$5:$6/;
}

sub dbConnect {
    my $dsn = "dbi:mysql:$opts{database}:$opts{host}:3306";
    my $dbh = DBI->connect($dsn, $opts{user}, $opts{password},
        {   HandleError => sub { die(shift) },
            mysql_enable_utf8 => 1,
            AutoCommit => 0
        }) or die "Couldn't connect to database: " . DBI->errstr;

    return $dbh;
}

sub dbDisconnect {
    $table->invalidate() if $table;
    $dbh->disconnect if $dbh;
}
