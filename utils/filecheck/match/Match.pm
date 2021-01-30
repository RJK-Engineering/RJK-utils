package Match;

use strict;
use warnings;

use RJK::Filename;
use RJK::Options::Util;
use RJK::Path;
use RJK::Paths;
use RJK::Util::SharedWordSequences;

sub execute {
    my ($self, $opts) = @_;
    my $file = RJK::Paths->get($opts->{file});

    my @words = RJK::Filename->cleanup($file->name);
    my $minLength = 6;
    my @long = grep { length >= $minLength } @words;

    my %wordInSentences;
    my %sharedSequences;

    RJK::Options::Util->traverseFiles($opts, sub {
        my $path = shift;
        return if $path eq $file;
        my @name = $path->basename =~ /(\w+)/g;

        my $shared = RJK::Util::SharedWordSequences->get(\@name, \@words, 2);
        $sharedSequences{$path} = [ sort { @$b <=> @$a } @$shared ] if @$shared;

        foreach my $w (@long) {
            push @{$wordInSentences{$w}}, "$path" if grep { $_ eq $w } @name;
        }
    });

    my %files;
    foreach (keys %sharedSequences) {
        next if ! @{$sharedSequences{$_}[0]} > 1;
        print "$_\n";
        $files{$_} = 1;
        return unless --$opts->{numberOfResults};
    }

    foreach (sort { length $b <=> length $a } keys %wordInSentences) {
        foreach (@{$wordInSentences{$_}}) {
            next if $files{$_};
            print "$_\n";
            $files{$_} = 1;
            return unless --$opts->{numberOfResults};
        }
    }
}

1;
