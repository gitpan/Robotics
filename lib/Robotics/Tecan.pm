
package Robotics::Tecan;

# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
# $Id$

use warnings;
use strict;

use Robotics::Tecan::Genesis;

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

Robotics::Tecan - Control Tecan robotics hardware as Robotics module

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';


=head1 SYNOPSIS

Easy to use software interface for Tecan robotics devices.  
Query the locally-connected hardware, attach to the hardware, use the
high level functions to send individual or multiple commands to the robotics.

NO WARRANTIES: Bugs in this software or any related software may possibly cause
physical damage to robotics hardware and/or equipment operators.  Be careful.

The following are required to communicate between Perl (or any scripting language)
and the Tecan robotics:
=over 4
Tecan requires the "Gemini" application to be running (and perhaps logged in).
The login account may require special flags set to enable third-party
communication.  The Tecan hardware may also require hardware options to enable
third-party communication (to turn on "the named pipe").  This hardware option
is referred to as a "hardware lock" (a dongle attached to the application
computer).  The "named pipe" must exist and be writable/readable to the local
user; this is outside of Perl control.  When in doubt here, verify capabilities
with Tecan support.
=back

Example:

	use Robotics;
	use Robotics::Tecan;

    $hardware = Robotics->query();  # Print available robots
    if (!($hardware =~ /Tecan/)) {
    	die "Where's the Tecan?\n";
    } 
   	my $tecan = Robotics::Tecan->new();
   	$tecan->attach();
    if (!($tecan->version =~ /Version 4.1.0.0/)) {
   		$tecan->detach();
       	die "Robot version mismatch: Exit.\n";
   	}
    $tecan->home();
    $tecan->configure("worktable.yaml");
    $tecan->pipette( ... );
    ...

=head1 EXPORT

=item *  Write
=item *  Read

=head1 FUNCTIONS

=head2 new

Allocate new object for communication to Tecan hardware.

Arguments: (optional) Object class.


Returns:  Object, or 0 if communication fails to initialize.

=cut

sub new {
    my $class = shift;
    my $self = {};

    my $connection = "local";
    my $server;
    my $serverport;
    my $serverpassword;
    while(@_) {
        my $key = shift;
        $key =~ s/^-//;
        my $value = shift;
        if ($key eq "server") { 
            my @host = split(":", $value);
            $server = shift @host;
            $serverport = shift @host;
            $connection = "remote"; 
        }
        if ($key eq "serverport") { $serverport = $value; }
        if ($key eq "password") { $serverpassword = $value; } 
    }

    if ($connection eq "local") { 
        my $incompatibility = "Win32::Pipe";
        eval "use $incompatibility;" || warn "Must have Win32::Pipe installed for local hardware connection\n";
        #use Win32::Pipe;
        no strict;

        if (!$Robotics::Tecan::PIPENAME) { 
            die "no pipe name";
        }
        # Win32::Pipe constants:
        #   timeout = in millisec
        #   flags = PIPE_TYPE_BYTE(=0x0)  
        #   state = PIPE_READMODE_BYTE(=0x0)
        $| = 1;
        my $timeout = NMPWAIT_NOWAIT;
        my $flags = 0;
        my $pipe;
        my $data;
        
        # warn "!! Opening Win32::Pipe(".$Robotics::Tecan::PIPENAME.")";
        $pipe = new Win32::Pipe($Robotics::Tecan::PIPENAME, $timeout, $flags);
        if (!$pipe) { 
            warn "cant open named-pipe $Robotics::Tecan::PIPENAME\n";
            return 0;
        }
        # warn "!! Got Win32::Pipe(), $pipe";

        if (0) {
            # test communication
            $pipe->Write("GET_VERSION\0");
            $data = $pipe->Read();
            if (!$data) { 
                # no reply
                $pipe->Close();
                warn "No response from hardware; pipe closed";
                return undef;
            }
        }

        # communication ok
        $self->{FID} = $pipe;
        $self->{ATTACHED} = undef;
    }
    elsif ($connection eq "remote") { 
        use IO::Socket;
        
        if (!$serverport) { die "Must specify port for server $server\n"; }
        my $sock = IO::Socket::INET->new( Proto     => "tcp",
                         PeerAddr  => $server,
                         PeerPort  => $serverport)
             || die "cannot connect to $server:$serverport\n";
        $sock->autoflush(1);
        $self->{SOCKET} = $sock;
        $self->{SERVER} = $server;
        $self->{SERVERPORT} = $serverport;
        $self->{SERVERPASSWORD} = $serverpassword;
        $self->{ATTACHED} = undef;
        my $reply = <$sock>;
    }

    $self->{VERSION} = undef;
    $self->{HWTYPE} = undef;
    $self->{STATUS} = undef;
    
    bless($self, $class);
    return $self;
}

=head2 _find
Internal function only.  Do not call.
=cut
sub _find {
	my %found;
	
    # Find Tecan Gemini by using Win32 API to look for running Gemini process.
    #
    #  Note: There is not much better way to find Tecan.  cygwin-perl cant
    #  access or test the named pipe at all.  If attempting to open a
    #  nonexistant pipe with Win32::Pipe and it doesn't exist, the process will
    #  hang.  So no good alternatives except to look for Gemini.exe in process
    #  list.

    # JC: Pipe name begins with \\ to assure Win32 local server context
	# Created by Tecan 'Gemini' gui app after local login

	# Win32 Incompatibility note:
	#  On Win32, the named pipe string is escaped differently running under
	#  cygwin-perl or running under cmd.exe+ActivePerl. cygwin-perl will attempt to
	#  use cygdrive paths and will fail to open the pipe. cygwin+activestate perl
	#  will succeed (because it does not use cygdrive paths?).
	#  Win32 Named Pipe "filename" format is: '\\\\SERVER/pipe/filename' 
	#       or use dot for local server '\\\\./pipe/filename' 
	#  '\\\\./pipe/gemini' or any combination does not work under cygwin+perl.
	#  '\\\\./pipe/gemini' works under cmd.exe+ActivePerl or cygwin+ActivePerl.
	if ($ENV{"PATH"} =~ m#/cygdrive/c# || $ENV{"PATH"} =~ m#Program Files#) {
	    # Found windows machine
	    if (($^X =~ m^\\Perl\\bin^i)) { 
	        # Activestate perl
	        warn "Recommend using cygwin-perl not Activestate Perl for Tecan named pipe: not tested\n";
	    }
	    else {
	        # found cygwin-perl
	    }
	    # Assume running under cygwin+ActiveState Perl or cmd.exe+ActiveState Perl
	    #  or cygwin+cygwin-perl
	    # Tested under: "This is perl, v5.10.0 built for MSWin32-x86-multi-thread"
	    # Tested under: "This is perl, v5.10.0 built for cygwin-thread-multi-64int"
	    $PIPENAME="\\\\.\\pipe\\gemini";
	}
	else {
		# not on Win32 so assume for simulation/test only
		warn "!! SIMULATION PIPE=TRUE\n";
		$PIPENAME = '/tmp/__gemini';
		unlink($PIPENAME);		# XXX: revisit this
	}

    if (-d "c:/Program Files/Tecan/Gemini") {
        # For Win32 support only
        my $incompatibility = "Win32::Process::List";
        eval "use $incompatibility";
        # -- end Win32 modules

        warn "Found Tecan Gemini, checking if running\n";
        # Found Gemini application however it may not be running.
        $found{"Tecan-Gemini"} = "not started";

        # Must search for Gemini as running process or attempting to
        # open the pipe will permanentily hang the parent process.
        # But, no way to do this in Win32.
        my $obj = Win32::Process::List->new();
        if ($obj->GetProcessPid("gemini")) { 
            $found{"Tecan-Gemini"} = "ok";
            warn "Robotics.pm: Found Tecan Gemini, App is Running\n";
        }
        else { 
            warn "Robotics.pm: Found Tecan Gemini, App is NOT RUNNING\n";
        }
	}
	# TODO Enhance this to return multiple machines with automatic names, if possible
	#$found{"Tecan-Gemini"} .= " genesis0:M1";
	
	return %found;
}

=head2 Attach

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

    if ($self->{FID}) { 
        # Notes on gemini named pipe:
        #   * must run gemini application first
        #   * user must have installed "hardware key" (parallel port dongle)
        #   * login is required(?) sometimes(?)
        #   * must terminate commands with \0   (undocumented)
        #   * input terminated by \0
        #   * Big problem: can not use F_NOBLOCK on windows with activeperl so
        #   must read char at a time and check for \0 on input
        #       * Use CPAN Win32::Pipe to avoid issues
        #   * must use binmode() for pipe to look for the \0 and act unbuffered
        #       * Use CPAN Win32::Pipe to avoid issues
        #   * if command sent is not terminated by \0, then tecan s/w will
        #    send the same buffer as before, i.e. "GET_STATUSpreviousstuff"
        #	 or other buffer garbage
        #   * commands are case-insensitive
        #   * Use the gemini app "Gemini Log" window to view cmds/answers
        #   * The variables (like Set_RomaNo) use 0-based index (0,1,..) whereas
        #       the gemini GUI uses 1-based index (1,2,..)

        $self->{ATTACHED} = 1;
        $self->Write("GET_VERSION");
        $self->{VERSION} = $self->Read() || "";
        print STDERR "\nVersion: $self->{VERSION}\n" if $Debug;
        $self->Write("GET_RSP");
        $self->{HWTYPE} = $self->Read() || "";
        print STDERR "\nHardware: $self->{HWTYPE}\n" if $Debug;

        if (!($self->{HWTYPE} =~ /GENESIS/i)) {
            $self->detach();
            warn "Robotics is not Genesis; reports '$self->{HWTYPE}': closed named-pipe\n";
            return 0;
        }

        # XXX assign this via arg to new, user discovers value from query
        # The HWALIAS and HWNAME should be set via hardware probe, user
        # discovers value from query
        $self->{HWALIAS} = "genesis0";
        $self->{HWNAME} = "M1";

        my $m = $self->{HWNAME};
        # Scan and get hardware device specifics
        # no. arms, diluters, options, posids, 
        # romas, uniports, options, voptions
        my $d;
        for $d (0 .. 7) { 
            $self->Write($m."RDS".$d.",1");
            $self->{HWSPEC} .= $self->Read();
        }
        print STDERR "\nHW Spec: $self->{HWSPEC}\n" if $Debug;

        # Scan and Get hardware options (optional i/o board)
        # "maximum two different devices accessible" using RRS
        $self->Write($m."ARS");  # SCAN
        $self->Read();
        for $d (1 .. 2) { 
            $self->Write($m."RRS".$d); # Report device on chN
            $self->{HWOPTION} .= $self->Read();
        }
        print STDERR "\nHW Options: $self->{HWOPTION}\n" if $Debug;


    }
    elsif ($self->{SERVER}) { 
        my $socket = $self->{SOCKET};
        warn "AUTHENTICATING\n";
        my $tries = 0;
        my $reply;
        if (!$self->{SERVERPASSWORD}) {
        	die "Must supply server password\n";
        }
        while ($reply = <$socket>) { 
            print STDOUT $reply;
            if ($reply =~ /^login:/) { 
                print $socket $self->{SERVERPASSWORD} . "\n";
            }
            if ($reply =~ /Authentication OK/i) { 
                $tries = 0;
                last;
            }
            $tries++;
            if ($tries > 3) { last; }
        }
        if ($tries) { 
            $self->detach();
            warn "can not authenticate to tecan network server\n";
            return 0;
        }
        $self->{SERVERPASSWORD} = undef;
        
        warn "ATTACHED\n";
        $self->{ATTACHED} = 1;
        $self->Write("GET_VERSION");
        $self->{VERSION} = $self->Read();
        print STDERR "\nVersion: $self->{VERSION}\n" if $Debug;
        $self->Write("GET_RSP");
        $self->{HWTYPE} = $self->Read();
        print STDERR "\nHardware: $self->{HWTYPE}\n" if $Debug;
        if (!($self->{HWTYPE} =~ /GENESIS/)) {
            $self->detach();
            warn "Robotics is not Genesis; reports '$self->{HWTYPE}': closed network\n";
            return 0;
        }
        # Force client to only attach if Robot is IDLE
        $self->Write("GET_STATUS");
        $self->{STATUS} = $self->Read();
        print STDERR "\nStatus: $self->{STATUS}\n" if $Debug;
        if (!($self->{STATUS} =~ /IDLE/)) {
            warn "Robotics is not idle; reports '$self->{STATUS}'\n";
            if ($flags =~ !/o/i) {
                $self->detach();
                warn "closed network\n";
                return 0;
            }
        }
        
        # XXX assign this via arg to new, user discovers value from query
        # The HWALIAS and HWNAME should be set via hardware probe, user
        # discovers value from query
        $self->{HWALIAS} = "genesis0";
        $self->{HWNAME} = "M1";

        my $m = $self->{HWNAME};
    }

    return $self->{VERSION};

}


=head2 startService

=item (Special method - Not normally used - Experimental)

Attempt to start the Windows GUI application associated with Tecan (such as
running "Gemini.exe").  Since this will occur under Win32, and there is no 
mechanism for forking, this call will likely never return.  Best not to
call this method if the Tecan application is already running: unexpected
Win32 results may occur.

This method should only be used when "Desktop" access to start the Tecan
application is unavailable (such as starting the service from a remote
machine over the network).  

Usage, for Tecan: 
Do query() first, to see if the robotics is "not started"; if it is not, use
this function to start Gemini, then query() again (the second time should find
the named pipe).


=cut

sub startService {
    my $incompatibility = "Win32::Process";
    eval "use $incompatibility";

    my $exe = 'c:\\Program Files\\Tecan\\Gemini\\Gemini.exe';
    # Experimental code follows

    my $obj;
    if (0) { 
        # This doesnt seem to work in winxp test
        Win32::Process::Create($obj,
                                $exe,
                                "",
                                0,
                                NORMAL_PRIORITY_CLASS,
                                ".")|| die "Win32 process error with $exe\n";
    }
    return $obj;
}


=head2 server

Start network server.  The server provides network access to the
locally-attached robotics.

=cut

sub server {
    my($self) = shift;
    use IO::Socket;
    use Net::hostent;

    my $password = shift || die "must supply password with server()\n";
    my $port = shift || 8088;

    my $server = IO::Socket::INET->new( Proto     => 'tcp',
                                  LocalPort => $port,
                                  Listen    => SOMAXCONN,
                                  Reuse     => 1);
    die "cant open network on port $port" unless $server;

    my $client;
    my $hostinfo;
    my $cdata;
    print STDERR "Robotics::Tecan network server is ready on port $port.\n";
    while ($client = $server->accept()) {
        $client->autoflush(1);
        print $client "Welcome to $0\n";
        $hostinfo = gethostbyaddr($client->peeraddr);
        printf STDERR "\tConnect from %s on port $port\n",
            $hostinfo ? $hostinfo->name : $client->peerhost;

        # Cheap authentication
        print $client "login:\n";
        while ($cdata = <$client>) {
            $cdata =~ s/\n\r\t\s//g;
            last if ($cdata =~ /^$password\b/);
            print $client "login:\n";
            print STDOUT "\t\t$cdata\n";
        }
        print $client "Authentication OK\n";
        printf STDERR "\tAuthenticated %s on port $port\n",
            $hostinfo ? $hostinfo->name : $client->peerhost;

        # Run commands
        my $result;
        while (<$client>) {
            next unless /\S/;       # blank line
            last if /end/oi;
            s/[\r\n\t\0]//g;
            s/^[\s\>]*//g;
            print STDERR "\t\t$_\n";
            $self->Write($_);
            $result = $self->Read();
            print STDERR "\t\t\t$result\n";
            print $client "\n$_\n<$result" . "\n";
        }
        printf STDERR "\tDisconnect %s\n",
            $hostinfo ? $hostinfo->name : $client->peerhost;
        close $client;
        print STDERR "Robotics::Tecan network server is ready on port $port.\n";
    }
    close $server;

	return 1;
}

=head2 detach

End communication to the hardware.

=cut

sub detach {
    my($self) = shift;
    $self->{ATTACHED} = 0;
    if ($self->{FID}) { 
        $self->{FID}->Close();
    }
    elsif ($self->{SERVER}) { 
        $self->{SOCKET}->close();
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
	$self->Write("GET_RSP");
	$reply = $self->Read();
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
    my $infile = shift || return 1;
	
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
	
	$self->Write("#".$self->{HWNAME}."PIS");
	return $reply = $self->Read();
}


=head2 initialize_full

Fully initialize hardware for movement (perhaps running calibration).  
Return status string.
May take time to complete.

=cut

sub initialize_full {
    my $self = shift;
	my $reply;
	$self->Write("INIT_RSP");
	return $reply = $self->Read();
}




=head2 simulate_enable

Robotics::Tecan internal hook for simulation and test.  Not normally used.

=cut

sub simulate_enable {
	# Modify internals to do simulation instead of real communication
	$Robotics::Tecan::PIPENAME = '/tmp/gemini';
}

=head2 Write

Low level function to write commands to hardware.

=cut

sub Write {
    my $self = shift;
	if ($self->{ATTACHED}) { 
        my $data = shift;
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
	else {
		warn "! attempted Write when not Attached\n";
		return "";
	}
}


=head2 WriteFirmware

Low level function to write commands to hardware's firmware.

=item WARNING - Some firmware commands are dangerous to the equipment - 
No error checking is performed by this function - user beware.

Argument:  string command.

=cut

sub WriteFirmware {
    my $self = shift;
    return $self->Write("COMMAND;" . shift);
}

=head2 Read

Low level function to read commands from hardware.

=cut
sub Read {
    my $self = shift;
	if ($self->{ATTACHED}) { 
        my $data;
        if ($self->{FID}) {
            my $byte;
            my $count;
            do { $byte = $self->{FID}->Read(); $data .= $byte if $byte; $count++; } 
                while ($byte && !($byte =~ m/\0/) && $count < 100);
            while (0) {  # XXX
                $byte = $self->{FID}->Read();
                last if $byte && $byte eq '\0';
                $count++;
                last if $count > 500;
                # sometimes undef is returned for $byte (blame Win32::Pipe)
                if ($byte) { $data .= $byte; }
            }
        }
        elsif ($self->{SERVER}) {
            my $socket = $self->{SOCKET};
            # OS/X perl 5.8.8 returns $data=undef if socket closed by server
            # cygwin-perl 5.10 returns $data="" if socket closed by server
            while ($data = <$socket>) { 
                last if !$data;
                last if $data =~ s/^<//;
            }
        }
        else { 
            die "notreached";
        }
        # $data may be undef on socket error (OS/X perl 5.8.8)
        if ($data) { 
            print STDERR "<$data" if $Debug;
            $data =~ s/[\r\n\t\0]//go;
            $data =~ s/^\s*//go;
            $data =~ s/\s*$//go;
            return $data;
        }
        else {
            return "";
        }
	}
	else {
		warn "! attempted Read when not Attached\n";
		return "";
	}
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

