package File::File;

# Author: Rob Klinkhamer
# $Revision: 1.54 $
# $Date: 2017/09/20 17:50:55 $
# $Source: c:\data\cvs\scripts/perllib/File/File.pm,v $

use strict;
use warnings;
use File::Spec::Functions qw(catfile catpath splitpath rel2abs);

our $curdir = File::Spec->curdir();
our $updir = File::Spec->updir();

use Class::AccessorMaker {
    # [path]
    # [mountPoint][dirs][name]
    # [mountPoint][drivePath]
    # [volume][dirs][name]
    # [parentPath|dir][name]
    path => "",
    volume => "",
    dirs => "",
    parentPath => "",
    dir => "", # equal to parentPath
    name => "",

    # status values and flags
    size => undef,
    exists => undef,
    isDir => undef,
    isFile => undef,
    isRoot => undef,
    isWritable => undef,
    isExecutable => undef,
    accessed => undef,
    modified => undef,
    created => undef,
    isLink => undef,

    id => undef,
    crc => undef,
}, "no_new";

sub children { $_[0]{children} }
sub names { keys %{$_[0]{children}} }

sub new {
    my $self = bless {}, shift;
    # new(path, %opts) or new(%opts)
    my %opts = @_ % 2 ? (path => @_) : @_;
    map { $self->{$_} = $opts{$_} } keys %opts;

    $self->{children} = {};

    if ($self->{path}) {
        $self->setPath($self->{path});
    } elsif (defined $self->{name}) {
        $self->{parentPath} or $self->{parentPath} = $self->{dir};
        my $parent = $self->{parent};
        if ($parent) {
            $self->setParentPath($parent->{path});
            $self->{parent} = $parent;
        } elsif ($self->{parentPath}) {
            $self->setParentPath($self->{parentPath});
        } elsif ($self->{volume} && $self->{dirs}) {
            $self->setPath(catpath(
                $self->{volume},
                $self->{dirs},
                $self->{name} || ""
            ));
        } elsif ($self->{name} !~ /:$/) {
            # resolve path from name
            $self->{path} = rel2abs($self->{name});
            $self->setPath($self->{path});
        } else {
            return;
        }
    } else {
        return;
    }

    return $self;
}

sub setPath {
    my ($self, $path) = @_;
    $path =~ s/[\\\/]+$//;
    $path =~ s/^(\w:)/\U$1/;
    $path .= "\\" if $path =~ /:$/;
    $self->{path} = $path;
    $self->{parent} = undef;

    my @sp = splitpath($path);
    $self->{volume} = $sp[0];
    $self->{dirs} = $sp[1];
    $self->{name} = $sp[2];
    $self->{parentPath} =
    $self->{dir} = catpath($self->{volume}, $self->{dirs}, "");

    if ($self->{parentPath} eq $self->{path}) {
        $self->{isRoot} = 1;
        $self->{parentPath} =
        $self->{dir} = undef;
    }
}

sub setParent {
    my ($self, $parent) = @_;
    $self->{path} = catfile($parent->{path}, $self->{name});
    $self->setPath($self->{path});
    $self->{parent} = $parent;
}

sub setParentPath {
    my ($self, $dir) = @_;
    $self->{path} = catfile($dir, $self->{name});
    $self->setPath($self->{path});
}

sub setName {
    my ($self, $name) = @_;
    $self->{name} = $name;
    $self->{path} = catfile($self->{parentPath}, $name);
}

sub setBasename {
    my ($self, $basename) = @_;
    my $extension = $self->extension;
    $self->setName("$basename.$extension");
}

sub setExtension {
    my ($self, $extension) = @_;
    my $basename = $self->basename;
    $self->setName("$basename.$extension");
}

# static function for getting File object from arguments
sub getFile {
    my %opts = @_ % 2 ? (path => @_) : @_;
    return $opts{file} if $opts{file};

    $opts{path} = $opts{dir} if $opts{dir};
    return unless $opts{path} || $opts{name}
        || ($opts{volume} && $opts{dirs});

    return new File::File(
        path => $opts{path},
        name => $opts{name},
        volume => $opts{volume},
        dirs => $opts{dirs},
    );
}

sub parent {
    my $self = shift;
    my $parent = $self->{parent};
    if (! $parent && $self->{parentPath}) {
        $parent = $self->{parent} =
            __PACKAGE__->new($self->{parentPath});
    }
    return $parent;
}

sub getChild {
    my ($self, $name) = @_;
    my $child = $self->{children}{$name};
    if (! $child && $self->{path}) {
        $child = $self->{children}{$name} =
             __PACKAGE__->new(
                name => $name,
                parent => $self,
            );
    }
    return $child;
}

sub getSibling {
    my ($self, $name) = @_;
    my $dir = $self->parent;
    return $dir ? $dir->getChild($name) : undef;
}

sub stat {
    my $self = shift;
    if (my @stat = CORE::stat $self->{path}) {
        $self->{exists} = 1;
        $self->{isDir} = -d _;
        $self->{isFile} = -f _;
        $self->{isWritable} = -w _;
        $self->{isExecutable} = -x _;
        $self->{size} = $stat[7];
        $self->{accessed} = $stat[8];
        $self->{modified} = $stat[9];
        $self->{created} = $stat[10];
        $self->{isLink} = -l $self->{path}; # updates stat buffer, don't use _ for this file hereafter!
    } else {
        $self->{exists} = 0;
    }
    return $self;
}

sub toString {
    $_[0]{path};
}

# '0' can be a filename extension, use defined to check if there is a
# filename extension!
# Extension/basename regex:
# At least one character before dott, e.g. the filename '.profile' has
# no extension. The dott indicates a hidden file, not the start of the
# filename extension.
sub extension {
    #~ ($_[0]{name} =~ /[^.]\.([^\.]+)$/)[0] || '';
    ($_[0]{name} =~ /.+\.(.*)/)[0] // '';
}

sub basename {
    #~ ($_[0]{name} =~ /(.+)\.[^\.]+$/)[0] || $_[0]{name};
    ($_[0]{name} =~ /(.+)\..*/)[0] // $_[0]{name};
}

# volume = [driveLetter]:
sub driveLetter {
    ($_[0]{volume} =~ /(.):/)[0];
}

# dirs + name
# path = [mountPoint][dirs][name]
# path = [mountPoint][drivePath]
sub drivePath {
    #~ catdir($_[0]{dirs}, $_[0]{name});
    catpath('', $_[0]{dirs}, $_[0]{name});
}

sub touch {
    return if -e $_[0]{path};
    open my $f, '>', $_[0]{path};
    close $f;
}

1;
