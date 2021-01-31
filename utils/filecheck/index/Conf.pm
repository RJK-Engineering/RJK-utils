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
my $fileVisitors;
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

    foreach my $fileType (keys %{$self->{fileTypes}}) {
        my $typeConf = $self->{fileTypes}{$fileType};
        if (ref $typeConf) {
            if ($typeConf->{tcSearch}) {
                push @tcSearches, {
                    search => $tcmdini->getSearch($typeConf->{tcSearch}),
                    fileType => $fileType
                };
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
    foreach my $fileType (keys %{$self->{fileVisitors}}) {
        my $visitorConf = $self->{fileVisitors}{$fileType};
        foreach (@$visitorConf) {
            my $module = ref ? $_->[0] : $_;
            my $conf = $_->[1] if ref;
            try {
                my $class = RJK::Module->load("Visitors", $module);
                push @{$fileVisitors->{$fileType}}, $class->new($conf);
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
    my ($self, $fileTypes) = @_;
    [ map {
        $fileVisitors->{$_} ? @{$fileVisitors->{$_}} : ();
    } @$fileTypes ];
}

sub getFileTypes {
    my ($self, $file, $stat) = @_;
    my %fileTypes;
    if (my $fts = $extensions->{$file->extension}) {
        $fileTypes{$_} = 1 foreach @$fts;
    }
    foreach (@tcSearches) {
        if (my $result = $_->{search}->match($file, $stat)) {
            $fileTypes{$_->{fileType}} = 1;
        }
    }
    return [keys %fileTypes];
}

1;
