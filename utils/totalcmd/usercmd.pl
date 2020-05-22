use strict;
use warnings;

use RJK::TotalCmd::Settings;

my $tc = new RJK::TotalCmd::Settings;

my %keys = $tc->getKeys;

my $uc = $tc->getUserCommands;
my @no = grep { ! exists $keys{$_->{name}} } @{$uc->getCommands};
if (@no) {
    print "User commands without shortcuts:\n";
    print join "\n", map { $_->{name} } @no;
    print "\n";
} else {
    print "No user commands without shortcuts\n";
}

my $menu = $tc->getStartMenu;
my %names;
map { $names{$_->{cmd}} = 1 if $_->isUser() } @{$menu->getCommands};
if (%names) {
    print "User commands in start menu:\n";
    print join "\n", keys %names;
    print "\n";
} else {
    print "No user commands in start menu\n";
}

$menu = $tc->getDirMenu;
%names = ();
map { $names{$_->{cmd}} = 1 if $_->isUser } @{$menu->getCommands};
if (%names) {
    print "User commands in directory menu:\n";
    print join "\n", keys %names;
    print "\n";
} else {
    print "No user commands in directory menu\n";
}

my $bars = $tc->getButtonBars;
foreach my $bar (@$bars) {
    my $bb = $tc->getButtonBar($bar);

    %names = ();
    map { $names{$_->{cmd}} = 1 if $_->isUser } @{$bb->getButtons};
    if (%names) {
        print "User commands in $bb->{name}.bar:\n";
        print join "\n", keys %names;
        print "\n";
    } else {
        print "No user commands in $bb->{name}.bar\n";
    }
}
