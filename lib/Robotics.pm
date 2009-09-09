package Robotics;

# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:

use warnings;
use strict;

use IO::Socket;
use YAML::XS;


# Implementation note:  Many of these robotics devices are designed 
# primarily, or exclusively, for MSWin systems.  This means module
# requirements and internal code must be activeperl and MSWin friendly.
# This author suggests registering an opinion with the manufacturer(s)
# requesting more Unix support.

=head1 NAME

Robotics - Simple software abstraction for physical robotics hardware!

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';


=head1 SYNOPSIS

Provides local communication to a robotics hardware device, related peripherals,
or network communication to the same.  Also provides a high-level software interface
to abstract the low level robotics commands or low level robotics hardware.   

Nominclature note:  The name "Robotics" is used in full, rather than "Robot",
to distinguish mechanical robots from the many internet-spidering software
modules or software user agents commonly (and erroneously) referred to as "robots".

Design note: This main Robotics.pm module is an abstraction layer for many types
of robotics devices and related peripheral hardware.  Other hardware, motor controllers,
CNC, or peripheral devices may exist below this module and new implementation
is welcomed.

To use this software with locally-connected robotics hardware:

    use Robotics;
    use Robotics::Tecan;

    my %hardware = Robotics::query();
    if ($hardware{"Tecan-Genesis"} eq "ok") { 
    	print "Found locally-connected Tecan Genesis robotics!\n";
    }
    elsif ($hardware{"Tecan-Genesis"} eq "busy") {
    	print "Found locally-connected Tecan Genesis robotics but it is busy moving!\n";
    	exit -2;
    }
    else {
    	print "No robotics hardware connected\n";
    	exit -3;
    }
    my $tecan = Robotics->new("Tecan") || die;
    $tecan->attach() || die;    # initiate communications 
    $tecan->configure("my-worktable.yaml");      # Load YAML configuration file (optional)
    $tecan->home("roma0");      # move robotics arm
    $tecan->move("roma0", "platestack", "e");    # move robotics arm to vector's end
    # TBD $tecan->fetch_tips($tip, $tip_rack);   # move liquid handling arm to get tips
    # TBD $tecan->liquid_move($aspiratevol, $dispensevol, $from, $to);
    ...

To use this software with remote robotics hardware over the network:

  # On the local machine, run:
    use Robotics;
    use Robotics::Tecan;

	my @connected_hardware = Robotics->query();
    my $tecan = Robotics->new("Tecan") || die "no tecan found in @connected_hardware\n";
    $tecan->attach() || die;
    # TBD $tecan->configure("my work table configuration file") || die;
    # Run the server and process commands
    while (1) {
      $error = $tecan->server(passwordplaintext => "0xd290"); # start the server
      # Internally runs communications between client->server->robotics
      if ($tecan->lastClientCommand() =~ /^shutdown/) { 
        last;   
      
    }
    $tecan->detach();   # stop server, end robotics communciations
    exit(0);

  # On the remote machine (the client), run:
    use Robotics;
    use Robotics::Tecan;

    my $server = "heavybio.dyndns.org:8080";
    my $password = "0xd290";
    my $tecan = Robotics->new("Tecan");
    $tecan->connect($server, $mypassword) || die;
    $tecan->home();
    $tecan->configure("my-worktable.yaml");      # Load YAML configuration file (optional)
     
    ... same as first example with communication automatically routing over network ...
    $tecan->detach();   # end communications
    exit(0);


=head1 EXPORT

No exported functions

=head1 FUNCTIONS

=head2 query

Query the local machine for connected hardware.

The user application must call this method to find hardware prior to 
attempting to access the hardware.

Developer design note: 
Robotics modules must all provide a mechanism for 
finding attached hardware and return the key-value.  Communication
must not allowed to any hardware device unless queried (probed) for 
status first.  This mechanism eliminates operating system issues
(hanging device drivers, etc) when the hardware does not exist or
is not ready for communication.

=cut

sub query {
	print STDOUT "Searching for locally connected robotics devices\n";


	my %found;
	
	# Find Tecan Gemini, EVO, etc
	%found = Robotics::Tecan::_find();

	# Add other robotics devices here

	return %found;
}

=head2 new

=cut

sub new {

	
}


=head2 configure

Loads configuration data into memory.  

=item pathname of configuration file in YAML format

Returns:
0 if success, 
1 if file error,
2 if configuration error.

=cut

sub configure {
    # XXX TODO

}

=head1 AUTHOR

Jonathan Cline, C<< <jcline at ieee.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-robotics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Robotics>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Robotics


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Robotics>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Robotics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Robotics>

=item * Search CPAN

L<http://search.cpan.org/dist/Robotics/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jonathan Cline.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Robotics

__END__

