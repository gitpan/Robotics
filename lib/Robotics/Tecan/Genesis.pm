
package Robotics::Tecan::Genesis;

# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
# $Id$

use warnings;
use strict;

use Robotics::Tecan::Genesis::config;
use Robotics::Tecan::Genesis::motor;
use Robotics::Tecan::Genesis::liquid;

our $PIPENAME;

#use AutoLoader qw(AUTOLOAD);

#require Exporter;
#our @ISA = qw(Exporter);


my $Debug = 1;

#our @EXPORT = qw(
#    Write
#    Read
#    new
#);



=head1 NAME

Robotics::Tecan::Genesis - (Internal module) Control of Tecan robotics hardware as Robotics module

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';


=head1 SYNOPSIS

Genesis hardware support for Robotics::Tecan.


=head1 EXPORT


=head1 FUNCTIONS

=head2 new

=head1 AUTHOR

Jonathan Cline, C<< <jcline at ieee.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-robotics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Robotics>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Robotics::Tecan


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-Robotics>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-Robotics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-Robotics>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-Robotics/>

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

