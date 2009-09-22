
package Robotics::Tecan::Genesis::Compiler;

#
# Tecan Genesis
# Compiler to generate hardware commands
#

use warnings;
use strict;

use YAML::XS;
use Moose::Role;


=head2 All Functions

Internal functions.  Data communications for this hardware.

Returns 0 on error, status string if OK.

=over 4

=item Tecan Genesis + Gemini software has (for the purposes of this module's design)
the following heirarchy of data communication:

=over 4

=item Gemini worklist commands (like: "A;...  D;...").
Not described in documentation.

=item Gemini *.gem script commands (like: "Aspirate(..)").
Not described in documentation.  Reverse engineer from the *.gem files.

=item Gemini script commands (like: "B;Aspirate(...)")

=item Gemini named pipe commands.  
Described in the thin documentation of "gem_pipe.pdf"

=item Low level single commands (like: "M1PIS").  
This is the raw robotics firmware command.
Described in the thin documentation of "gemfrm.hlp".
Sent through named pipe prefaced with "COMMAND;"

=back

Only the named pipe commands and low level single commands 
can be sent through the named pipe to control the robotics.  To run
the script commands, a dummy script file must be written to disk, and a pipe
command can be sent to execute the script file (like a bootstrap method).
Worklist commands can be executed using a double-bootstrap; to 
provide status of command completion, use the execute command to
run an external semaphore program to track script status.

Design note: To distinguish between command types, 
they are called 'type1' (firmware commands, single instruction) 
and 'type2' (multiple arguments with semicolon) in this code.

=back

=cut

my $Debug = 1;

sub compile1 {
	my $self    = shift;

    # "single commands" (Firmware commands)
    my $cmd = shift;
    
    
    #
    # TODO  write compiler for single commands
    #
    
    # Prepend 'COMMAND;'
    #my $command = $self->compile(@_);
    $cmd = "COMMAND;". $cmd;
    
    return ($cmd);
}

sub compile {
	my $self    = shift;
    
    # Process Pipe commands    
    my $cmd = shift;
    my %userdata = @_;
    
    # Look up the command
    my $cmdsref = $Robotics::Tecan::Genesis::comm_ydata->{"type2commands"};
    my $cmdref = $cmdsref->{"send"}->{$cmd};
    if (!$cmdref) {
        warn "no cmdref for $cmd  => Sending dummy command GET_STATUS";
        $cmdref = $cmdsref->{"send"}->{"GET_STATUS"};
    }
    
    # Get the params & param names for the command
    # Perform argument matching and some checking
    my @validargs = @{$cmdref->{"args"}};
    shift @validargs;
    print "\n$cmd ". join(" "). " => args: ".join("  ", @validargs). "\n" if $Debug;
    my @output = ( $cmd );
    my $arg;
    for $arg (@validargs) {
        my ($pname, $ptype, $flags) = split(":", $arg);
        if (!$flags) { $flags = ""; }
        if (defined $ptype) {
            if ($ptype eq "zero") {
                # This param is always zero regardless of passed value
                push(@output, "0");
                next;
            }
            if (($ptype =~ /optional/ || $flags =~ /optional/)
                    && $userdata{$pname} == 0) { 
                # user specified zero for optional value so omit it (see docs)
                #push(@output, "");
                next;
            }
            if ($ptype =~ m/([-]?\d+)-(\d+)/) {
                # Range, so do boundary check 
                my $min = $1;
                my $max = $2;
                if ($userdata{$pname} >= $min && $userdata{$pname} <= $max) { 
                    push(@output, $userdata{$pname});
                    next;
                }
                else {
                    warn "improper user value $userdata{$pname} in $cmd ".join(" ", @_). 
                            " => sending dummy command GET_STATUS\n";
                    return $self->compile("GET_STATUS");
                }
                warn "notreached";
            }
            if ($ptype =~ m/([-]?\d+)-n/) {
                # Range, so do boundary check; assume max value (not in docs)
                my $min = $1;
                my $max = 255;
                if ($userdata{$pname} >= $min && $userdata{$pname} <= $max) { 
                    push(@output, $userdata{$pname});
                    next;
                }
                else {
                    warn "improper user value $userdata{$pname} in $cmd ".join(" ", @_). 
                            " => sending dummy command GET_STATUS\n";
                    return $self->compile("GET_STATUS");
                }
                warn "notreached";
            }
            # TODO Add unit conversion here to change user-given "1ml" to "1000ul"
            #  if ptype specifies different native units for hardware
            #    - won't that be cool.
        }
        if (defined $userdata{$pname}) { 
            # User set this parameter to user value
            push(@output, $userdata{$pname});
        }
        else {
            # Unspecified argument; use zero
            # TODO Add state here to set defaults of named params
            push(@output, "0");
        }
    }
    
    # Join output parms with ';' to form pipe command
    my $data = join(";", @output);

    # Output Pipe commands    
    if (0 && $data) {
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
        else {
            warn "not reached";
        }
    }
    
    # Save state for the expected reply
    $self->{EXPECT_RECV} = $self->{comm_ydata}->{"layer2"}->{"send"}->{$cmd}->{"recv"};

    return $data;
}

1;    # End of Robotics::Tecan::Genesis::Compiler


__END__

