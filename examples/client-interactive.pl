#!/usr/bin/perl
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:

use Robotics;
use Robotics::Tecan;

print "Testing Robotics $Robotics::VERSION, Perl $], $^X\n";

my $hw = Robotics::Tecan->new(
    'server' => 'heavybio.dyndns.org:8088',
    'password' => 'pcrisfunforme');

if (!$hw) { 
    die "fail to connect\n";
}

print $hw->attach();
print $hw->status();
print $hw->status();
print $hw->initialize();
print $hw->status();


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

print "Enter tecan commands!\n\n";
while ($_ = <STDIN>) {
    s/[\n\r\t]*//g;
    if (!$_) { last; }
    $hw->Write($_);
    print "\t".$hw->Read()."\n\n";
}

$hw->detach();

1;
