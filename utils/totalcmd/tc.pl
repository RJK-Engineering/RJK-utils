use strict;
use warnings;

use RJK::Exception;
use RJK::Options::Pod;
use RJK::TotalCmd::Command;
use RJK::TotalCmd::Settings;
use RJK::TotalCmd::Utils;

use Try::Tiny;

###############################################################################
=head1 DESCRIPTION

Find and execute Total Commander commands.

=head1 SYNOPSIS

tc.pl [options] [paths]

    | *Command source*    | *Option*         | *Subselection*     |
    | All                 | -a               |                    |
    |                     | -n [name]        |                    |
    | Start menu          | -s [item nr]     | -m [item nr]    *3 |
    |                     |                  | -M              *4 |
    | Directory menu      | -d [item nr]     | -m [item nr]    *3 |
    |                     |                  | -M              *4 |
    | User command        | -u [nr]          |                    |
    |                     | -u -n [name]  *1 |                    |
    | Internal            | -i [nr]          | -c [category name] |
    |                     | -i -n [name]  *2 | -C [category nr]   |
    | Button              | -b [bar],[nr]    |                    |

    *1) "em_" prefix may be omitted.
    *2) "cm_" prefix may be omitted.
    *3) Show root items if no item nr is specified.
    *4) Show submenus

If no command sources are specified the custom command sources
Start menu, Directory menu, User commands and Buttons are selected.

Search: -f [terms]
Select search result: -r [result nr]
Execute command: -x/-X
Show all buttons: -B (-b without argument shows available bars)
Show shortcut keys: -k

=head1 SEARCHING

    | *Command source*     | *Search in* |
    | Start menu items     | title       |
    | Directory menu items | title       |
    | User commands        | tooltip     |
    | Buttons              | tooltip     |
    | Internal             | description |

=head1 DISPLAY EXTENDED HELP

usercmd.pl -?

=head1 OPTIONS

=for options start

=over 4

=item B<--tcmdinc [path]>

Path to Total Commander F<totalcmd.inc> file.

=item B<--tcmdini [path]>

Path to Total Commander F<INI> file.

=item B<--usercmdini [path]>

Path to Total Commander F<usercmd.ini> file.

=item B<-a --all>

Select all commands (custom and internal).

=item B<-u --user [nr]>

Select all user commands or user command number C<[nr]>.

=item B<-s --start-menu [nr]>

Select all start menu items or start menu item C<[nr]>.

=item B<-d --dir-menu [nr]>

Select all directory menu items or directory menu item C<[nr]>.

=item B<-b --button [[bar].[nr]]>

Select all buttons of button bar C<[bar]> or button C<[bar].[nr]>.

=item B<-i --internal [nr]>

Select all internal commands or internal command C<[nr]>.

=item B<-n --name [name]>

Select command with name C<[name]>.

=item B<-c --category-nr [nr]>

Show categories or select commands in category [nr].

=item B<-C --category [name]>

Show categories or select commands in category [name].

=item B<-m --menu [item nr]>

Show menu items in root or in submenu [item nr].

=item B<-M --submenus>

Show submenus.

=item B<-B --all-buttons>

Select all buttons in all bars.

=item B<-f --find [string]>

Search in command descriptions (internal), titles (start and
directory menu items) and tooltips (user commands and buttons).

=item B<-r --result [nr]>

Select search result [nr].

=item B<-k --keys>

Show shortcut keys.

=back

=head2 Executing a command

=over 4

=item B<-x --execute>

Execute selected command. The selected command is shown with its
arguments after parameter substitution.

=item B<-X --show>

Like C<-x> but do not execute.

=item B<-p --params [string]>

Override command parameter string.

=back

=head2 Source and target specification

=over 4


=item The first [paths] argument is the file or directory under the
source cursor, unless C<-S> is specified.

=item If the command doesn't require a source selection, the second
[paths] argument is the file or directory under the target cursor,
unless C<-T> is specified.

=item If the command requires a source or a target selection, they
are taken from the [paths] arguments, separated by a C<,>.
E.g: C<source1 source2 , target1 target2>.

=item If just a filename is specified, the current working directory
or the directory specified with C<-S> or C<-T> is assumed.


=back

=over 4

=item B<-L --list [path]>

Path to a file containing the source list.
Total Commander parameters: %L %l %F %f %D %d %S %s

=item B<-S --source [path]>

Path to the file or directory under the source cursor.
Total Commander parameters: %P %p %N %n %O %o %E %e

=item B<-T --target [path]>

Path to the file or directory under the target cursor.
Total Commander parameters: %T %t %M %m

=back

=head2 Output options

=over 4

=item B<-h --head [n]>

Show first I<n> results.

=item B<-t --tail [n]>

Show last I<n> results.

=item B<--bar>

Ouput bar file (INI) format.

=item B<-w --wiki>

TODO Use wiki table formatting.

=item B<-e --delimiter [string]>

Use [string] as delimiter, uses a TAB character if [string]
is equal to C<T> or C<TAB> (case insensitive).

=item B<-v --verbose>

Be verbose. Incremental.

=item B<-q --quiet>

Be quiet.

=item B<--debug>

Show debug information.

=back

=head2 Pod options

=over 4

=item B<--podcheck>

Run podchecker.

=item B<--pod2html --html [path]>

Run pod2html. Writes to [path] if specified. Writes to
F<[path]/{scriptname}.html> if [path] is a directory.
E.g. C<--html .> writes to F<./{scriptname}.html>.

=item B<--genpod>

Generate POD for options.

=item B<--savepod>

Save generated POD to script file.
The POD text will be inserted between C<=for options start> and
C<=for options end> tags.
If no C<=for options end> tag is present, the POD text will be
inserted after the C<=for options start> tag and a
C<=for options end> tag will be added.
A backup is created.

=back

=head2 Help

=over 4

=item B<--help -?>

Display extended help.

=back

=for options end

=cut
###############################################################################

my %opts = (
    delimiter => "\t",
    defaultIcon => 'wcmicons.dll,64',
    sendCommand => 'SendTCCommand',
);
RJK::Options::Pod::GetOptions(
    ['OPTIONS'],
    'tcmdinc=s' => \$opts{tcmdinc},
      "{Path} to Total Commander F<totalcmd.inc> file.",
    'tcmdini=s' => \$opts{tcmdini},
      "{Path} to Total Commander F<INI> file.",
    'usercmdini=s' => \$opts{usercmdini},
      "{Path} to Total Commander F<usercmd.ini> file.",

    'a|all' => \$opts{all},
      "Select all commands (custom and internal).",
    'u|user:i' => \$opts{user},
      "Select all user commands or user command number C<[{nr}]>.",
    's|startmenu:i' => \$opts{startMenu},
      "Select all start menu items or start menu item C<[{nr}]>.",
    'd|dirmenu:i' => \$opts{dirMenu},
      "Select all directory menu items or directory menu item C<[{nr}]>.",
    'b|button:s' => \$opts{buttonBar},
      "Select all buttons of button bar C<[bar]> or button C<{[bar].[nr]}>.",
    'i|internal:i' => \$opts{internal},
      "Select all internal commands or internal command C<[{nr}]>.",
    'n|name=s' => \$opts{name},
      "Select command with name C<[{name}]>.",

    'c|category-nr:i' => \$opts{catNumber},
      "Show categories or select commands in category [{nr}].",
    'C|category:s' => \$opts{catName},
      "Show categories or select commands in category [{name}].",
    'm|menu:i' => \$opts{menuItems},
      "Show menu items in root or in submenu [{item nr}].",
    'M|submenus' => \$opts{submenus},
      "Show submenus.",
    'B|all-buttons' => \$opts{allButtons},
      "Select all buttons in all bars.",

    'f|find=s' => \$opts{find},
      "Search in command descriptions (internal), titles (start and\n".
      "directory menu items) and tooltips (user commands and buttons).",
    'F|Find=s' => \$opts{findCommand},
      "Search in command commands.",
    'r|result=i' => \$opts{result},
      "Select search result [{nr}].",
    'k|keys' => \$opts{keys},
      "Show shortcut keys.",

    [ "Executing a command" ],

    'x|execute' => \$opts{execute},
      "Execute selected command. The selected command is shown with its\n".
      "arguments after parameter substitution.",
    'X|show' => \$opts{show},
      "Like C<-x> but do not execute.",
    'p|params=s' => \$opts{params},
      "Override command parameter string.",

    [ "Source and target specification", qq(
==item The first [paths] argument is the file or directory under the
source cursor, unless C<-S> is specified.

==item If the command doesn't require a source selection, the second
[paths] argument is the file or directory under the target cursor,
unless C<-T> is specified.

==item If the command requires a source or a target selection, they
are taken from the [paths] arguments, separated by a C<,>.
E.g: C<source1 source2 , target1 target2>.

==item If just a filename is specified, the current working directory
or the directory specified with C<-S> or C<-T> is assumed.
) ],

    'L|list=s' => \$opts{sourceList},
      "{Path} to a file containing the source list.\n".
      "Total Commander parameters: %L %l %F %f %D %d %S %s",
    'S|source=s' => \$opts{source},
      "{Path} to the file or directory under the source cursor.\n".
      "Total Commander parameters: %P %p %N %n %O %o %E %e",
    'T|target=s' => \$opts{target},
      "{Path} to the file or directory under the target cursor.\n".
      "Total Commander parameters: %T %t %M %m",

    [ "Output options" ],

    'h|head:i' => \$opts{head},
      "Show first I<{n}> results.",
    't|tail:i' => \$opts{tail},
      "Show last I<{n}> results.",

    'D|save2dirmenu:i' => \$opts{saveToDirMenu},
      "Save to directory menu, insert new submenu at the end or at position [{nr}].",
    'S|save2start:i' => \$opts{saveToStartMenu},
      "Save to start menu, insert new submenu at the end or at position [{nr}].",

    'bar' => \$opts{bar},
      "Ouput bar INI format.",
    'w|wiki' => \$opts{wiki},
      "TODO Use wiki table formatting.",
    'e|delimiter=s' => \$opts{delimiter},
      "Use [{string}] as delimiter, uses a TAB character if [string]\n".
      "is equal to C<TAB> (case insensitive).",

    'v|verbose+' => \$opts{verbose},
      "Be verbose. Incremental.",
    'q|quiet' => \$opts{quiet},
      "Be quiet.",
    'debug' => \$opts{debug},
      "Show debug information.",

    ['POD'],
    RJK::Options::Pod::Options,
    ['HELP'],
    RJK::Options::Pod::HelpOptions
);

$opts{tail} = undef if $opts{head} && $opts{tail};
$opts{head} ||= 10 if defined $opts{head};
$opts{tail} ||= 10 if defined $opts{tail};

$opts{delimiter} = "\t" if $opts{delimiter} =~ /^TAB$/i;

# quiet!
$opts{verbose} = 0 if $opts{quiet};


###############################################################################

BEGIN {
    # message functions
    *main::debug = sub ($@) {
        printf STDERR (shift . "\n", @_) if $opts{debug};
    };
    *main::error = sub ($@) {
        printf STDERR (shift . "\n", @_);
        exit;
    };
    *CORE::GLOBAL::warn = sub ($@) {
        printf STDERR (shift . "\n", @_) unless $opts{quiet};
    };
    *main::info = sub ($@) {
        printf STDERR (shift . "\n", @_) unless $opts{quiet};
    };
    *main::verbose = sub ($@) {
        printf STDERR (shift . "\n", @_) if $opts{verbose};
    };
}

###############################################################################

my $tcmd = new RJK::TotalCmd::Settings();
my $results;

try {
    GetResults();
    debug "%d commands", scalar @$results;

    if ($opts{bar}) {
        CreateButtonBar();
    } elsif (defined $opts{saveToStartMenu}) {
        SaveToMenu("user");
    } elsif (defined $opts{saveToDirMenu}) {
        SaveToMenu("DirMenu");
    } elsif (@$results == 1) {
        if ($opts{execute} || $opts{show}) {
            Execute($results->[0]);
        } else {
            Details($results->[0]);
        }
    } elsif (@$results) {
        if ($opts{execute} || $opts{show}) {
            warn "Execute: no command selected";
        } else {
            List();
        }
    } else {
        warn "No results";
    }
} catch {
    if ( $_->isa('RJK::TotalCmd::NotFoundException') ) {
        warn $_->error();
    } else {
        RJK::Exception::GeneralCatch();
    }
};

###############################################################################

sub GetResults {
    $opts{find} //= $opts{findCommand};
    my @cmds;

    if (defined $opts{startMenu} || defined $opts{dirMenu}) {
        my $menu = defined $opts{startMenu} ? "user" : "DirMenu";
        if ($opts{startMenu}) {
            @cmds = $tcmd->getMenuItem($menu, $opts{startMenu});
        } elsif (defined $opts{menuItems}) {
            if ($opts{menuItems}) {
                @cmds = $tcmd->getMenuItems($menu, $opts{menuItems});
            } else {
                @cmds = $tcmd->getMenuItems($menu, 0);
            }
        } elsif ($opts{submenus}) {
            @cmds = $tcmd->getSubmenus($menu);
        } else {
            @cmds = $tcmd->getMenuItems($menu);
        }
    } elsif (defined $opts{user}) {
        if ($opts{user}) {
            @cmds = $tcmd->getUserCommand($opts{user});
        } elsif ($opts{name}) {
            $opts{name} =~ s/^(em_)?/em_/;
            @cmds = $tcmd->getCommand($opts{name});
        } else {
            @cmds = $tcmd->getUserCommands();
        }
    } elsif (defined $opts{internal}) {
        if ($opts{internal}) {
            @cmds = $tcmd->getInternalCommand($opts{internal});
        } elsif ($opts{name}) {
            $opts{name} =~ s/^(cm_)?/cm_/;
            @cmds = $tcmd->getCommand($opts{name});
        } else {
            @cmds = $tcmd->getInternalCommands();
        }
    } elsif (defined $opts{buttonBar}) {
        if ($opts{buttonBar}) {
            my ($bar, $nr) = split /,/, $opts{buttonBar};
            if ($nr) {
                @cmds = $tcmd->getButton($bar, $nr);
            } else {
                @cmds = $tcmd->getButtons($bar);
            }
        } else {
            my @bars = $tcmd->getButtonBars();
            foreach my $bar (@bars) {
                my @buttons = $tcmd->getButtons($bar);
                info "%s$opts{delimiter}%s", $bar, scalar @buttons;
            }
            exit;
        }
    } elsif ($opts{allButtons}) {
        @cmds = $tcmd->getAllButtons();
    } elsif (defined $opts{catName} || defined $opts{catNumber}) {
        if ($opts{catName}) {
            @cmds = $tcmd->getInternalCommands($opts{catName});
        } elsif ($opts{catNumber}) {
            my $catName = $tcmd->getCategoryName($opts{catNumber});
            info "Category: $catName";
            @cmds = $tcmd->getInternalCommands($catName);
        } else {
            my $i = 1;
            foreach my $cat ($tcmd->getCommandCategories) {
                info "%s$opts{delimiter}%s", $i++, $cat;
            }
            exit;
        }
    } elsif (defined $opts{all}) {
        @cmds = $tcmd->getAllCommands();
    } elsif (defined $opts{name}) {
        @cmds = $tcmd->getCommand($opts{name});
    } elsif ($opts{keys}) {
        DisplayShortcutKeys();
        exit;
    } elsif (defined $opts{find}) {
        @cmds = $tcmd->getCustomCommands();
    } else {
        RJK::Options::Pod::pod2usage(
            -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
        );
    }

    # search
    $results = \@cmds;
    if (defined $opts{find}) {
        my @terms = split /\s+/, $opts{find};
        my $field = defined $opts{findCommand} ? 'cmd' : 'menu';

        my $i = 0;
        $results = [];
        CMD: foreach my $cmd (@cmds) {
            next unless defined $cmd->{$field};

            foreach (@terms) {
                next CMD if $cmd->{$field} !~ /$_/i;
            }

            $i++;
            if ($opts{result}) {
                if ($opts{result} == $i) {
                    $results = [ $cmd ];
                    last CMD;
                }
            } else {
                $cmd->{result} = $i;
                push @$results, $cmd;
            }
        }
    }

    # get shortcut keys
    my %keys = $tcmd->getCommandKeys();
    foreach my $cmd (@$results) {
        next if !$cmd->{name};
        my $sc = $keys{ $cmd->{name} };
        $cmd->{shortcuts} = join " ", @$sc if $sc;
    }

    # commands with shortcut keys only
    if ($opts{keys}) {
        @$results = grep { $_->{shortcuts} } @$results ;
    }

    # TODO limit
    #~ if (@$results > 1) {
    #~     # 0 .. head
    #~     my $end   = $opts{head} && $opts{head} < @$results ? $opts{head} - 1 : @$results - 1;
    #~     # last - tail .. last
    #~     my $start = $opts{tail} && $opts{tail} < @$results ? @$results - $opts{tail} : 0;
    #~     debug "Results [$start..$end]";
    #~     @$results  = $results->[$start..$end];
    #~ }
}

sub CreateButtonBar {
    my $bar = $tcmd->getButtonBar;
    foreach my $cmd (@$results) {
        $cmd->{button} //= GetIcon($cmd) // $opts{defaultIcon};
        $bar->addButton($cmd);
    }
    $bar->write;
}

sub SaveToMenu {
    my $menu = shift;
    my $title = $opts{buttonBar} // "saved by tc.pl";
    my $items = $tcmd->getMenuItems($menu);
    push @$items, {menu=>"-[ $title ]"}, @$results, {menu=>"--"};
    $tcmd->saveMenu($menu, $items);
}

sub GetIcon {
    my $cmd = shift;
    my $path = $cmd->{cmd} || return;

    my $icon = _GetIcon($path);
    if (!$icon && $cmd->{path}) {
        $path = "$cmd->{path}\\$path";
        $icon = _GetIcon($path);
    }

    debug $icon ? "Icon: $icon" : "No icon found";

    return $icon;
}

sub _GetIcon {
    my $path = shift;

    debug "Looking for .ico file";
    my $ico = $path;
    $ico =~ s/\.exe$/.ico/i;
    debug "$ico";
    return $ico if -f $ico;

    debug "Looking for icon in executable";
    debug "$path";
    return $path if -f $path && HasIcon($path);
}

sub HasIcon {
    my $file = shift;

    my ($fh, $path) = RJK::TotalCmd::Utils::TempFile("ico");
    close $fh;
    debug $path;

    my @args = ('i_view32', $file, "/convert=\"$path\"", "/silent");
    debug "@args";
    system @args;
    my $has = ! -z $path;
    unlink $path;

    return $has;
}

sub List {
    my %format = (
        all => {
            default => [ qw(
                source number name shortcuts menu cmd
            )],
            verbose => [ qw(
                source number name menu cmd param
                button path iconic key shortcuts
            )],
        },
        default => {
            default => [ qw(
                source number name shortcuts menu cmd
            )],
            verbose => [ qw(
                source number name menu cmd param
                button path iconic key shortcuts
            )],
        },
        Button => {
            default => [ qw(
                number menu cmd
            )],
            verbose => [ qw(
                number menu cmd param
                button path iconic key
            )],
        },
    );
    my $type = $opts{all} ? 'all' :$results->[0]{source};
    my $fields = $opts{verbose} ?
        $format{$type}{verbose} // $format{default}{verbose} :
        $format{$type}{default} // $format{default}{default};
    unshift @$fields, "result" if defined $opts{find};

    my $c = @$fields - 1;
    my $fstr = "%s". ("$opts{delimiter}%s" x $c). "\n";

    printf $fstr, map { uc } @$fields;
    foreach my $cmd (@$results) {
        printf $fstr, map { $cmd->{$_} // "" } @$fields;
    }
}

sub Details {
    return if $opts{quiet};
    my $cmd = shift;
    print "Source: $cmd->{source}\n";
    print "Number: $cmd->{number}\n";
    print "Name: $cmd->{name}\n" if $cmd->{name};
    print "Description: $cmd->{menu}\n" if defined $cmd->{menu};
    print "Command: $cmd->{cmd}\n" if defined $cmd->{cmd};
    print "Parameters: $cmd->{param}\n" if defined $cmd->{param};
    print "Icon: $cmd->{button}\n" if defined $cmd->{button};
    print "Start path: $cmd->{path}\n" if defined $cmd->{path};
    print $cmd->{iconic} == 1 ? "Run minimized\n" : "Run maximized\n" if defined $cmd->{iconic};
    print "Shortcut key (command config): $cmd->{key}\n" if defined $cmd->{key};
    print "Shortcuts: $cmd->{shortcuts}\n" if defined $cmd->{shortcuts};
}

sub Execute {
    my $cmd = shift;

    # send internal command
    if ($cmd->{source} eq 'TotalCmdInc') {
        exec $opts{sendCommand}, $cmd->{name};
    }

    unless (defined $cmd->{cmd} && $cmd->{cmd} ne '') {
        warn "Item has no command";
        return;
    }

    info "Executing \"%s\" ...", $cmd->{menu};
    verbose "%s %s", $cmd->{cmd}, $cmd->{param}//"";

    # selections from arguments
    my (@sourceSelection, @targetSelection);
    for (my $i=0; $i<@ARGV; $i++) {
        if ($ARGV[$i] eq ',') {
            @sourceSelection = @ARGV[0..$i-1];
            @targetSelection = @ARGV[$i+1..@ARGV-1];
            last;
        }
    }
    @sourceSelection = @ARGV unless @sourceSelection;
    debug "Source selection: @sourceSelection";
    debug "Target selection: @targetSelection";

    delete $cmd->{shortcuts}; #XXX

    # bless if not already blessed
    $cmd = new RJK::TotalCmd::Command(%$cmd) if ref $cmd eq 'HASH';

    try {
        $cmd->execute(
            {
                source => $opts{source},
                target => $opts{target},
                sourceSelection => \@sourceSelection,
                targetSelection => \@targetSelection,
            },
            sub {
                my $args = shift;
                my $confirm = $args =~ s/^\?//;
                verbose "%s %s", $cmd->cmd, $args;
                unless (defined $opts{show}) {
                    system "$cmd->{cmd} $args";
                }
            }
        );
    } catch {
        if ( $_->isa('RJK::TotalCmd::Command::UnsupportedParameterException') ) {
            error "Unsupported parameter: %s", $_->parameter();
        } elsif ( $_->isa('RJK::TotalCmd::Command::ListFileException') ) {
            warn "%s: %s", $_->error, $_->path();
        } elsif ( $_->isa('RJK::TotalCmd::Command::NoFileException') ) {
            warn "%s: %s", $_->error, $_->path();
        } elsif ( $_->isa('RJK::TotalCmd::Command::NoShortNameException') ) {
            warn "%s: %s", $_->error, $_->path();
        } elsif ( $_->isa('RJK::TotalCmd::Command::Exception') ) {
            error $_->error(). ".";
        } elsif ( $_->isa('Exception') ) {
            $_->rethrow;
        } else {
            die $_;
        }
    };
}

sub DisplayShortcutKeys {
    my @commands;
    my $shortcuts = $tcmd->getShortcuts()
        or die "Section not found";

    while (my ($cmdKeys, $cmdName) = each %$shortcuts) {
        my $cmd = $tcmd->getCommand($cmdName);
        $cmd->{shortcuts} = $cmdKeys;

        # determine modifier keys
        ($cmd->{modif}, $cmd->{key}) = $cmdKeys =~ /(\w+\+)?(.+)/;
        $cmd->{modif} ||= "";

        push @commands, $cmd;
    }

    my @header = (qw(Combination Description Command Parameters), "Start Path");
    print join($opts{delimiter}, @header), "\n";

    foreach my $cmd (sort {
        $a->{key} cmp $b->{key} ||
        $a->{modif} cmp $b->{modif}
    } @commands) {
        my @fields = qw(shortcuts menu cmd param path);
        $cmd->{cmd} //= $cmd->{name};
        print join($opts{delimiter},
            map { $cmd->{$_} // "" } @fields), "\n";
    }
}
