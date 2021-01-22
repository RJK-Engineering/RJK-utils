package Search;

use strict;
use warnings;

use Log::Log4perl;

use RJK::Env;
use RJK::Util::JSON;

use FileSearch;
use TotalCmdSearches;
use UnicodeConsoleView;

my $opts;

sub execute {
    my $self = shift;
    $opts = shift;

    if ($opts->{log4perlConf}) {
        Log::Log4perl::init(RJK::Env->subst($opts->{log4perlConf}));
    } else {
        Log::Log4perl::init(\q(
            log4perl.logger.search=DEBUG, StdErr
            log4perl.logger.warnings=WARN, StdErr
            log4perl.appender.StdErr=Log::Log4perl::Appender::Screen
            log4perl.appender.StdErr.stderr=1
            log4perl.appender.StdErr.layout=Log::Log4perl::Layout::SimpleLayout
        ));
    }

    my $logger = Log::Log4perl->get_logger('search');

    $opts->{statusFile} = RJK::Env->subst($opts->{statusFile});

    go();
}

sub go {
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
