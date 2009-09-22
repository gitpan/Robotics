package Robotics::Tecan::Client;

use warnings;
use strict;

use Moose;

has 'SOCKET' => ( isa => 'Maybe[IO::Socket]', is => 'rw' );
has 'SERVER' => ( isa => 'Str', is => 'rw', default => 0 );
has 'PORT' => ( isa => 'Int', is => 'rw', default => 0 );
has 'PASSWORD' => ( isa => 'Str|Undef', is => 'rw', default => 0 );
has 'attached' => ( is => 'rw', isa => 'Bool' );
has 'last_reply' => ( is => 'rw', isa => 'Str' );
has 'object' => ( is => 'ro', isa => 'Robotics::Tecan' );

extends 'Robotics::Tecan', 'Robotics::Tecan::Genesis';

# This module is not meant for direct inclusion.
# Use it "with" Tecan::Genesis.

my $Debug = 1;

=head1 NAME

Robotics::Tecan::Client - (Internal module)

Software-to-Software interface for Tecan Gemini, network client.
Application for controlling robotics hardware

=head1 VERSION

Version 0.22

=cut

our $VERSION = '0.22';

=head1 SYNOPSIS

Network client software interface support for Robotics::Tecan. 
This software can connect to a network server created with 
Robotics::Tecan::Server.

=head1 EXPORT
=cut


sub BUILD {
    my ($self, $params) = @_;
    
    use IO::Socket;
    if (!$params->{port}) { 
        die "Must specify port for server ". $params->{server}. "\n"; 
    }
    my $socket = IO::Socket::INET->new( Proto     => "tcp",
                     PeerAddr  => $params->{server},
                     PeerPort  => $params->{port})
         || die "cannot connect to $params->{server}:$params->{port}\n";
    $socket->autoflush(1);
    $self->SOCKET( $socket );
    $self->SERVER( $params->{server} );
    $self->PORT( $params->{port} );
    $self->PASSWORD( $params->{password} );
    $self->attached( 0 );
    my $reply = <$socket>;
    warn "CONNECTED $params->{server}:$params->{port}\n" if $Debug;
}

sub attach {
    my ($self, %params) = @_;
    
    my $socket = $self->SOCKET;
    warn "AUTHENTICATING\n";
    my $tries = 0;
    my $reply;
    if (!$self->PASSWORD()) {
    	die "Must supply server password\n";
    }
    while ($reply = <$socket>) { 
        print STDOUT $reply;
        if ($reply =~ /^login:/) { 
            print $socket $self->PASSWORD . "\n";
        }
        if ($reply =~ /Authentication OK/i) { 
            $tries = 0;
            last;
        }
        $tries++;
        if ($tries > 3) { last; }
    }
    $self->PASSWORD( undef );
    if ($tries) { 
        $self->detach();
        warn "can not authenticate to tecan network server\n";
        return 0;
    }
    warn "ATTACHED ". __PACKAGE__. "\n";
    $self->attached( 1 );
    # Probe for Genesis
    $self->object()->{HWTYPE} = "GENESIS"; 
    $self->object()->{HWNAME} = "M1";
    
    #$self->{VERSION} = $self->hw_get_version();
    $self->write("GET_VERSION");
    $self->object()->{VERSION} = $self->read();
    print STDERR "\nVersion: ". $self->object()->{VERSION}. "\n" if $Debug;
    $self->write("GET_RSP");
    $self->object()->{HWTYPE} = $self->read();
    print STDERR "\nHardware: ". $self->object()->{HWTYPE}. "\n" if $Debug;
    if (!($self->object()->{HWTYPE} =~ /GENESIS/)) {
        $self->detach();
        warn "Robotics is not Genesis; reports '".
            $self->object()->{HWTYPE}. "': closed network\n";
        return 0;
    }
    # Force client to only attach if Robot is IDLE
    $self->write("GET_STATUS");
    $self->object()->{STATUS} = $self->read();
    print STDERR "\nStatus: ". $self->object()->{STATUS}. "\n" if $Debug;
    if (!($self->object()->{STATUS} =~ /IDLE/)) {
        warn "Robotics is not idle; reports '".
            $self->object()->{STATUS}. "'\n";
        if ($params{option} =~ !/o/i) {
            $self->detach();
            warn "closed network\n";
            return 0;
        }
    }
    
    # XXX assign this via arg to new 
    # The HWALIAS and HWNAME should be set via hardware probe, user
    # discovers value from query
    $self->{HWALIAS} = "genesis0";
    $self->{HWNAME} = "M1";

    my $m = $self->{HWNAME};
}


sub read {
    my $self = shift;
    my $data;
    my $socket = $self->{SOCKET};
    # OS/X perl 5.8.8 returns $data=undef if socket closed by server
    # cygwin-perl 5.10 returns $data="" if socket closed by server
    while ($data = <$socket>) { 
        last if !$data;
        last if $data =~ s/^<//;
    }
    # $data may be undef on socket error (OS/X perl 5.8.8)
    if ($data) { 
        print STDERR "<$data" if $Debug;
        $data =~ s/[\r\n\t\0]//go;
        $data =~ s/^\s*//go;
        $data =~ s/\s*$//go;
        $self->last_reply( $data );
        return $data;
    }
    $self->last_reply( "" );
    return "";
}

sub write { 
    my $self = shift;
    my $data = shift;
    my $socket = $self->{SOCKET};
    print $socket ">$data\n";
    print STDERR ">$data\n" if $Debug;
}
        
sub close {
    my ( $self ) = shift;
    $self->attached( 0 );
    if ($self->SOCKET()) { 
        $self->SOCKET()->close();
        $self->SOCKET( undef );
    }
        
}


=head1 FUNCTIONS

=head2 new

=head1 FUNCTIONS

=head1 AUTHOR

Jonathan Cline, C<< <jcline at ieee.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bio-robotics at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Robotics>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Robotics::Tecan::Gemini


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

1; # End of Robotics::Tecan::Client


__END__

