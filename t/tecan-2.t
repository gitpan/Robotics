#!perl -T
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
use Test::More tests => 6;

BEGIN {
    use_ok( 'Robotics' );
    use_ok( 'Robotics::Tecan' );
}

diag( "Testing Robotics $Robotics::VERSION, Perl $], $^X" );

# Query before simulator start -> expect fail only if no h/w connected
my @connected_hardware = Robotics->query();
if (!@connected_hardware) {
    fail("find hardware");
}

if (! -d '/cygdrive/c' && ! -d '/Program Files') {
    # Only continue to test if we are on Win32 and hardware
    # is attached
    warn "# Skipping real hardware test since no Win32 found\n";
    exit(0);
}
 
diag( "Found: @connected_hardware");
pass("find hardware");

my $hw;
$hw = Robotics::Tecan->new();
if ($hw) { 
    pass("new");
}
else {
    fail("new");
}

is($hw->attach(), "0;Version 4.1.0.0", "attach");
is($hw->status(), "0;IDLE", "status");

1;
