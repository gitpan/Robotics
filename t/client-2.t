#!perl -T
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
use Test::More tests => 7;


BEGIN {
    use_ok( 'Robotics' );
    use_ok( 'Robotics::Tecan' );
}

diag( "Testing Robotics $Robotics::VERSION, Perl $], $^X" );

$hw = Robotics::Tecan->new(
    'server' => 'heavybio.dyndns.org:8088',
    'password' => $ENV{"TECANPASSWORD"});

if ($hw) { 
    pass("connect");
}
else {
    fail("connect");
}

if ($hw) {
    is($hw->attach(), "0;Version 4.1.0.0", "attach");
    is($hw->status(), "0;IDLE", "status1");
    is($hw->status(), "0;IDLE", "status2");
    is($hw->status(), "0;IDLE", "status3");
    is($hw->initialize(), "0", "init");
    is($hw->status(), "0;IDLE", "status4");
    is($hw->park("roma0"), "0", "park");
    is($hw->status(), "0;IDLE", "status5");
    $hw->move("roma0", "JC-TrayPickup", "e");
    $hw->move("roma0", "JC-TrayPickup", "s");
    is($hw->status(), "0;IDLE", "status6");
    is($hw->park("roma0"), "0", "park");
    is($hw->status(), "0;IDLE", "status7");
}


1;
