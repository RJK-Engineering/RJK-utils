package Filecheck;

use strict;
use warnings;

use RJK::Util::Properties;

my $config;

sub getConfigProp {
    my ($class, $prop) = @_;
    $class->loadConfig() if ! $config;
    return $config->get($prop);
}

sub loadConfig {
    $config = new RJK::Util::Properties();
    if ($ENV{FILECHECK_CONF_FILE}) {
        $config->load($ENV{FILECHECK_CONF_FILE});
    } else {
        $config->load("$ENV{LOCALAPPDATA}/filecheck.properties");
    }
}

1;