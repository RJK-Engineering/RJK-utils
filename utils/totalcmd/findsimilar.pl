use strict;
use warnings;

use File::File;
use TotalCmd::ListFile;
use Win32::Clipboard;

my $filename = shift @ARGV;
$filename //= "C:\\CMDDE62.tmp";
@ARGV = qw(pre post joined size);

my %opts;
%opts = (
    listFile => $filename,
    groupBy => [@ARGV],
    maxDigits => 4,

    # -1 = last number in filename is sequence number (default)
    # 1 = first number in filename is sequence number
    #~ numberPosition => -1,
    numberPosition => 1,
    sizeGroupSize => 1000,

    setClipboard => 1,
    pauseBeforeExit => 1,
    show => 1,
);

$opts{groupByIndex} = { map { $_ => 1 } @{$opts{groupBy}} };

my $selection = new TotalCmd::ListFile($opts{listFile});
my $files = load($selection);
my $groups = group($files->{dirs});
#~ show($groups) if $opts{show};
#~ $groups = merge($groups);
#~ show($groups) if $opts{show};
my $result = filter($groups, $files->{selection});
show($result) if $opts{show};

setClipboard($result) if $opts{setClipboard};

if ($opts{pauseBeforeExit}) {
    print "Press return to exit.\n";
    <STDIN>;
}

sub load {
    my $selection = shift;
    my (%dirs, %selection);
    foreach my $path ($selection->files) {
        # TODO skip files
        my $f = new File::File($path);
        if (! $dirs{$f->dir}) {
            $dirs{$f->dir} = $f->parent->files;
        }
        $selection{$f->dir}{$f->name} = $f;
    }
    return { dirs => \%dirs, selection => \%selection };
}

sub group {
    my $dirs = shift;
    my %index;

    my $meta = {};
    if ($opts{groupByIndex}{sizeGroup}) {
        $meta->{sizeGroup} = sub {
            my ($file, $data) = @_;
            my $size = -s $file->path;
            $data->{sizeGroup} = [
                $opts{sizeGroupSize} * int ($size / $opts{sizeGroupSize}),
                $opts{sizeGroupSize} * int ($size / $opts{sizeGroupSize}) - int($opts{sizeGroupSize} / 2)
            ];
        };
    }
    if ($opts{groupByIndex}{size}) {
        $meta->{size} = sub {
            my ($file, $data) = @_;
            $data->{size} = -s $file->path;
        };
    }
    if (grep { $opts{groupByIndex}{$_} } qw(pre post joined)) {
        $meta->{fileSequence} = sub {
            my ($file, $data) = @_;
            my @fields = split /(\d+)/, $file->basename;
            return if @fields == 1;

            my $pos = 2 * $opts{numberPosition};
            if ($opts{numberPosition} < 0) {
                $pos += @fields;
                return if $pos < 0;
                $pos += 1 unless @fields % 2; # even number of elements in list = no chars after last nr
            } else {
                $pos--;
                return if $pos >= @fields;
            }

            if ($opts{debug}) {
                $data->{_pos} = $pos;
                $data->{_fields} = "(" . (join ")-(", @fields) . ")";
            }
            $data->{nr} = $fields[$pos];
            $data->{joined} = join("", split /\d+/, $file->basename);
            $data->{post} = join("", splice @fields, $pos+1);
            $data->{pre} = join("", splice @fields, 0, $pos);
        };
    }

    my $getFile = sub {
        my $file = shift;
        my $f = { file => $file };
        foreach my $key (keys %$meta) {
            $meta->{$key}($file, $f);
        }
        return $f;
    };

    foreach my $dir (keys %$dirs) {
        foreach my $file (@{$dirs->{$dir}}) {
            my $f = $getFile->($file);
            next if ! $f;
            for my $by (@{$opts{groupBy}}) {
                next if ! exists $f->{$by};
                my $value = $f->{$by};
                if (ref $value eq 'ARRAY') {
                    foreach my $v (@$value) {
                        push @{$index{$dir}{$by}{$v}}, $f;
                    }
                } else {
                    push @{$index{$dir}{$by}{$value}}, $f;
                }
            }
        }
    }

    return wantarray ? %index : \%index;
}

sub filter {
    my ($groups, $selection) = @_;
    my %result;

    foreach my $dir (keys %$groups) {
        my $groups = $groups->{$dir};
        foreach my $groupName (keys %$groups) {
            my $group = $groups->{$groupName};
            #~ print "$dir ($groupName)\n";
            foreach my $groupedBy (keys %$group) {
                my $files = $group->{$groupedBy};
                next if @$files == 1;

                my $found;
                foreach my $f (@$files) {
                    $found = exists $selection->{$dir}{$f->{file}->name};
                    last if $found;
                }
                next if not $found;

                #~ print "  $groupedBy\n";
                #~ foreach my $f (@$files) {
                #~     print "    $f->{file}{name}\n";
                #~ }
                $result{$dir}{$groupName}{$groupedBy} = $files;
            }
        }
    }

    return wantarray ? %result : \%result;
}

sub merge {
    my $groups = shift;
    my %result;

    foreach my $dir (keys %$groups) {
        my $groups = $groups->{$dir};
        my $group = $groups->{sizeGroup};
        #~ print "$dir\n";
        foreach my $groupedBy (sort { $a <=> $b } keys %$group) {
            my $files = $group->{$groupedBy};
            my $prevGroupedBy = $groupedBy - $opts{sizeGroupSize};
            my $prevGroupedByFiles = $group->{$prevGroupedBy};
            if (exists $group->{$prevGroupedBy}) {
                my $n = @$files = @$prevGroupedByFiles;
                #~ next if $n < 3;
                push @$files, @$prevGroupedByFiles;
                delete $group->{$prevGroupedBy};
            }

            #~ print "  $groupedBy\n";
            #~ foreach my $f (@$files) {
            #~     print "    $f->{file}{name}\n";
            #~ }
            #~ $result{$dir}{$groupName}{$groupedBy} = $files;
        }
    }

    return wantarray ? %result : \%result;
}

sub show {
    my $groups = shift;

    foreach my $dir (keys %$groups) {
        my $groups = $groups->{$dir};
        foreach my $groupName (keys %$groups) {
            my $group = $groups->{$groupName};
            print "$dir ($groupName)\n";
            foreach my $groupedBy (keys %$group) {
                my $files = $group->{$groupedBy};
                next if @$files == 1;
                print "  $groupedBy\n";
                foreach my $f (@$files) {
                    if ($opts{debug}) {
                        print "    $f->{_pos}=$f->{nr} $f->{_fields}\n";
                        next;
                    }
                    print "    $f->{file}{name}\n";
                }
            }
        }
    }
}

sub setClipboard {
    my $groups = shift;
    my $clip = Win32::Clipboard();
    my %paths;

    foreach my $dir (keys %$groups) {
        my $groups = $groups->{$dir};
        foreach my $groupName (keys %$groups) {
            my $group = $groups->{$groupName};
            foreach my $groupedBy (keys %$group) {
                my $files = $group->{$groupedBy};
                next if @$files == 1;
                foreach my $f (@$files) {
                    $paths{$f->{file}{path}} = 1;
                }
            }
        }
    }

    $clip->Set(join "\n", sort keys %paths);
}

__END__

finding sequenced files
file1.ext
file2.ext

[pre][number][post].[extension]
1. find file with numbers
2. group by [pre], throw away groups having one file
3. group by [post], throw away groups having one file
4. add missing filenames to complete the sequence (between min [number] and max [number])

Max [number] detected = 9999

input
- dir (consider all files in dir)
- file selection

1. joined, groupedBy != ''
1. pre, groupedBy = ''
2.