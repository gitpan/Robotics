package Robotics;

use warnings;
use strict;

use Carp;
use Moose;
use MooseX::StrictConstructor;

#use Module::Pluggable::Object;  # maybe in future
use IO::Socket;
use YAML::XS;

our @Devices = (
    "Robotics::Tecan"
);

has 'alias' => ( is => 'rw' );

has 'device' => ( is => 'rw' );

has 'devices' => ( 
    traits    => ['Hash'],
    is => 'rw', 
    isa       => 'HashRef[Str]',
    default   => sub { {} },
    );  

=head1 NAME

Robotics - Robotics hardware control and abstraction

=head1 VERSION

Version 0.22

=cut

our $VERSION = '0.22';

# Application should always perform device probing as first thing,
# so this is done as 'new'
sub BUILD {
    my ($self, $params) = @_;
    
    if ($self->device()) { 
        print STDOUT "Setting up ". $self->device(). "\n";
    }
    else { 
        $self->probe();
    }
}

sub probe { 
    my ($self, $params) = @_;
	print STDOUT "Searching for locally connected robotics devices\n";
	
	# Find Tecan Gemini, EVO, Genesis, ...

    my $this = shift;
    my %device_tree;
    $self->devices( \%device_tree );
    for my $class ( @Robotics::Devices ) {
        warn "Loading $class\n";
        if ( _try_load($class) ) {
            my $result = $class->probe();
            if (defined($result)) { 
                $self->devices->{$class} = $result;
                #$list{$class} = $result;
            }
        }
        else {
            die "should not get here; could not load ".
                "Robotics::Device subclass $class\n\n\n$@";
        }
    }

	# Add other robotics systems here
}

sub printDevices {
    my ($self, $params) = @_;
    my $yamlstring;
    if ($self->devices() ) { 
        $yamlstring = "\n".YAML::XS::Dump( $self->devices() );
    }
    return $yamlstring;   
}

sub findDevice { 
    my ($self, %params) = @_;
    my $root;
    my $want = $params{"product"} || return "";
    $root = $params{root};
    if (!$root) { 
        $root = $self->devices();
    }
    for my $key (keys %{$root}) {
        if ($key =~ /$want/) { 
            return $root->{$key};
        }
        else {
            my $val; 
            eval {
                if (keys %{$root->{$key}}) { 
                    $val = $self->findDevice(
                        root => $root->{$key},
                        %params);
                    if (defined($val)) { 
                        return $val;
                    }
                } 
            };
            if ($val) { 
                return $val;
            }
        }
    }
    return undef;
}

=secret 
# see example from File::ChangeNotify
my $finder =
    Module::Pluggable::Object->new( search_path => 'Robotics::Device' );

=cut

sub _try_load
{
    my $class = shift;

    eval { Class::MOP::load_class($class) };

    my $e = $@;
    die $e if $e && $e !~ /Can\'t locate/;

    return $e ? 0 : 1;
}

sub configure {
    # XXX TODO

}


=head1 SYNOPSIS

Provides local communication to robotics hardware devices, related
peripherals, or network communication to these devices.  Also
provides a high-level, object oriented software interface to
abstract the low level robotics commands or low level robotics
hardware.  Environmental configuration is provided with a
configuration file in YAML format.  Allows other hardware device
drivers to be plugged into this module.

Simple examples are provided in the examples/ directory of the
distribution.

This main Robotics.pm module is an abstraction layer for many types
of robotics devices and related peripheral hardware.  Other
hardware, motor controllers, CNC, or peripheral devices may exist
below this module, or under Devices::, or under other libraries, and
new implementation is welcomed.

Nominclature note:  The name "Robotics" is used in full, rather than
"Robot", to distinguish mechanical robots from the many
internet-spidering software modules or software user agents commonly
(and erroneously) referred to as "robots".  Robotics has motors;
both the internet & software do not!

Technical details: 
This & related modules use YAML to allow users (and the module
itself) to use configuration data in a readable way.  The
configuration data contains:  physical locations of objects to
interact with, physical points in space to navigate from/to,
dictionary definitions, equipment lists, and so on, as well as the
tokens for the low-level robotics commands.

To use this software with locally-connected robotics hardware:

=item Use the module(s)

=item Use the query method to probe for connected hardware or
(in the future) remote robotics hardware servers via the network

=item Create a 'new' robotics object from the desired hardware

=item Use the robotics object to 'Attach' to the robotics hardware
for communications

=item Use the robotics object to control the physical hardware,
perhaps using very high level semantics which translate into
multiple lower-level robotics commands.

Example (Please see currently working examples in the distribution):

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
    $tecan->park("roma0");      # move robotics arm to 'home' position
    $tecan->move("roma0", "platestack", "s");    # move robotics named arm to vector start
    $tecan->grip("roma0");    # grip the plate with the named arm
    $tecan->move("roma0", "platestack", "e");    # move robotics named arm to vector end
    # TBD $tecan->fetch_tips($tip, $tip_rack);   # move liquid handling arm to get tips
    # TBD $tecan->liquid_move($aspiratevol, $dispensevol, $from, $to);
    ...

To use this software with remote robotics hardware over the network:

  # On the local machine, run:
    use Robotics;
    use Robotics::Tecan;

	my %hardware = Robotics::query();
    my $tecan = Robotics->new("Tecan") || die "no tecan found\n";
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
Robotics modules must all provide a mechanism for finding attached
hardware and return the key-value.  Communication must not allowed
to any hardware device unless queried (probed) for status first.
This mechanism eliminates operating system issues (hanging device
drivers, etc) when the hardware does not exist or is not ready for
communication.

=cut



=head2 configure

Loads configuration data into memory.  

=item pathname of configuration file in YAML format

Returns:
0 if success, 
1 if file error,
2 if configuration error.

=cut


=head1 IMPLEMENTATION NOTES


Many of these robotics devices are designed 
primarily or exclusively for MSWin systems.  This means module
requirements and internal code must be activeperl and MSWin friendly.
This author suggests discussing with the manufacturer(s)
requesting more Unix/OSX/POSIX compatibility when appropriate.



=head1 AUTHOR

Jonathan Cline, C<< <jcline at ieee.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-robotics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Robotics>.  I will be notified, and then you'll
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

no Moose;

__PACKAGE__->meta->make_immutable;

1; # End of Robotics

__END__

