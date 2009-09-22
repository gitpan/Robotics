
package Robotics::Tecan::Genesis::Liha;

# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:

use warnings;
use strict;
use Moose::Role;
#extends 'Robotics::Tecan::Genesis';

#
# Tecan Genesis 
# Liquid handling commands
#


=head2 tip_aspirate

Aspirate with coupled tips from named arm.  Use tip string to specify tips.

Specify volume and location, with optional liquid type, flags, etc.
Requires work table to be previously loaded.

Return status string.
May take time to complete.

=item named motor arm - string, motor name (default: "liha")

=item (optional) tips - string, "1" or "2-6" or "2,4,1,7" or "1,5-8" or "all" (default: "1")
=item (optional) volume - string, specifying volume of 1-1000 for each tip, such as "20,20,20" (default: 10)
=item (optional) location - string, specifying "well" numbers or well co-ordinates (default: "1")
=item (optional) liquid type - string, from configuration database (default: "Water")
=item (optional) position - numeric, carrier location, 1-67 (default: 1)
=item (optional) site - numeric, rack position, 0-127 (default: 0)
=item (optional) inter-tip distance - numeric, 1-n (default: 1)
=item (optional) flags - various flags for specifying actions after aspiration (default: "") 
=item (optional) flag argument - various arguments depending on flags (default: "")

=cut

sub tip_aspirate {
    my $self = shift;
    my $motor = shift || "liha";
    my $tips = shift || "1";
    my $volume = shift || "10";
    my $location = shift || '"0C0810000000000000"';
    my $liquid = shift || "Water";
    my $grid = shift || "11";
    my $site = shift || "0";
    my $tipdist = shift || "1";
    my $flags = shift || "0";
    my $flagarg = shift || "";
    
    # ASPIRATE() 
    #  Example: Aspirate(7,">> MagBeads in Viscous Soln <<  23","BUFFER_UL",
    #       "BUFFER_UL","BUFFER_UL",0,0,0,0,0,0,0,0,0,11,0,1,"0C0870000000000000",0);
    # Example: Aspirate(85,"Water","5",0,"5",0,"5",0,"5",0,0,0,0,0,18,0,1,"0C08ˆ0000000000000",0);
    
    my $tipMask = _tipStringToMask8($tips);
    my @volumes = split(",", $volume . ",0,0,0,0,0,0,0,0,0,0");
    for $volume (0..7) {
        if ($volumes[$volume] > 0) { 
            $volumes[$volume] .= '"'. $volumes[$volume]. '"';   
        }
    }
    my $volumestring = join(",", @volumes[0..7]);
    my $wellstring = $location;
    my $loopoption = "0";
    my $loopname = "";
    my $loopaction = "";
    my $loopindex = "";
    if ($flags) { 
        $loopoption = $flags;
    }
    
    my $cmd = "B;ASPIRATE(";
    $liquid =~ s/"//g;
    $liquid = '"'. $liquid. '"';
    if ($loopoption > 0) {
    	$cmd .= join(",", ($tipMask, $liquid, $volume, 
    	       $grid, $site, $tipdist, $wellstring, 
    	       $loopoption, $loopname, $loopaction, $loopindex)). ");";
    }
    else {
        $cmd .= join(",", ($tipMask, $liquid, $volume, 
                $grid, $site, $tipdist, $wellstring, "0")). ");";
    }
    $self->Write($cmd);
	return $self->Read();
}



=head2 tip_dispense

Aspirate with coupled tips from named arm.  Use tip string to specify tips.

Specify volume and location, with optional liquid type, flags, etc.
Requires work table to be previously loaded.

Return status string.
May take time to complete.

=item named motor arm - string, motor name (default: "liha")

=item All other arguments (many) are the same as tip_aspirate.

=cut

sub tip_dispense {
    my $self = shift;
    my $motor = shift || "liha";
    my $tips = shift || "1";
    my $volume = shift || "10";
    my $location = shift || "0C0810000000000000";
    my $liquid = shift || "Water";
    my $grid = shift || "11";
    my $site = shift || "0";
    my $tipdist = shift || "1";
    my $flags = shift || "";
    my $flagarg = shift || "";
    
    # DISPENSE() 
    #  Example: Dispense(7,">> MagBeads in Viscous Soln <<  33",
    #       "SAMPLE_UL","SAMPLE_UL","SAMPLE_UL",0,0,0,0,0,0,0,0,0,11,1,1,"0C0870000000000000",0);
    my $tipMask = _tipStringToMask8($tips);
    my @volumes = split(",", $volume . "," x 7);
    my $volumestring = join(",", @volumes[0..7]);
    my $wellstring = $location;
    my $loopoption;
    my $loopname;
    my $loopaction;
    my $loopindex;
    if ($flags) { 
        $loopoption = $flags;
    }
    my $cmd = "B;DISPENSE(". join(",", ($tipMask, $liquid, $volume, 
    	       $grid, $site, $tipdist, $wellstring));
    if ($loopoption > 0) {
    	$cmd .= join(",", ($loopoption, $loopname, $loopaction, $loopindex));
    }
    else {
        $cmd .= "0";
    }
    $cmd .= ");";
    
    $self->Write($cmd);
	return $self->Read();
}


=head2 tip_set_supply

Set type and location for the supply of pipette tips.
Return status string.
Returns immediately.

=item (optional) type - numeric, 1-4 (default: 1)
=item (optional) grid - numeric, 1-99 (default: 1)
=item (optional) site - carrier location, 0-63 (default: 0)
=item (optional) position - rack position, 0-95 (default: 0)
=cut

sub tip_set_supply {
    my $self = shift;
    my $type = shift || "1";
    my $grid = shift || "1";
    my $site = shift || "0";
    my $position = shift || "0";

    # SET_DITI  [type;grid;site;position]
    #  Example: SET_DITI;1;32;0;0

	my $cmd = join(";", ("set_diti", $type, $grid, $site, $position));

    $self->Write($cmd);
	return $self->Read();
}


=head2 tip_query

Query next available tip location, given tip type.
Return query status string (example: "0;32;0;0")
Returns immediately.

=item type - numeric, 1-4 (default: 1)

=cut

sub tip_query {
    my $self = shift;
    my $type = shift || "1";

    # GET_DITI  [type]
    #  Example: GET_DITI;1

	my $cmd = join(";", ("get_diti", $type));

    $self->Write($cmd);
	return $self->Read();
}


=head2 tip_query_usage

Query usage of tip type.
Return tip usage string (example: "0;96")
Returns immediately.

=item (optional) type - numeric, 1-4 (default: 1)

=cut

sub tip_query_usage {
    my $self = shift;
    my $type = shift || "1";

    # GET_USED_DITIS  [type]
    #  Example: GET_USED_DITIS;1 

	my $cmd = join(";", ("get_used_ditis", $type));

    $self->Write($cmd);
	return $self->Read();
}


=head2 tip_pause

Pause pipetting if robotics is in the PIPETTING state.
No arguments.
Returns error if any.
Returns immediately (?).

=cut

sub tip_pause {
    my $self = shift;

    # PAUSE_PIPETTING 

    $self->Write("pause_pipetting");
	return $self->Read();
}

=head2 tip_couple

Connect pipetting tips to liquid handling arm.


=item (optional) Tips to use.  String, in the format: "1" or "2-5" or "1,4,8" or "all".  Default: "1"
=item (optional) Type of tip.  Numeric, 0-3, as defined in Tecan configuration MINUS ONE.  Default: 0
=item (optional) Operational flags.  Numeric.  0=none.  1=retry tip fetching up to 3 times at 
successive positions.  Default: 0

Returns error if any.
May take time to complete.

=cut

sub tip_coupleWorklist {
    my $self = shift;
    my $motor = shift || "liha";
    my $tiparg = shift || "1";
    my $type = shift || 0;
    my $flag = shift || 0;
	
    # GetDITI(1,0,0);  - connect a tip to pipette #1 (the first pipette)
	my $tipmask = _tipStringToMask8($tiparg);

	my $cmd = "B;GetDITI(". join(',', ($tipmask, $type, $flag)) . ");";
	
    #open(WORKLIST, ">/cygdrive/c/temp/genesis.gwl") || die;
    #print WORKLIST "$cmd\n";
    #close WORKLIST;

    $cmd = 'LOAD_WORKLIST;Worklist(0,c:\temp\genesis.gwl,15,"Water");'.
        'Wash(1,255,255,255,255,"2.0",500,"1.0",500,10,70,30,0,0,1000);';
        
    $self->Write($cmd);
	my $reply = $self->Read();

    sleep(5);
    return $reply;
}

=head2 tip_coupleFirmware

Couple (mechanically join) a pipetting tip(s) to liquid handling arm at the current arm position.


=item (optional) Tips to use.  String, in the format: "1" or "2-5" or "1,4,8" or "all".  Default: "1"
=item (optional) Type of tip.  Numeric, 0-3, as defined in Tecan configuration MINUS ONE.  Default: 0
=item (optional) Operational flags.  Numeric.  0=none.  1=retry tip fetching up to 3 times at 
successive positions.  Default: 1

Returns error if any.
May take time to complete.

See also: tip_uncouple

=cut

sub tip_coupleFirmware {
    my $self = shift;
    my $tiparg = shift || "1";
    my $type = shift || 0;
    my $flag = shift || 1;
	
    # GetDITI(1,0,0); 
	my $tipmask = _tipStringToMask8($tiparg);

	# use firmware cmd; example #A1AGT170,500,100
	my $cmd = "#A1AGT". join(',', ($tipmask, $type, $flag)) . ");";
    $self->Write($cmd);
	return $self->Read();
}


=head2 tip_uncoupleFirmware

Uncouple (mechanically unjoin) a pipetting tip(s) from liquid handling arm at the current arm position.


=item (optional) Tips to use.  String, in the format: "1" or "2-5" or "1,4,8" or "all".  Default: "1"

Returns error if any.
May take time to complete.

See also: tip_couple

=cut

sub tip_uncoupleFirmware { 
    my $self = shift;
    my $tiparg = shift || "1";
    my $type = shift || 0;
    my $flag = shift || 1;
	
    # GetDITI(1,0,0); 
	my $tipmask = _tipStringToMask8($tiparg);

	# use firmware cmd; example #A1ADT170
	my $cmd = "#A1AGT". $tipmask;
    $self->Write($cmd);
	return $self->Read();
}


=head2 _tipStringToMask8

Internal function.
Convert tip string into a numeric tip mask, where tips are numbered "1" to "8".

=item String: "1" or "2-6" or "2,4,1,7" or "1,5-8" or "all" (default: "1")

Returns: 8-bit numeric value.

=cut

sub _tipStringToMask8 {
    my $s = shift || "1";
    
    # tip 1 => return mask=1
    # tip 8 => return mask=128
    # tips 1-8 => return mask=255
    
    # base index = 1 for calling argument of 1-8 vs. index=0 for calling argument of 0-7
    return $s =~ m/all/i ? 255 : _convertStringRangeToMask8($s, 1);
}

sub _convertStringRangeToMask8 {  
	# arg0: string to parse,  "1" or "1,2,3" or "1-3" or "3-5,6,7-8"
	# arg1: index, 0 means bits are 0..7, 1 means bits are 1..8
	# returns: 8-bit number
	my $index = pop;
	my $s = shift; 
	$s =~ s/(\d+)-(\d+)/join ',', $1 .. $2/eg;
	return _convertArrayToMask8($s =~ /\d+/g, $index);
}

sub _convertArrayToMask8 {
	# arg0: numbers in array,  (1,4,8)
	# arg1: base index for bit number, 0 means bits are 0..7, 1 means bits are 1..8
	# error checking:  bit numbers outside 0+index .. 7+index are ignored
	# returns: 8-bit number
	my $n = 0;
	my $base = pop @_;
	my @bits = @_;
	$n |= 1 << ($_ - $base) for grep { $_ >= $base && $_ <= 7+$base } @bits;
	return $n;
}


1; # End of Robotics::Tecan::Genesis::liquid

__END__

