package Search;

use strict;
use warnings;

use RJK::Log;
use RJK::Util::JSON;

use FileSearch;
use TotalCmdSearches;
use UnicodeConsoleView;

my $opts;
my $logger;

sub execute {
    my $self = shift;
    $opts = shift;
    RJK::Log->logWarnings();
    return TotalCmdSearches->listSearches() if $opts->{listSearches};

    my $tcSearch = TotalCmdSearches->getSearch($opts);
    my $view = new UnicodeConsoleView();
    my @partitions = getPartitions() unless $opts->{allPartitions};

    FileSearch->execute($view, $tcSearch, \@partitions, $opts);
}

sub getPartitions {
    my $status = RJK::Util::JSON->read($opts->{statusFile});
    my @partitions;
    if ($opts->{partitions}) {
        @partitions = split /[\Q$opts->{delimiters}\E]/, $opts->{partitions};
        if ($opts->{setDefault}) {
            $status->{partitions} = \@partitions;
            RJK::Util::JSON->write($opts->{statusFile}, $status);
        }
    } else {
        $status->{partitions} ||= [];
        @partitions = @{$status->{partitions}};
    }
    return @partitions;
}

1;
