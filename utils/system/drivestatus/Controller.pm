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
        if (@event && $event[0] == 1 and $event[1]) {
            #~ $console->printLine("@event");
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
            } else {
                next;
            }
            last;
        }
    }
    $console->flush();  # empty buffer
}

1;
