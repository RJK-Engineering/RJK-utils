package Conf;

use strict;
use warnings;

use RJK::Exceptions;
use RJK::Module;
use RJK::Path;
use RJK::TotalCmd::Settings::Ini;
use Try::Tiny;

my @tcSearches;
my $extensions;
my $visitors;
my $fileTypeVisitors;
my $tcmdini = new RJK::TotalCmd::Settings::Ini;

sub new {
    my $class = shift;
    my $self = bless shift, $class;
    $self->load();
    return $self;
}

sub load {
    my ($self) = @_;

    $tcmdini->read;
    my $searches = $tcmdini->getSearches();

    foreach my $fileType (keys %{$self->{fileTypes}}) {
        my $typeConf = $self->{fileTypes}{$fileType};
        if (ref $typeConf) {
            if ($typeConf->{tcSearch}) {
                if (my $search = $searches->{$typeConf->{tcSearch}}) {
                    push @tcSearches, {
                        search => $search,
                        fileType => $fileType
                    };
                } else {
                    warn "Unknown tc search: $typeConf->{tcSearch}";
                }
            }
        } else {
            my $exts;
            foreach (split /\s+/, $typeConf) {
                if ($exts->{$_}) {
                    warn "Skipping duplicate extension: $_";
                    next;
                }
                $exts->{$_} = 1;
                push @{$extensions->{$_}}, $fileType;
            }
        }
    }
    foreach (@{$self->{visitors}}) {
        my $module = ref ? $_->[0] : $_;
        my $conf = $_->[1] if ref;
        try {
            my $class = RJK::Module->load("Visitors", $module);
            push @$visitors, $class->new($conf);
        } catch {
            RJK::Exceptions->handle(
                ModuleNotFoundException => sub {
                    print "Module not found: $_->{module}\n";
                }
            );
        };
    }
    foreach my $fileType (keys %{$self->{fileTypeVisitors}}) {
        foreach (@{$self->{fileTypeVisitors}{$fileType}}) {
            my $module = ref ? $_->[0] : $_;
            my $conf = $_->[1] if ref;
            try {
                my $class = RJK::Module->load("Visitors", $module);
                push @{$fileTypeVisitors->{$fileType}}, $class->new($conf);
            } catch {
                RJK::Exceptions->handle(
                    ModuleNotFoundException => sub {
                        print "Module not found: $_->{module}\n";
                    }
                );
            };
        }
    }
}

sub getVisitors {
    $visitors;
}

sub getFileTypeVisitors {
    my ($self, $fileTypes) = @_;
    [ map { $fileTypeVisitors->{$_} ? @{$fileTypeVisitors->{$_}} : () } @$fileTypes ];
}

sub getFileTypes {
    my ($self, $file, $stat) = @_;
    my %fileTypes;
    if (my $fts = $extensions->{$file->extension}) {
        $fileTypes{$_} = 1 foreach @$fts;
    }
    foreach (@tcSearches) {
        if ($_->{search}->match($file, $stat)) {
            $fileTypes{$_->{fileType}} = 1;
        }
    }
    return [keys %fileTypes];
}

1;
