#!perl -T
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
use Test::More tests => 13;


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
    exit -2;
}

warn "
#
# WARNING!  ARMS WILL MOVE!
# 
";

print "ROBOT ARMS WILL MOVE!!  Is this okay?  (must type 'yes') [no]:";
$_ = <STDIN>;
if (!($_ =~ m/yes/i)) { 
    exit -4;
}

if ($hw) {
    is($hw->attach(), "0;Version 4.1.0.0", "attach");
    if (!is($hw->status(), "0;IDLE", "status1")) { 
        diag "Aborting test - hardware not IDLE";
        exit -5;
    }
    is($hw->status(), "0;IDLE", "status2");
    is($hw->status(), "0;IDLE", "status3");
    is($hw->initialize(), "0;IDLE", "init");
    is($hw->status(), "0;IDLE", "status4");
    is($hw->park("roma0"), "0", "park1");
    is($hw->status(), "0;IDLE", "status5");
    is($hw->park("roma0"), "0", "park2");
    is($hw->status(), "0;IDLE", "status7");
}


1;
