#!perl -T
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
use Test::More tests => 6;

BEGIN {
    use_ok( 'Robotics' );
    use_ok( 'Robotics::Tecan' );
    Robotics::Tecan->simulate_enable();  # Turn on simulation ability
}

diag( "Testing Robotics $Robotics::VERSION, Perl $], $^X" );

# Query before simulator start -> expect fail only if no h/w connected
my @connected_hardware = Robotics->query();
if (@connected_hardware) {
    warn "# Found hardware, is it connected? if not this test fails\n";
}

if (-d '/cygdrive/c' && @connected_hardware) {
    # Do not continue to test simulator if we are on Win32 and hardware
    # is attached
    warn "# Skipping simulation test since hardware is found\n";
    exit(0);
}
# Start simulator before running any methods
push(@INC, "t");
require "sim-tecan.pl";
 
@connected_hardware = Robotics->query();
isnt(@connected_hardware, (), "didnt find any hardware");
diag( "Found: @connected_hardware");
pass("hardware check");

Robotics::Tecan->attach();

# Stop Simulator
diag( "Simulator attempting stop.");
SimulateTecan::Shutdown();
Robotics::Tecan->status();
diag( "Simulator stopped.");

