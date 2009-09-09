
package Robotics::Tecan;

# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:

use warnings;
use strict;

#
# Tecan Genesis 
# Liquid handling commands
#

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

=head2 tip_get

Connect pipetting tips to liquid handling arm.


=item (optional) Tips to use.  String, in the format: "1" or "2-5" or "1,4,8" or "all".  Default: "1"
=item (optional) Type of tip.  Numeric, 0-3, as defined in Tecan configuration MINUS ONE.  Default: 0
=item (optional) Operational flags.  Numeric.  0=none.  1=retry tip fetching up to 3 times at 
successive positions.  Default: 1

Returns error if any.
May take time to complete.

=cut

sub tip_get {
    my $self = shift;
    my $tiparg = shift || "1";
    my $type = shift || 0;
    my $flag = shift || 1;
	
    # GetDITI(1,0,0); 
	my $tipmask = _tipStringToMask8($tiparg);

	my $cmd = "GetDITI(". join(',', ($tipmask, $type, $flag)) . ");";
	# use firmware cmd; example #A1AGT170,500,100
	#my $cmd = "#AGT". join(',', ($tipmask, $type, $flag)) . ");";
    $self->Write($cmd);
	return $self->Read();
}

=head2 tip_couple

Couple (mechanically join) a pipetting tip(s) to liquid handling arm at the current arm position.


=item (optional) Tips to use.  String, in the format: "1" or "2-5" or "1,4,8" or "all".  Default: "1"
=item (optional) Type of tip.  Numeric, 0-3, as defined in Tecan configuration MINUS ONE.  Default: 0
=item (optional) Operational flags.  Numeric.  0=none.  1=retry tip fetching up to 3 times at 
successive positions.  Default: 1

Returns error if any.
May take time to complete.

See also: tip_uncouple

=cut

sub tip_couple {
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


=head2 tip_couple

Uncouple (mechanically unjoin) a pipetting tip(s) from liquid handling arm at the current arm position.


=item (optional) Tips to use.  String, in the format: "1" or "2-5" or "1,4,8" or "all".  Default: "1"

Returns error if any.
May take time to complete.

See also: tip_couple

=cut

sub tip_uncouple { 
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
    # base index = 1 for argument of 1-8 vs. 0-7
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
	$n |= 1 << $_ - $base for grep { $_ >= $base && $_ <= 7+$base } @_;
	return $n;
}


1; # End of Robotics::Tecan::Genesis::liquid

__END__

