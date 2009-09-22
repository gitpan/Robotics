
package Robotics::Tecan::Genesis;

use warnings;
use strict;

use Moose;
use Robotics::Tecan::Gemini;

with 'Robotics::Tecan::Genesis::Compiler';
with 'Robotics::Tecan::Genesis::Session';
with 'Robotics::Tecan::Genesis::Roma';
with 'Robotics::Tecan::Genesis::Liha';

has 'DATAPATH' => ( is => 'rw', isa => 'Maybe[Robotics::Tecan]' );

my $Debug = 1;


our $comm_ydata;

# Read the YAML-formatted 'translator data' from __DATA__
# Maybe use File::ShareDir & Module::Install to store yaml in a separate file
if (!$comm_ydata) {
    my $comm_yamlstring;
     {
        local( $/ ) = ( undef );
        $comm_yamlstring = <DATA>;    
        $comm_yamlstring =~ s/__END__//;
    }
    
    $comm_ydata = YAML::XS::Load($comm_yamlstring);
    die "Config data empty" 
        unless $comm_ydata->{"type2commands"}->{"send"}->{"GET_VERSION"};
}

sub probe {
    my %list;
    return \%list;
}



=head1 NAME

Robotics::Tecan::Genesis - (Internal module) Control of Tecan robotics hardware as Robotics module

=head1 VERSION

Version 0.22

=cut

our $VERSION = '0.22';



=head1 SYNOPSIS

Genesis hardware support for Robotics::Tecan.


=head1 EXPORT


=head1 FUNCTIONS

=head2 new


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

1; # End of Robotics::Tecan::Genesis

__DATA__
%YAML 1.1
--- # Tecan-Genesis+Gemini
type2commands:
    send:
        SET_DITI:
            args:
                - 4
                - type:1-4 
                - grid:1-99 
                - site:0-63 
                - position:0-95
            recv:
                ok: 0
                err: 3,4
        SET_PNP_BARCODE:
            args:
                - 1
                - barcode
            recv:
                ok: 0
                err: 3,6
        SET_PNPNO:
            args:
                - 1
                - pnpnum
            recv:
                ok: 0
                err: 3
        SET_RACK:
            args:
                - 4
                - racknum:0-n 
                - barcode:optional 
                - location 
                - zero:zero
            recv:
                ok: 0
                err: 4
        SET_RACK_EXT:
            args:
                - 3
                - racknum:0-99 
                - barcode:optional 
                - location
            recv:
                ok: 0
                err: 4
        SET_ROMA_BARCODE:
            args:
              - 1
              - barcode
            recv:
                ok: 0
                err: 3,6
        SET_ROMANO:
            args:
              - 1
              - romanum
            recv:
                ok: 0
                err: 3
        SET_VARIABLE:
            args:
              - 2
              - varname 
              - varvalue:float
            recv:
                ok: 0
                err: 3,10
        SET_VARIABLE_EXT:
            args:
              - 2
              - varname 
              - varvalue:float
            recv:
                ok: 0
                err: 3
        GET_DITI:
            args:
              - 1
              - dititype:1-4
            recv:
                ok: 0
                err: 3,4
        GET_MAX_VARIABLES:
            args:
              - 0
            recv:
                ok: 0
                err: 3
        GET_MAXRACKS:
            args:
              - 0
            recv:
                ok: 0
                err: 3
        GET_PNPNO:
            args:
              - 0
            recv:
                ok: 0-1
                err: 3
        GET_RACK:
            args:
              - 1
              - racknum
            recv:
                ok: 0
                err: 2,3,4
        GET_RACK_EXT:
            args:
              - 1
              - racknum
            recv:
                ok: 0
                err: 3,4
        GET_ROMANO:
            args:
              - 0
            recv:
                ok: 0-1
                err: 3
        GET_RSP:
            args:
              - 0
            recv:
                ok: 0
                err: 2,3
        GET_STATUS:
            args:
              - 0
            recv:
                ok: 0
                err: 2,3
        GET_USED_DITIS:
            args:
              - 0
            recv:
                ok: 0
                err: 3,4
        GET_VARIABLE:
            args:
              - 1
              - varname
            recv:
                ok: 0
                err: 3,14
        GET_VARIABLE_NAME:
            args:
              - 1
              - varindex:0-n
            recv:
                ok: 0
                err: 2,3,4
        GET_VERSION:
            args:
              - 0
            recv:
                ok: 0
                err: 3
        GET_WINDOW_HANDLES:
            args:
              - 0
            recv:
                ok: 0
                err: 3
        ABORT_PIPETTING:
            args:
              - 0
            recv:
                ok: 0
                err: 3,11
        COMMAND:
            args:
              - 1
              - command
            recv:
                ok: 0
                err: 3
        CONTINUE_PIPETTING:
            args:
              - 0
            recv:
                ok: 0
                err: 3,9
        EDIT_SCRIPT:
            args:
              - 1
              - filename
            recv:
                ok: 0
                err: 3,9,12,13
        EDIT_VECTOR:
            args:
              - 2
              - vectorname 
              - sitemax
            recv:
                ok: 0
                err: 2,3,6
        EXECUTE_TEMO_SCRIPT:
            args:
              - 0
            recv:
                ok: 0
                err: 3,4,6
        EXECUTE_WORKLIST:
            args:
              - 0
            recv:
                ok: 0
                err: 3,4,10
        FILL_SYSTEM:
            args:
              - 3
              - volume:ml 
              - grid:1-99 
              - site:0-63
            recv:
                ok: 0
                err: 3,4,5,6
        INIT_RSP:
            args:
              - 0
            recv:
                ok: 0
                err: 3
        LIHA_PARK:
            args:
              - 1
              - lihanum
            recv:
                ok: 0
                err: 3,4,5,6
        LOAD_SCRIPT:
            args:
              - 1
              - filename
            recv:
                ok: 0
                err: 3,9,12,13
        LOAD_TEMO_SCRIPT:
            args:
              - 1
              - filename
            recv:
                ok: 0
                err: 3,4
        LOAD_WORKLIST:
            args:
              - 1
              - command
            recv:
                ok: 0
                err: 3,4,19
        LOGIN:
            args:
              - 2
              - username 
              - password:encrypted
            recv:
                ok: 0
                err: 3
        MAG_S:
            args:
              - 8
              - device:0-7 
              - action:0-5 
              - timeout:0 
              - position:0-3 
              - moveback:0-1 
              - time:1-999 
              - temperature:15-80 
              - cycles:1-99
            recv:
                ok: 0
                err: 3
        OPEN_LOGPIPE:
            args:
              - 0
            recv:
                ok: 0
                err: 3
        PAUSE_PIPETTING:
            args:
              - 0
            recv:
                ok: 0
                err: 3,11
        PNP_GRIP:
            args:
              - 4
              - distance:7-28 
              - speed:zero 
              - force:zero 
              - strategy:0-1
            recv:
                ok: 0
                err: 3,4,5,6,15
        PNP_MOVE:
            args:
              - 8
              - vectorname 
              - site:0-n 
              - position:0-n 
              - deltax:-400-400 
              - deltay:-400-400 
              - deltaz:-400-400 
              - direction:0-1 
              - xyzspeed:1-400
            recv:
                ok: 0
                err: 3,4,5,6,7,8,15
        PNP_PARK:
            args:
              - 1
              - gripcommand:0-1
            recv:
                ok: 0
                err: 3,4,5,6
        PNP_RELATIVE:
            args:
              - 4
              - deltax:-400-400 
              - deltay:-400-400 
              - deltaz:-400-400 
              - xyzspeed:1-400
            recv:
                ok: 0
                err: 3,4,5,6,15
        PREPARE_PIPETTING:
            args:
              - 0
            recv:
                ok: 0
                err: 3,9
        READ_LIQUID_CLASSES:
            args:
              - 0
            recv:
                ok: 0
                err: 2,3
        ROMA_GRIP:
            args:
              - 4
              - distance:60-140 
              - speed:0.1-150 
              - force:1-249 
              - gripcommand:0-1
            recv:
                ok: 0
                err: 3,4,5,6,15
        ROMA_MOVE:
            args:
              - 8
              - vectorname 
              - site:0-n 
              - deltax:-400-400 
              - deltay:-400-400 
              - deltaz:-400-400
              - direction:0-1 
              - xyzspeed:1-400:optional
              - rotatorspeed:1-400:optional
            recv:
                ok: 0
                err: 3,4,5,6,7,8,15
        ROMA_PARK:
            args:
              - 1
              - grippos:0-1
            recv:
                ok: 0
                err: 3,4,5,6
        ROMA_RELATIVE:
            args:
              - 4
              - deltax:-400-400 
              - deltay:-400-400 
              - deltaz:-400-400
              - xyzspeed:1-400
            recv:
                ok: 0
                err: 3,4,5,6,15
        SAVE_SCRIPT:
            args:
              - 0
            recv:
                ok: 0
                err: 3,9,13
        SHAKER:
            args:
              - 7
              - devicenum:0-7 
              - action:0-5 
              - rpm:100-1500 
              - time:1-9999 
              - direction:0-2 
              - alttime:1-999 
              - temperature:15-90
            recv:
                ok: 0
                err: 3,4,6,17
        STACKER:
            args:
              - 5
              - devicenum:0-3 
              - action:0-2 
              - stack:0-1 
              - platetype:1-25
              - scan:0-1
            recv:
                ok: 0
                err: 3,4,6
        START_PIPETTING:
            args:
              - 0
            recv:
                ok: 0
                err: 3,10
        TEMO_DROP_PLATE:
            args:
              - 3
              - grid:1-99 
              - site:0-14 
              - platetype:1-25
            recv:
                ok: 0
                err: 3,4,6
        TEMO_MOVE:
            args:
              - 2
              - site:0-14 
              - command:0-1
            recv:
                ok: 0
                err: 3,4,6,15
        TEMO_PICKUP_PLATE:
            args:
              - 3
              - grid:1-99 
              - site:0-14 
              - platetype:1-25
            recv:
                ok: 0
                err: 3,4,6
        VAC_S:
            args:
              - 7
              - devicenum:0-7 
              - action:0-9 
              - time:0-1000 
              - pressure:30-700
              - position:0-3 
              - repositionernum:1-2 
              - opentime:1-60
            recv:
                ok: 0
                err: 3,4,6,15,17,18
        WASH:
            args:
              - 14
              - volume1:ml 
              - delay1:ms 
              - volume2:ml 
              - delay2:ms 
              - grid1:1-99 
              - site1:0-63 
              - grid2:1-99 
              - site2:0-63
              - option_mpo:0-1 
              - retractspeed:1-999 
              - volumeairgap:ul 
              - speedairgap:1-999 
              - volumeopt:0-1 
              - frequency:50-5000
            recv:
                ok: 0
                err: 3,6
        CAROUSEL_SCAN_BARCODE:
            args:
              - 3
              - devicenum:0-3 
              - action:0-1 
              - towernum:1-9
            recv:
                ok: 0
                err: 3,4,6
        CAROUSEL_RETRIEVE:
            args:
              - 5
              - devicenum:0-3 
              - action:0-1 
              - barcode:optional 
              - tower:1-9 
              - position:1-27
            recv:
                ok: 0
                err: 3,4,6
        CAROUSEL_RETURN:
            args:
              - 4
              - devicenum:0-3 
              - action:0-1 
              - towernum:1-9 
              - position:1-21
            recv:
                ok: 0
                err: 3,4,6
        CAROUSEL_DIRECT_MOVEMENTS:
            args:
              - 4 
              - devicenum:0-3 
              - action:0-3 
              - towernum:1-9 
              - command
            recv:
                ok: 0
                err: 3,4,6
    recv:
        ok:
           0: ok
        error:
           1: E_command
           2: E_unexpected
           3: E_num_operands
           4: E_operand
           5: E_hw_error_reported
           6: E_hw_not_init
           7: E_roma_vector_not_defined
           8: E_roma_vector_site_not_defined
           9: E_hw_still_active
           10: E_hw_not_active
           11: E_hw_not_active
           12: E_cancelled
           13: E_script_load_save
           14: E_varible_not_defined
           15: E_requires_advanced_version
           16: E_roma_grip_fail
           17: E_device_not_found
           18: E_timeout
           19: E_worklist_already_loaded
            
type1commands:

__END__

