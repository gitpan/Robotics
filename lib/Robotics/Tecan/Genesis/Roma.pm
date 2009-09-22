
package Robotics::Tecan::Genesis::Roma;

#
# Tecan Genesis
# Motor commands
#

use warnings;
use strict;
use Moose::Role;
use Carp;
#extends 'Robotics::Tecan::Genesis';

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
    my $code;
    $code = $self->compile1("R". $motornum. "REE");
    $self->DATAPATH()->write($code);
    $reply = $self->DATAPATH()->read();
    if ($reply =~ /^[^0]/) { 
        # command error
        carp "Robotics cmd error: $reply\n";
        return 0;       
    }
    # set reply to only result string, strip '0;'
    $reply = substr($reply, 2);
    if ($reply =~ /[^@]/) { 
        warn "Robotics error found: $reply\n"; 
        return 0;
    }

    return $reply;
}

1;    # End of Robotics::Tecan::Genesis::Roma

__END__

