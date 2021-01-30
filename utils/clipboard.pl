use strict;
use warnings;

use Win32::Clipboard;

my $clip = Win32::Clipboard();
local $/;
my $text = $clip->Set(<>);
