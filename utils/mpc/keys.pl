use strict;
use warnings;

use RJK::Media::MPC::Settings;
use RJK::Options::Pod;
use RJK::Win32::VirtualKeys;


###############################################################################
=head1 DESCRIPTION

Media Player Classic command keys.

=head1 SYNOPSIS

keys.pl [options]

=head1 DISPLAY EXTENDED HELP

keys.pl -h

=head1 OPTIONS

=for options start

=over 4

=item B<-u --user>

List commands with user defined keys.
If used in combination with C<-d>, indicates default key between
brackets if there is no user defined key, and an exclamation mark
is prefixed if the default command was cleared by the user.

=item B<-d --default>

List commands with default keys.
If used in combination with C<-u>, indicates default key between
brackets if there is no user defined key, and an exclamation mark
is prefixed if the default command was cleared by the user.

=item B<-a --all>

List all commands.
Indicates default key between brackets if there is no user defined
key, and an exclamation mark is prefixed if the default command was
cleared by the user.

=item B<--set>

Set keys, reads tab separated values from =STDIN=.
First reads a header, must contain columns =ID= and =KEY=.
Removes existing user key definitions not present in input.

=item B<--update>

Set keys, reads tab separated values from =STDIN=.
First reads a header, must contain columns =ID= and =KEY=.
Leaves existing user key definitions not present in input.

=item B<--stats>

Show stats.

=item B<-i --mpchc-ini [path]>

Path to F<mpc-hc.ini>.

=item B<--app-settings-cpp [path]>

Path to F<AppSettings.cpp>.

=item B<--resource-h [path]>

Path to F<resource.h>.

=item B<--mpchc-rc [path]>

Path to F<mpc-hc.rc>.

=item B<--virtkey-descr [path]>

Path to F<.tsv> file containing virtual key descriptions.

=item B<-v --verbose>

Be verbose.

=item B<-q --quiet>

Be quiet.

=item B<--debug>

Display debug information.

=back

=head2 Pod

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

=item B<-h --help -?>

Display extended help.

=back

=for options end

=cut
###############################################################################

my %opts = (
    appSettingsCpp => 'AppSettings.cpp',
    resourceHeader => 'resource.h',
    mpchcRc => 'mpc-hc.rc',
);
RJK::Options::Pod::GetOptions(
    'u|user' => \$opts{user},
        "List commands with user defined keys.\n".
        "If used in combination with C<-d>, indicates default key between\n".
        "brackets if there is no user defined key, and an exclamation mark\n".
        "is prefixed if the default command was cleared by the user.",
    'd|default' => \$opts{default},
        "List commands with default keys.\n".
        "If used in combination with C<-u>, indicates default key between\n".
        "brackets if there is no user defined key, and an exclamation mark\n".
        "is prefixed if the default command was cleared by the user.",
    'a|all' => \$opts{all},
        "List all commands.\n".
        "Indicates default key between brackets if there is no user defined\n".
        "key, and an exclamation mark is prefixed if the default command was\n".
        "cleared by the user.",
    'set' => \$opts{set},
        "Set keys, reads tab separated values from =STDIN=.\n".
        "First reads a header, must contain columns =ID= and =KEY=.\n".
        "Removes existing user key definitions not present in input.",
    'update' => \$opts{update},
        "Set keys, reads tab separated values from =STDIN=.\n".
        "First reads a header, must contain columns =ID= and =KEY=.\n".
        "Leaves existing user key definitions not present in input.",
    'stats' => \$opts{stats},
        "Show stats.",

    'i|mpchc-ini=s' => \$opts{mpcini},
        "{Path} to F<mpc-hc.ini>.",
    'app-settings-cpp=s' => \$opts{appSettingsCpp},
        "{Path} to F<AppSettings.cpp>.",
    'resource-h=s' => \$opts{resourceHeader},
        "{Path} to F<resource.h>.",
    'mpchc-rc=s' => \$opts{mpchcRc},
        "{Path} to F<mpc-hc.rc>.",

    'v|verbose' => \$opts{verbose}, "Be verbose.",
    'q|quiet' => \$opts{quiet}, "Be quiet.",
    'debug' => \$opts{debug}, "Display debug information.",

    ['Pod'],
    RJK::Options::Pod::Options,

    ['Help'],
    RJK::Options::Pod::HelpOptions
);

$opts{user} ||
$opts{default} ||
$opts{all} ||
$opts{set} ||
$opts{update} || RJK::Options::Pod::pod2usage(
    -sections => "DESCRIPTION|SYNOPSIS|DISPLAY EXTENDED HELP",
);

# quiet!
$opts{verbose} = 0 if $opts{quiet};

###############################################################################

my $mpc = new RJK::Media::MPC::Settings(
    mpcini => $opts{mpcini},
    appSettingsCpp => $opts{appSettingsCpp},
    resourceHeader => $opts{resourceHeader},
    mpchcRc => $opts{mpchcRc},
);
my %shortcuts = $mpc->shortcuts();
my %descriptions = $mpc->commandDescriptions();
my %constants = $mpc->commandConstants();

my $vkeys = new RJK::Win32::VirtualKeys();
my $keycodes = $vkeys->getKeyCodes();
my $vkeynames = $vkeys->getVirtualKeyNames();

my (%descr, %virtualKeyCodes, %virtualKeyNames);

#~  mpcKeyStateToChar
my %flagsShort = (
    FCONTROL => 'C',
    FALT => 'A',
    FSHIFT => 'S',
    FNOINVERT => 'N',
    FVIRTKEY => 'V',
);

#~ charToMpcKeyState
my %modifierFlags = (
    N => 0,
    V => 1,
    #~ N => 1<<1,
    S => 1<<2,
    C => 1<<3,
    A => 1<<4,
);

my %mouseButtons = (0 => '');
my @mouseButtons = ('');
my $i = 1;
foreach my $b (qw(Left Middle Right X1 X2 Wheel)) {
    foreach ($b eq 'Wheel' ? qw(Up Down) : qw(Down Up DblClk)) {
        $mouseButtons{"$b $_"} = $i;
        $mouseButtons[$i++] = "$b $_";
    }
}

###############################################################################

my @shortcuts = values %shortcuts;

if ($opts{set} || $opts{update}) {
    Set();
} elsif ($opts{stats}) {
    #~ printf "%s user defined keys\n", scalar keys %mods;
    printf "%s shortcuts\n", scalar @shortcuts;
    printf "%s command descriptions\n", scalar keys %descriptions;
    printf "%s virtual keys\n", scalar keys %$vkeynames;
    printf "\nIni file: %s\n", $mpc->getMpcIni->file;
} else {
    List();
}

###############################################################################

sub List {
    if ($opts{verbose}) {
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
            qw(ID KEY DEFAULT FLAGS
               MOUSE_WINDOWED MOUSE_FULLSCREEN NAME DESCRIPTION);
    } else {
        printf "%s\t%s\t%s\t%s\t%s\n",
            qw(ID KEY MOUSE_WINDOWED MOUSE_FULLSCREEN DESCRIPTION);
    }

    %descriptions = MPC::GetDescriptions($opts{mpchcRc});
    #~ %virtualKeys = MPC::GetVirtualKeys($opts{virtkeyDescr});
    %virtualKeyNames = MPC::GetVirtualKeyNames($opts{virtkeyDescr});

    foreach (@shortcuts) {
        DisplayCommand($_);
    }
}

sub DisplayCommand {
    my $cmd = shift;

    my @flags = map { $flagsShort{$_} } @{$cmd->{flags}};
    my $f1 = join "", grep { /[CAS]/ } @flags;
    my $f2 = join "", grep { ! /[CAS]/ } @flags;

    # default key
    my $defaultKey;
    if ($opts{default}) {
        $defaultKey = $cmd->{key} // "";
        if ($defaultKey && $defaultKey =~ s/^VK_//) {
            unless ($defaultKey = $virtualKeyNames{"VK_$defaultKey"}) {
                print "Unrecognized key name: $defaultKey\n";
            }
        }
        $defaultKey = $f1 && $defaultKey ? "$f1+$defaultKey" : $defaultKey;
    }

    my $id = $cmd->{id};
    my $name = $cmd->{name};

    # user defined keys
    #~ my $user = $mods{$id} // {};
    my $mouseWind = $user->{mouseWindowed} // 0;
    my $mouseFull = $user->{mouseFullscreen} // 0;

    my $key = getKeyDescription($user);
    my $keyCode = $user->{key};

    return unless $opts{all}
        || $opts{user} && defined $keyCode
        || $defaultKey;

    if ($opts{verbose}) {
        if ($defaultKey && ! defined $keyCode) {
            $key = $defaultKey;
        }
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
            $id, $key, $defaultKey, $f2,
            $mouseButtons[$mouseWind],
            $mouseButtons[$mouseFull],
            $name, $descriptions{$name};
    } else {
        if ($opts{default} && ! $opts{user}) {
            # show default keys only
            $key = $defaultKey;
        } elsif ($defaultKey) {
            if (defined $keyCode) {
                # cleared default key
                $key = "!($defaultKey)" if $keyCode eq '0';
            } else {
                $key = "($defaultKey)";
            }
        }
        printf "%s\t%s\t%s\t%s\t%s\n",
            $id, $key,
            $mouseButtons[$mouseWind],
            $mouseButtons[$mouseFull],
            $descriptions{$name};
    }
}

sub getKeyDescription {
    my ($mod) = @_;
    my ($keyCode, $modifCode) = ($mod->{key}, $mod->{modif});
    $keyCode || return "";

    my $oct = oct "0x$modifCode";
    my $modifName = "";
    $modifName .= $oct & $modifierFlags{$_} && $_ || ""
        for qw(C A S);

    my $keyName;
    if (my $code = $virtualKeys{ sprintf "%02s", uc $keyCode }) {
        $keyName = $code->[2];
    } else {
        $oct = oct "0x$keyCode";
        # ascii printable chars: 0x20 (space) - 0x7E
        $keyName = $oct > 0x20 && $oct <= 0x7E ? keyName $oct : "($keyCode)";
    }
    return $modifName ? "$modifName+$keyName" : $keyName;
}

sub Set {
    my @values;

    # get header
    while (<>) {
        chomp;
        @values = split /\t/;
        last;
    }
    @values || die "No input";

    my @cols = qw(
        ID KEY REMOTE_CMD APP_CMD
        MOUSE_WINDOWED REP_CNT MOUSE_FULLSCREEN
    );
    # get column indices
    my %cols;
    for (my $i=0; $i<@values; $i++) {
        foreach (@cols) {
            $cols{$_} = $i if $values[$i] eq $_;
        }
    }

    $cols{ID} // die "Column ID must be present";
    $cols{KEY} // die "Column KEY must be present";

    my %virtualKeyCodes = MPC::GetVirtualKeyCodes($opts{virtkeyDescr});

    # process values
    my %cmds;
    while (<>) {
        chomp;
        my @values = split /\t/;
        my %values;
        foreach (@cols) {
            $values{$_} = $values[ $cols{$_} ] if defined $cols{$_};
        }

        # remove indicators
        $values{KEY} =~ s/^!.*//;
        $values{KEY} =~ s/^\((.*)\)$/$1/;

        # determine modifier keys
        my ($modKeys, $keyName) = $values{KEY} =~ /(\w+\+)?(.+)/;
        my $modif = 1;
        if ($modKeys) {
            $modif |= $modKeys =~ /$_/ && $modifierFlags{$_}
                for qw(C A S);
        }

        my $code = $keyName eq "" ? 0 : $virtualKeyCodes{$keyName};
        if (defined $code) {
            $code =~ s/^0+//;
            $cmds{ $values{ID} } = {
                modif     => sprintf("%x", $modif),
                key       => lc $code || 0,
                remoteCmd => $values{REMOTE_CMD}       // "",
                repCnt    => $values{REP_CNT}          // 5,
                mouseWind => $values{MOUSE_WINDOWED}   // 0,
                appCmd    => $values{APP_CMD}          // 0,
                mouseFull => $values{MOUSE_FULLSCREEN} // 0,
            };
        } else {
            print "Unrecognized key name: $keyName\n";
        }
    }

    my @fields = qw(
        modif key remoteCmd
        repCnt mouseWind appCommand mouseFull
    );

    my @cmds;

    foreach my $cmd (@shortcuts) {
        my $id = $cmd->{id};
        #~ my $user = $mods{$id};

        my $input;
        if ($input = delete $cmds{$id}) {
            $input->{$_} = $input->{$_} && $mouseButtons{ $input->{$_} } || 0
                for qw(mouseWind mouseFull);
            $input->{$_} //= $user->{$_}
                for @fields;
        } elsif ($user && $opts{update}) {
            $input = $user;
        } else {
            printf "%s removed\n", getKeyDescription($user);
            next;
        }

        # skip if equal to default
        my $key = $cmd->{key};
        if (defined $key) {
            if (my $keyCode = $virtualKeyCodes{$key}) {
                $keyCode =~ s/^0+//;
                my $modifCode = getModifCode($cmd->{flags});

                my $equal =
                    $input->{key} eq $keyCode &&
                    $input->{modif} eq sprintf("%x", $modifCode) &&
                    ! $input->{remoteCmd} &&
                    ! $input->{mouseWind} &&
                    ! $input->{appCommand} &&
                    ! $input->{mouseFull};
                next if $equal;
            }
        }

        push @cmds, sprintf '%d %s %s "%s" %d %d %d %d',
            $id, map { $input->{$_} // 0 } @fields;
        print "$cmds[@cmds-1]\n";
    }

    foreach (keys %cmds) {
        print "Unknown id: $_\n";
    }

    #~ MPC::SetCommandMods($opts{mpchcIni}, \@cmds);
}

sub getModifCode {
    my $flags = shift;
    my $modif = 0;
    $modif |= $modifierFlags{ $flagsShort{$_} } for @$flags;
    return $modif;
}
