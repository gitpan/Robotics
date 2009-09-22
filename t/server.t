#!perl -T
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
use Test::More tests => 7;


BEGIN {
    use_ok( 'Robotics' );
    use_ok( 'Robotics::Tecan' );
}

diag( "Testing Robotics $Robotics::VERSION, Perl $], $^X" );

if ((! -d '/cygdrive/c') && (! -d '/Program Files')) { 
    # Only continue to test if we are on Win32 and hardware
    # is connected
    plan skip_all => "No Win32 found, cant test hardware";
    exit(-1);
}

if (!$ENV{'TECANPASSWORD'}) { 
    plan skip_all => "Must set environ var TECANPASSWORD for server password";
}

my $obj = Robotics->new();
print "Hardware: ". $obj->printDevices();
my $gemini;
my $hw;
if ($gemini = $obj->findDevice(product => "Gemini")) { 
    print "Found local Gemini $gemini\n";
    pass("find tecan");
    my $genesis = $obj->findDevice(product => "Genesis");
    pass("find genesis");
}
else {
    print "No Gemini found\n";
    fail("find tecan");
    fail("find genesis");
    plan skip_all => "No locally-connected hardware found, cant test";
}

 
if (0) {
    # Found but gemini not started, complain
    diag "Skipping real hardware test since GEMINI not started\n";
    diag "(Experimental) Try to use Robotics::Tecan->startService() (see docs)\n";
    Robotics::Tecan->startService();

    # Call Robotics->new() again in case gemini now started
}

$hw = Robotics::Tecan->new(
    connection => $gemini);
if ($hw) { 
    pass("new");
}
else {
    plan skip_all => "cant connect to tecan hardware";
}

if ($hw) {
    is($result = $hw->attach(), "0;Version 4.1.0.0", "attach");
    if (!$result) { 
        plan skip_all => "Skipping real hardware test since cant attach";
    }
    is($result = $hw->status(), "0;IDLE", "status");
    is($hw->server(password => $ENV{'TECANPASSWORD'}), 1, "server");
}


1;

