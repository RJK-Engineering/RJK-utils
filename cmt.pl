use strict;
use warnings;

use File::Search qw(Files);
use Options::Pod;

use Win32::Clipboard;
use Win32::Console::ANSI;

###############################################################################
=head1 DESCRIPTION

Search for stored comments.

=head1 SYNOPSIS

cmt.pl [options] [search terms]

=head1 DISPLAY EXTENDED HELP

cmt.pl -h

=head1 OPTIONS

=for options start

=item B<-a -display-all>

Display all comments.

=item B<-c -copy-urls>

Copy urls to clipboard.

=item B<-C -copy-comments>

Copy full comment info to clipboard.

=item B<-u -url-search>

Search in urls.

=item B<-o -open>

Open url in browser.

=item B<-l -min-like-count [integer]>

Like count filter.

=item B<-t -tag-filter [string]>

Tag filter.

=item B<-d -comments-dir [path]>

Path to comments dir.

=item B<-f -comments-file [name]>

Name of comments file.

=item B<-L -list>

List comment files.

=back

=head1 Pod

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

=head1 Help

=over 4

=item B<-h -help -?>

Display extended help.

=back

=for options end

=cut
###############################################################################

my %opts = (
    searchIn => "text",
    commentsDir => ".",
);
Options::Pod::GetOptions(
    'a|display-all' => \$opts{displayAll}, "Display all comments.",
    'c|copy-urls' => \$opts{copyUrlsToClip}, "Copy urls to clipboard.",
    'C|copy-comments' => \$opts{copyCommentsToClip}, "Copy full comment info to clipboard.",
    'u|url-search' => \$opts{urlSearch}, "Search in urls.",
    'o|open' => \$opts{open}, "Open url in browser.",

    'l|min-like-count=i' => \$opts{minLikeCount}, "Like count filter.",
    't|tag-filter=s' => \$opts{tagFilter}, "Tag filter.",
    'd|comments-dir=s' => \$opts{commentsDir}, "{Path} to comments dir.",
    'f|comments-file=s' => \$opts{commentsFile}, "{Name} of comments file.",

    'L|list' => \$opts{list}, "List comment files.",

    ['Pod'],
    Options::Pod::Options,

    ['Help'],
    Options::Pod::HelpOptions
);

@ARGV ||
$opts{displayAll} ||
$opts{tagFilter} ||
$opts{list} ||
$opts{minLikeCount} || Options::Pod::pod2usage(
    -verbose => 99,
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

# quiet!
$opts{verbose} = 0 if $opts{quiet};

$opts{searchFor} = \@ARGV;
$opts{searchIn} = "url" if $opts{urlSearch};

###############################################################################

my @paths;

if ($opts{commentsFile}) {
    $opts{commentsFile} = "$opts{commentsDir}/$opts{commentsFile}"
        if $opts{commentsDir};
    @paths = $opts{commentsFile};
} else {
    @paths = Files(
       in => $opts{commentsDir},
       filter => sub { /^comments_?\d*\.txt$/ },
       orderBy => 'date',
    );
    if (!@paths) {
       die "No files found";
    }
}

###############################################################################

my $comment;
my $urls;
my $text;
my @searchFor;
my $matches = 0;

if (! $opts{list}) {
    @searchFor = @{$opts{searchFor}};
    print "Search for: @searchFor\n" if @searchFor;
}

foreach (@paths) {
    if ($opts{list}) {
        print "$_\n";
    } else {
        $matches += search($_);
    }
}

if ($matches) {
    print "$matches results total" if @paths > 1;

    if ($opts{copyUrlsToClip}) {
        my $clip = Win32::Clipboard();
        $clip->Set($urls);
    } elsif ($opts{copyCommentsToClip}) {
        my $clip = Win32::Clipboard();
        $clip->Set($text);
    }
}

sub search {
    my $file = shift;
    print "File: $file\n\n";
    my $matches = 0;

    open my $fh, '<', $file or die "$!";
    while (<$fh>) {
        chomp;
        if (/^ (?: ([A-Z,]*) -)? (https?:\/\/.*)/x) {
            $matches += comment($comment);
            $comment = {
                tags => $1,
                url => $2,
                text => "",
            };
        } elsif ($_) {
            if ($_ =~ s/^!!!(\d+)-//) {
                $comment->{likeCount} = $1;
            }
            $comment->{text} .= "$_\n";
        }
    }
    close $fh;

    $matches += comment($comment);
    print $matches ? "$matches results\n\n" : "No results\n\n";
    return $matches;
}

sub comment {
    my ($comment, $matches) = @_;
    $comment or return 0;

    foreach my $s (@searchFor) {
        $comment->{$opts{searchIn}} =~ s/$s/\e\[1;4;33m$s\e\[21;24;37m/gi;
    }

    if (match($comment)) {
        matched($comment);
        return 1;
    }
    return 0;
}

sub match {
    my $comment = shift;

    if ($opts{minLikeCount}) {
        return 0 if ! $comment->{likeCount};
        return 0 if $comment->{likeCount} < $opts{minLikeCount};
    }
    if ($opts{tagFilter}) {
        return 0 if ! $comment->{tags};
        return 0 if $comment->{tags} !~ /$opts{tagFilter}/i;
    }

    my $searchIn = $comment->{$opts{searchIn}};
    foreach (@searchFor) {
        if ($searchIn !~ /$_/i) {
            return 0;
        }
    }
    return 1;
}

sub matched {
    my $comment = shift;
    $urls .= "$comment->{url}\n";
    $text .= "$comment->{url}\n";
    $text .= "$comment->{text}\n";
    print "$comment->{url}\n";
    print "$comment->{tags}\n" if $comment->{tags};
    print "$comment->{likeCount} likes\n" if $comment->{likeCount};
    print "$comment->{text}\n";
}
