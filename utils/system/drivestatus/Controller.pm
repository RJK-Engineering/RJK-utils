package Controller;

use strict;
use warnings;

my $console;
my $actions;

sub new {
    my $self = bless {}, shift;
    ($console, $actions) = @_;
    return $self;
}

sub userInput {
    while ($console->getEvents) {
        my @event = $console->input();
        next if !@event or $event[0] != 1 or !$event[1];
        if ($event[5]) {                    # ASCII
            if ($event[5] == 9) {           # Tab
                $actions->preventSleep();
            } elsif ($event[5] == 27) {     # Esc
                $actions->quit();
            } else {
                my $key = chr $event[5];
                if ($actions->can($key)) {  # action key
                    $actions->do($key);
                } else {                    # drive letter
                    $actions->do('toggle', [uc $key]);
                }
            }
        } elsif ($event[3] == 112) {        # F1
            $actions->help();
        }
    }
    $console->flush();  # empty buffer
}

1;
