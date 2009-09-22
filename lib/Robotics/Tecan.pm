package Robotics::Tecan;

use warnings;
use strict;
use Moose; 
use Carp;

has 'connection' => ( is => 'rw' );
has 'serveraddr' => ( is => 'rw' );
has 'password' => ( is => 'rw' );
has 'port' => ( is => 'rw', isa => 'Int' );
has 'token' => ( is => 'rw');
has 'VERSION' => ( is => 'rw' );
has 'STATUS' => ( is => 'rw' );
has 'HWTYPE' => ( is => 'rw' );
has 'DATAPATH' => ( is => 'rw', isa => 'Maybe[Robotics::Tecan]' );
has 'COMPILER' => ( is => 'rw' );
has 'compile_package' => (is => 'rw', isa => 'Str' );

use Robotics::Tecan::Gemini;  # Software<->Software interface
use Robotics::Tecan::Genesis; # Software<->Hardware interface
use Robotics::Tecan::Client;
with 'Robotics::Tecan::Server';

# note for gemini device driver:
# to write a "dying gasp" to the filehandle prior to closure from die,
# implement DEMOLISH, which would be called if BUILD dies

my $Debug = 1;

=head1 NAME

Robotics::Tecan - Control Tecan robotics hardware as Robotics module

=head1 VERSION

Version 0.22

=cut

our $VERSION = '0.22';

=begin text

Data Flow block diagram:

 (Robotics object) -->  (Tecan object)  --future-work--> (other device object)
                          |                                           |
                          v                                           v
             (Genesis device object)  -----> Genesis::DATAPATH -> Tecan::Client
                          ^
                          +---------------<- Genesis::DATAPATH <- Tecan::Server
                          v
                  (Gemini object)   -----> named pipe  <->  hardware


=cut

sub BUILD {
    my ( $self, $params ) = @_;

    # Do only if called directly
    return unless $self->connection;
    
    my $connection = "local";
    
    my $server = $self->serveraddr;
    my $serverport;

    if ($server) { 
        my @host = split(":", $server);
        $server = shift @host;
        $serverport = shift @host || $self->port;
        $connection = "remote"; 
    }
    if ($self->connection) {
        $self->compile_package( (split(',', $self->connection))[1] );
        if ($connection eq "local") { 
            # Use Gemini
            warn "Opening Robotics::Tecan::Gemini->openPipe()\n" if $Debug;
            $self->DATAPATH(
                    Robotics::Tecan::Gemini->new(
                        object => $self)
                );
        }
        elsif ($connection eq "remote") { 
            # Use Robotics::Tecan socket protocol
            warn "Opening Robotics::Tecan::Client to $server:$serverport\n" if $Debug;
            $self->DATAPATH( 
                    Robotics::Tecan::Client->new(
                        object => $self,
                        server => $server, port => $serverport, 
                        password => $self->password)
                    );
        }
    
        $self->VERSION( undef );
        $self->HWTYPE( undef );
        $self->STATUS( undef );
        $self->password( undef );
    }
    else { 
       die "must give 'connection' for ".__PACKAGE__."->new()\n";
    }
}

=head2 probe
 
=cut
sub probe {
    my ($self, $params) = @_;
	my (%all, %found);

    # Find software interfaces then hardware interfaces
    %found = %{Robotics::Tecan::Gemini->probe()};
    %all = (%all, %found); 
    %found = %{Robotics::Tecan::Genesis->probe()};
    %all = (%all, %found); 
    
    return \%all;
}

=head2 attach

Start communication with the hardware.

Arguments are:

=item Robotics object: The variable returned from new().

=item (optional) Flags.  A string which specifies attach options 
as single characters in the string: "o" for override 


Returns:  String containing hardware type and version from manufacturer "VERSION" output.

Will not attach to "BUSY" hardware unless override flag is given.

=cut

sub attach {
    my ($self) = shift;
    my $flags = shift || "";
    if ($self->DATAPATH()) { 
        $self->DATAPATH()->attach(option => $flags);
        if ($self->DATAPATH()->attached &&
                $self->compile_package) { 
            # Create a machine compiler for the attached hardware
            $self->COMPILER($self->compile_package()->new());
            # Compiler needs datapath for internal sub's
            $self->COMPILER()->DATAPATH( $self->DATAPATH() );
        }
    }
    return $self->VERSION();
}

sub hw_get_version {
    my $self = shift;
    return $self->command("GET_VERSION");
    
}

=head2 Write

Function to send a command to hardware Robotics device driver.

=cut

sub Write {
    my $self = shift;
    warn "!  Write needs removal\n";
	if ($self->DATAPATH() && $self->DATAPATH()->attached()) { 
	    if ($self->HWTYPE() =~ /GENESIS/) {
	        # XXX temporary
	        my $selector = $self->DATAPATH();
            my $rval = $selector->write(@_);
            return $rval;
	    }
	}
	else {
		warn "! attempted Write when not Attached\n";
		return "";
	}
}

sub command { 
    my $self = shift;
    if ($self->DATAPATH() && $self->DATAPATH()->attached()) { 
        if ($self->COMPILER) { 
            my $code = $self->COMPILER()->compile(@_);
            return $self->DATAPATH()->write($code) if $code;
        }
        else { 
            warn "! No command compiler for ".$self->connection. "\n";
        }
    }
	else {
		warn "! attempted 'command' when not Attached\n";
		return "";
	}
}

# sub command1 is for single(firmware) commands
sub command1 { 
    my $self = shift;
    if ($self->DATAPATH() && $self->DATAPATH()->attached()) { 
        if ($self->COMPILER) { 
            my $code = $self->COMPILER()->compile1(@_);
            return $self->DATAPATH()->write($code);
        }
        else { 
            warn "! No command compiler for ".$self->connection. "\n";
        }
    }
	else {
		warn "! attempted 'command' when not Attached\n";
		return "";
	}
}

=head2 park

Park robotics motor arm (perhaps running calibration), based on the motor name (see 'move') 

For parking roma-named arms, use the arguments:
=item (optional) grip - gripper (hand) action for parking: 
	"n" or false means unchanged grip (default), "p" for park the grip

For parking liha-named arms, use the arguments:


For parking 
Return status string.
May take time to complete.

=cut

sub park {
	my $self  = shift;
	my $motor = shift || "roma0";
	my $grip  = shift || "0";
	my $reply;
	if ($motor =~ m/liha(\d*)/i) {
		$self->command("LIHA_PARK", lihanum => $1) if $1;
		$self->command("LIHA_PARK", lihanum => "0") if !$1;
	}
	elsif ($motor =~ m/roma(\d*)/i) {
		my $motornum = 0;
		# XXX: Check if \d is active arm, if not use SET_ROMANO to make active
		if ($1 > 0) { 
			$motornum = $1;
		}
		$self->command("SET_ROMANO", romanum => $motornum);
		$reply = $self->Read();
		if ( $grip =~ m/p/i ) {
			$grip = "1";
		}
		else {
			$grip = "0";
		}
		$self->command("ROMA_PARK", grippos => $grip);
	}
	elsif ($motor =~ m/lihi(\d*)/i) {
		# "arm number always zero"
		my $arm = "0";
		$self->command("LIHA_PARK", lihanum => $arm);
	}
	elsif ($motor =~ m/pnp(\d*)/i) {

		# XXX: allow user to set handpos (gripper)
		my $handpos = 0;
		$self->command("PNP_PARK", gripcommand => $handpos);
	}
	return $reply = $self->Read();
}

=head2 grip

Grip robotics motor gripper hand, based on the motor name (see 'move').

For roma-named motors, the gripper hand motor name is the same as the arm motor name.

For roma-named motors, use the arguments:
=item (optional) direction - "o" for hand open, or "c" for hand closed (default)
=item (optional) distance - numeric, 60..140 mm (default: 110)
=item (optional) speed - numeric, 0.1 .. 150 mm/s (default: 100)
=item (optional) force - numeric when moving hand closed, 1 .. 249 (default: 40)

For pnp-named motors, use the arguments:
=item (optional) direction - "o" for hand open/release tube, or "c" for hand closed/grip (default)
=item (optional) distance - numeric, 7..28 mm (default: 16)
=item (optional) speed - numeric (unused)
=item (optional) force - numeric (unused)


Return status string.
May take time to complete.

=cut

sub grip {
	my $self     = shift;
	my $motor    = shift || "roma0";
	my $dir      = shift || "c";
	my $distance = shift;
	my $speed    = shift;
	my $force    = shift;

	# ROMA_GRIP  [distance;speed;force;strategy]
	#  Example: ROMA_GRIP;80;50;120;0
	# PNP_GRIP  [distance;speed;force;strategy]
	#  Example: PNP_GRIP;16;0;0;0
	# TEMO_PICKUP_PLATE [grid;site;plate type]
	# TEMO_DROP_PLATE [grid;site;plate type]
	# CAROUSEL_DIRECT_MOVEMENTS [device;action;tower;command]

	# C=close/gripped=1, O=open/release=0
	if ( $dir =~ m/c/i ) { $dir = "1"; }
	else { $dir = "0"; }

	my $reply;
	if ( $motor =~ m/roma(\d*)/i ) {
		if (!$distance) { $distance = "110" };
		if (!$speed) { $speed = "50" };
		if (!$force) { $force = "40" };
		# XXX: Check if \d is active arm, if not use SET_ROMANO to make active
		$self->command("ROMA_GRIP", 
            distance => $distance, speed => $speed,
            force => $force, gripcommand => $dir);
	}
	elsif ( $motor =~ m/pnp(\d*)/i ) {
		# "speed, force: unused"
		if (!$distance) { $distance = "16" };
		$self->command("PNP_GRIP", 
            distance => $distance, speed => $speed, 
            force => $force, strategy => $dir);
	}
	return $reply = $self->Read();
}



=head2 move

Move robotics motor arm, based on the case-insensitive motor name and given coordinates.  

Note: The Gemini application asks the user for arm numbers 1,2,3... in the GUI application, 
whereas the robotics command language (and this Perl module) use arm numbers 0,1,2,..
The motors are named as follows:


=item "roma0" .. "romaN" - access RoMa arm number 0 .. N.  Automatically switches to make the arm
the current arm.  Alternatively, "romaL" or "romal" can be used for the left arm (same as "roma0") 
and "romaR" or "romar" can be use for the right arm (same as "roma1"). 

=item "pnp0" .. "pnpN" - access PnP arm number 0 .. N.   Alternatively, "pnpL" or "pnpl" can be used 
for the left arm (same as "pnp0") 
and "pnpR" or "pnpr" can be use for the right arm (same as "pnp1").  Note: The Gemini application 
asks the user for arm numbers 1,2,3... in the GUI application, whereas the robotics command language
(and this Perl module) use arm numbers 0,1,2,..

=item "temo0" .. "temoN" - access TeMo arm number 0 .. N.

=item "liha0" .. "lihaN" - access LiHA arm number 0 .. N.  (Note: no commands exist)
 
For moving roma-named motors with Gemini-defined vectors, use the arguments:

=item vector - name of the movement vector (programmed previously in Gemini)

=item (optional) direction - "s" = travel to vector start, "e" = travel to vector end 
(default: go to vector end)

=item (optional) site - numeric, (default: 0)

=item (optional) relative x,y,z - three arguments indicating relative positioning (default: 0)

=item (optional) linear speed (default: not set)

=item (optional) angular speed (default: not set)

For moving roma-named motors with Robotics::Tecan points (this module's custom software),
use the arguments:

=item point - name of the movement point (programmed previously)

For moving pnp-named motors, use the arguments:

=item TBD

For moving temo-named motors, use the arguments:

=item TBD

For moving carousel-named motors, use the arguments:

=item TBD

Return status string.
May take time to complete.

=cut

sub move {
	my $self         = shift;
	my $motor        = shift || "roma0";
	my $name         = shift || "HOME1";
	my $dir          = shift || "0";
	my $site         = shift || "0";
	my $xdelta       = shift || "0";
	my $ydelta       = shift || "0";
	my $zdelta       = shift || "0";
	my $speedlinear  = shift || 0;
	my $speedangular = shift || 0;

# ROMA_MOVE  [vector;site;xOffset;yOffset;zOffset;direction;XYZSpeed;rotatorSpeed]
#  Example: ROMA_MOVE;Stacker1;0;0;0;0;0
# PNP_MOVE [vector;site;position;xOffset;yOffset;zOffset;direction;XYZSpeed]
# TEMO_MOVE [site;stacker flag]
#	Example: TEMO_MOVE;1
# CAROUSEL_DIRECT_MOVEMENTS [device;action;tower;command]

	# S=vector points to start=1, E=vector points to end=0
    # ""0 = from safe to end position, 1 = from end to safe position""
	if    ( $dir =~ m/s/i ) { $dir = "1"; }
	#elsif ( $dir =~ m/e/i ) { $dir = "0"; }
	else { $dir = "0"; }
	
	my $reply;
	if ( $motor =~ m/roma(\d*)/i ) {
        # First check for Robotics::Tecan point
        if (grep {$_ eq $name} keys %{$self->{POINTS}->{$motor}}) { 
            no warnings 'uninitialized';
            my $motornum = $1 + 1; # XXX motornum needs verification with docs

            # Verify motors are OK to move
            $self->{COMPILER}->CheckMotorOK($motor, $motornum) || return "";
            
            # Write movement command
            my ($x, $y, $z, $r, $g, $speed) = split(",", $self->{POINTS}->{$motor}->{$name});
            if (!$speed) { $speed = "0"; }
            my $cmd = "SAA1,$x,$y,$z,$r,$g,$speed";
            $self->command1("R". $motornum. $cmd);
            $reply = $self->Read();
            if ($reply =~ /^0/) { 
                # Program point is OK
                $self->command1("R". $motornum. "AAA");
                $reply = $self->Read();
            }

            # Verify move is correct
            $self->{COMPILER}->CheckMotorOK($motor, $motornum) || return "";
            return $reply;
        }
        else { 
            # Use ROMA_MOVE
            my $motornum = 0;
            # XXX: Check if \d is active arm, if not use SET_ROMANO to make active
            if ($1 > 0) { 
                $motornum = $1;
                
            }
            $self->command("SET_ROMANO", romanum => $motornum);
            $reply = $self->Read();
            
            my $cmd = join( ";", $name, $site, $xdelta, $ydelta, $zdelta, $dir );
            if ( $speedlinear > 0 ) { $cmd .= ";$speedlinear"; }
            if ( $speedangular > 0 ) {
                if ( $speedlinear < 1 ) { $cmd .= ";400"; }
                $cmd .= ";$speedangular";
            }
            $self->command("ROMA_MOVE", 
                    vectorname => $name, site => $site,
                    deltax => $xdelta, deltay => $ydelta, deltaz => $zdelta,
                    direction => $dir, 
                    xyzspeed => $speedlinear, 
                    rotatorspeed => $speedangular);
                                
            return $reply = $self->Read();
        }
	}
	elsif ( $motor =~ m/pnp(\d*)/i ) {

		# XXX: TBD
	}
}


=head2 move_path

Move robotics motor arm along predefined path, based on the case-insensitive motor name and given coordinates.  See move. 

Arguments:

=item Name of motor.

=item Array of Robotics::Tecan custom points (up to 100 for Genesis)

Return status string.
May take time to complete.

=cut

sub move_path {
	my $self         = shift;
	my $motor        = shift || "roma0";
	my @points       = @_;
	my $name;
	my $reply;
	if ( $motor =~ m/roma(\d*)/i ) {
        my $motornum = $1 + 1; # XXX motornum needs verification with docs
        # Verify motors are OK to move
        $self->{COMPILER}->CheckMotorOK($motor, $motornum) || return "";
        my $p = 1;
        foreach $name (@points) { 
            # First check for Robotics::Tecan point
            if (grep {$_ eq $name} keys %{$self->{POINTS}->{$motor}}) { 
                no warnings 'uninitialized';
                my ($x, $y, $z, $r, $g, $speed) = split(",", $self->{POINTS}->{$motor}->{$name});
                if (!$speed) { $speed = "0"; }
                my $cmd = "SAA$p,$x,$y,$z,$r,$g,$speed";
                $self->command1("R". $motornum. $cmd);
                $reply = $self->Read();
                if (!($reply =~ /^0/)) { 
                    warn "Error programming point '$name'\n";
                    return "";
                }
                $p++;
            }
            last if $p > 100;
    	}
	    if ($p > 1) {
            # Program point is OK - Start Move
            $self->command1("R". $motornum. "AAA");
            $reply = $self->Read();
                
            # Verify move is correct
            $self->{COMPILER}->CheckMotorOK($motor, $motornum) || return "";
            return $reply;
	    }
	}
	
}

sub WriteRaw {
# This function provided for debug only - do not use
    my $self = shift;
    warn "!  WriteRaw needs removal\n";
    my $data;
	if ($self->{ATTACHED}) { 
        $data =~ s/[\r\n\t\0]//go;
        $data =~ s/^\s*//go;
        $data =~ s/\s*$//go;
        if ($self->{FID}) { 
            $self->{FID}->Write($data . "\0");
        }
        elsif ($self->{SERVER}) { 
            my $socket = $self->{SOCKET};
            print $socket ">$data\n";
            print STDERR ">$data\n" if $Debug;
        }
	}
	else {
		warn "! attempted Write when not Attached\n";
		return "";
	}
     warn "!! delete this function";
          
}
=head2 Read

Low level function to read commands from hardware.

=cut
sub Read {
    my $self = shift;
    # Reading while unattached may hang depending on device
    #  so always check attached()
	if ($self->DATAPATH() && $self->DATAPATH()->attached()) { 
        my $data;
        my $selector = $self->DATAPATH();
        $data = $selector->read();
	}
	else {
		warn "! attempted Read when not Attached\n";
		return "";
	}
}


=head2 detach

End communication to the hardware.

=cut

sub detach {
    my($self) = shift;
    if ($self->DATAPATH()) { 
        $self->DATAPATH()->close();
        $self->DATAPATH( undef );
    }
    return;
}

=head2 status_hardware

Read hardware type.  
Return hardware type string (should always be "GENESIS").

=cut

sub status_hardware {
    my $self = shift;
	my $reply;
	$reply = $self->command("GET_RSP");
	if (!($reply =~ m/genesis/i)) {
		warn "Expected response GENESIS from hardware"
	}
	return $reply;
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
    my $self = shift;
    my $infile = shift || croak "cant open configuration file";
	
	open(IN, $infile) || return 1;
	my $s = do { local $/ = <IN> };
    $self->{CONFIG} = YAML::XS::Load($s) || return 2;
    
    warn "Configuring from $infile\n";
    my $make;
    my $model;
    for $make (keys %{$self->{CONFIG}}) {
        if ($make =~ m/tecan/i) { 
            warn "Configuring $make\n";
            for $model (keys %{$self->{CONFIG}->{$make}}) {
                warn "Configuring $model\n";
                if ($model =~ m/genesis/i) {
                    Robotics::Tecan::Genesis::configure(
                            $self, $self->{CONFIG}->{$make}->{$model});                        
                }
            }
        }
    }
    return 0;
}

=head2 status

Read hardware status.  Return status string.

=cut

sub status {
    my $self = shift;
	my $reply;
	$self->Write("GET_STATUS");
	return $reply = $self->Read();
}

=head2 initialize

Quickly initialize hardware for movement (perhaps running quick calibration).  
Return status string.
May take time to complete.

=cut

sub initialize {
    my $self = shift;
	my $reply;
	
	#$self->command("#".$self->{HWNAME}."PIS");
	#return $reply = $self->Read();
}


=head2 initialize_full

Fully initialize hardware for movement (perhaps running calibration).  
Return status string.
May take time to complete.

=cut

sub initialize_full {
    my $self = shift;
	my $reply;
	return $self->command("INIT_RSP");
}




=head2 simulate_enable

Robotics::Tecan internal hook for simulation and test.  Not normally used.

=cut

sub simulate_enable {
	# Modify internals to do simulation instead of real communication
	$Robotics::Tecan::Gemini::PIPENAME = '/tmp/gemini';
}



=head1 REFERENCE ON NAMED PIPES

Named pipes must be accessed as UNCs. This means that the computer name where the 
named pipe is running is a part of its name. Just like any UNC a share name must 
be specified. For named pipes the share name is pipe. Examples are:

\\machinename\pipe\My Named Pipe
\\machinename\pipe\Test
\\machinename\pipe\data\Logs\user_access.log

Notice how the third example makes use of an arbitrarly long path and that 
it has what appear to be subdirectories. Since a named pipe is not truly a part 
of the a disk based file system there is no need to create the data\logs subdirectories; 
they are simply part of the named pipes name.
Also notice that the third example uses a file extension (.log). This extension does 
absolutely nothing and is (like the subdirectories) simply part of the named pipes name.

When a client process attempts to connect to a named pipe it must specify a full UNC. 
If, however, the named pipe is on the same computer as the client process then the 
machine name part of the UNC can be replaced with a dot "." as in:

\\.\pipe\My Named Pipe


=head1 AUTHOR

Jonathan Cline, C<< <jcline at ieee.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-robotics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Robotics>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Robotics::Tecan


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


1; # End of Robotics::Tecan

__END__

