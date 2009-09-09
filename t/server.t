#!perl -T
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
use Test::More tests => 6;


BEGIN {
    use_ok( 'Robotics' );
    use_ok( 'Robotics::Tecan' );
}

diag( "Testing Robotics $Robotics::VERSION, Perl $], $^X" );

if (!$ENV{'TECANPASSWORD'}) { 
    diag( "Must set env var TECANPASSWORD for server password" );
    exit -5;
}
# Query before start
my %connected_hardware = Robotics->query();
diag( "\nFound: ". join(" ", keys %connected_hardware));
if ($connected_hardware{"Tecan-Gemini"}) {
    pass("find tecan");
}
else {
    fail("find tecan");
}

if ((! -d '/cygdrive/c') && (! -d '/Program Files')) { 
    # Only continue to test if we are on Win32 and hardware
    # is connected
    diag "Skipping real hardware test since no Win32 found\n";
    exit(-1);
}
 
if ($connected_hardware{"Tecan-Gemini"} eq "not started") {
    # Found but gemini not started, complain
    diag "Skipping real hardware test since GEMINI not started\n";
    diag "(Experimental) Try to use Robotics::Tecan->startService() (see docs)\n";
    exit(-2);
    Robotics::Tecan->startService();
}

# Call query() again in case gemini now started
%connected_hardware = Robotics->query();
diag( "\nFound: ". join(" ", keys %connected_hardware));
if ($connected_hardware{"Tecan-Gemini"} ne "ok") {
    # Only continue if hardware is running
    diag "Skipping real hardware test since no ROBOTICS HARDWARE found\n";
    exit(-3);
}

my $hw;
$hw = Robotics::Tecan->new();
if ($hw) { 
    pass("new");
}
else {
    fail("new");
}

if ($hw) {
    is($result = $hw->attach(), "0;Version 4.1.0.0", "attach");
    if (!$result) { 
        diag "Skipping real hardware test since cant attach\n";
        exit(-3);
    }
    is($result = $hw->status(), "0;IDLE", "status");
    is($hw->server($ENV{'TECANPASSWORD'}), 1, "server");
}


1;
