
package Robotics::Tecan::Genesis::Session;

# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:

#
# Tecan Genesis
# Session layer: configuration handling of the 'attached' hardware
#

use warnings;
use strict;
use Moose::Role;
#extends 'Robotics::Tecan::Genesis';

use YAML::XS;

=head2 configure

Internal function.  Configures internal data from user file.

Returns 0 on error, status string if OK.

=cut

sub configure {
	my $self    = shift;
    my $cref    = shift;

    my $section;
    for $section (keys %{$cref}) {
        warn "Configuring $section\n";
        if ($section =~ m/points/i) {
            $self->{POINTS} = $cref->{$section};
        }
    }
        
    print keys %{$self->{POINTS}};
    return 0;
}

1;    # End of Robotics::Tecan::Genesis::Session

__END__