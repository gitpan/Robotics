#!/usr/bin/perl
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
#
# jcline@ieee.org 2009-06-26
#
#
# Test Tecan Gemini using named pipe & control 

use Test::More tests => 2;

if (!($ENV{"PATH"} =~ m^/cygdrive/c^)) {
    warn "this test is only for cygwin-perl\n";
    exit -1;
}

warn "this test for cygwin-perl always fails; no workaround found\n";

# Notes on gemini named pipe:
#   - must run gemini application first
$pipename="\\\\.\\pipe\\gemini";
my $version;
my $status;
use Fcntl;
$| = 1;
sysopen(CMD, $pipename, O_RDWR) || die "\n!! FAIL - cant open $pipename\n";
binmode(CMD);
print "\nversion: ";
print CMD "GET_VERSION\0";
do { read(CMD, $_, 1); $version .= $_; } while ($_ ne "\0");
$version =~ s/[\t\n\r\0]//g;
print "$version\n";
if ($version) { pass("version"); } else { fail("version"); }

print "status: ";
print CMD "GET_STATUS\0";
do { read(CMD, $_, 1); $status .= $_; } while ($_ ne "\0");
$status =~ s/[\t\n\r\0]//g;
print "$status\n";
if ($status) { pass("status"); } else { fail("status"); }

close(CMD);
if (!$version || !$status) {
    diag("TEST FAIL");
}
__DATA__
__END__
