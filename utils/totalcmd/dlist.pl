use strict;
use warnings;

use RJK::File::Paths;
use RJK::TotalCmd::DownloadList;

my ($op, $from, $to) = @ARGV;
my $dlistfile = 'c:\data\totalcmd\dlist.txt';

my $dlist = new RJK::TotalCmd::DownloadList();

if ($op) {
    if ($op =~ /^clear$/) {
        $dlist->write($dlistfile);
        exit;
    } elsif ($op =~ /^e$/) {
        exit system "edit", $dlistfile;
    }
}

if (!$to) {
    print "USAGE: $0 [op] [from] [to]\n";
    print "[op] = clear | c(opy) | m(ove) | e(dit)\n";
    exit 1;
}

if ($op =~ /^m/) {
    $op = 'move';
} elsif ($op =~ /^c/) {
    $op = 'copy';
} else {
    die "Invalid operation: $op";
}

if ($to =~ /\\$/) {
    my $path = RJK::File::Paths->get($from);
    $to .= $path->{name};
}

# Skip all + Skip all which cannot be opened for reading
#~ $dlist->addFlags("136");
#~ $dlist->addClearFlags();
$dlist->add($op, $from, $to);

$dlist->append($dlistfile);
