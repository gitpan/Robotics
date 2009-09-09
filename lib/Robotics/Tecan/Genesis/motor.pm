
package Robotics::Tecan;

# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:

#
# Tecan Genesis
# Motor commands
#

use warnings;
use strict;

=head2 CheckMotorOK

Internal function.  Verifies named motor is OK to move or prior move was
successful.

Returns 0 on error, status string if OK.

=cut

sub CheckMotorOK {
	my $self         = shift;
    my $motorname    = shift;
    my $motornum     = shift;

    my $reply;
    $self->WriteFirmware("R". $motornum. "REE");
    $reply = $self->Read();
    $reply = substr($reply, 2);
    if ($reply =~ /[^@]/) { 
        warn "Robotics error found: $reply\n"; 
        return 0;
    }

    return $reply;
}


=head2 Move

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
            $self->CheckMotorOK($motor, $motornum) || return "";
            
            # Write movement command
            my ($x, $y, $z, $r, $g, $speed) = split(",", $self->{POINTS}->{$motor}->{$name});
            if (!$speed) { $speed = "0"; }
            my $cmd = "SAA1,$x,$y,$z,$r,$g,$speed";
            $self->WriteFirmware("R". $motornum. $cmd);
            $reply = $self->Read();
            if ($reply =~ /^0/) { 
                # Program point is OK
                $self->WriteFirmware("R". $motornum. "AAA");
                $reply = $self->Read();
            }

            # Verify move is correct
            $self->CheckMotorOK($motor, $motornum) || return "";
            return $reply;
        }
        else { 
            # Use ROMA_MOVE
            my $motornum = 0;
            # XXX: Check if \d is active arm, if not use SET_ROMANO to make active
            if ($1 > 0) { 
                $motornum = $1;
                
            }
            $self->Write("SET_ROMANO;" . $motornum);
            $reply = $self->Read();
            
            my $cmd = join( ";", $name, $site, $xdelta, $ydelta, $zdelta, $dir );
            if ( $speedlinear > 0 ) { $cmd .= ";$speedlinear"; }
            if ( $speedangular > 0 ) {
                if ( $speedlinear < 1 ) { $cmd .= ";400"; }
                $cmd .= ";$speedangular";
            }
            
            $self->Write("ROMA_MOVE;$cmd");
            return $reply = $self->Read();
        }
	}
	elsif ( $motor =~ m/pnp(\d*)/i ) {

		# XXX: TBD
	}
}


=head2 Move

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
        $self->CheckMotorOK($motor, $motornum) || return "";
        my $p = 1;
        foreach $name (@points) { 
            # First check for Robotics::Tecan point
            if (grep {$_ eq $name} keys %{$self->{POINTS}->{$motor}}) { 
                no warnings 'uninitialized';
                my ($x, $y, $z, $r, $g, $speed) = split(",", $self->{POINTS}->{$motor}->{$name});
                if (!$speed) { $speed = "0"; }
                my $cmd = "SAA$p,$x,$y,$z,$r,$g,$speed";
                $self->WriteFirmware("R". $motornum. $cmd);
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
            $self->WriteFirmware("R". $motornum. "AAA");
            $reply = $self->Read();
                
            # Verify move is correct
            $self->CheckMotorOK($motor, $motornum) || return "";
            return $reply;
	    }
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
		$self->Write("LIHA_PARK;$1") if $1;
		$self->Write("LIHA_PARK;0")  if !$1;
	}
	elsif ($motor =~ m/roma(\d*)/i) {
		my $motornum = 0;
		# XXX: Check if \d is active arm, if not use SET_ROMANO to make active
		if ($1 > 0) { 
			$motornum = $1;
		}
		$self->Write("SET_ROMANO;" . $motornum);
		$reply = $self->Read();
		if ( $grip =~ m/p/i ) {
			$grip = "1";
		}
		else {
			$grip = "0";
		}
		my $cmd = join( ";", ( "roma_park", $grip ) );
		$self->Write($cmd);
	}
	elsif ($motor =~ m/lihi(\d*)/i) {
		# "arm number always zero"
		my $arm = "0";
		my $cmd = join(";", ("liha_park", $arm));
		$self->Write($cmd);
	}
	elsif ($motor =~ m/pnp(\d*)/i) {

		# XXX: allow user to set handpos (gripper)
		my $handpos = 0;
		$self->Write("PNP_PARK;$handpos");
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
		my $cmd = join( ";", ( "roma_grip", $distance, $speed, $force, $dir ) );
		$self->Write($cmd);
	}
	elsif ( $motor =~ m/pnp(\d*)/i ) {
		# "speed, force: unused"
		if (!$distance) { $distance = "16" };
		my $cmd = join( ";", ( "pnp_grip", $distance, $speed, $force, $dir ) );
		$self->Write($cmd);
	}
	return $reply = $self->Read();
}

1;    # End of Robotics::Tecan::Genesis::motor

__END__

