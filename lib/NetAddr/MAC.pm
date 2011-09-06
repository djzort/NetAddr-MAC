#!/usr/bin/perl

package NetAddr::MAC;
use strict;

use Carp qw(croak);

use List::Util qw( first );

use constant EUI48LENGTHHEX => 12;
use constant EUI48LENGTHDEC => 6;
use constant EUI64LENGTHHEX => 16;
use constant EUI64LENGTHDEC => 8;

use base qw( Exporter );
use vars qw( $VERSION %EXPORT_TAGS @EXPORT_OK );
$VERSION = (qw$Revision: 0.71 $)[1];

%EXPORT_TAGS = (
    all => [
        qw(
          mac_is_eui48     mac_is_eui64
          mac_is_unicast   mac_is_multicast
          mac_is_local     mac_is_universal
          mac_as_basic     mac_as_sun
          mac_as_microsoft mac_as_cisco
          mac_as_bpr       mac_as_ieee
          mac_as_ipv6_suffix
        )
    ],
    properties => [
    	qw(
          mac_is_eui48     mac_is_eui64
          mac_is_unicast   mac_is_multicast
          mac_is_local     mac_is_universal
    	)
    ],
    normals => [
    	qw(
          mac_as_basic     mac_as_sun
          mac_as_microsoft mac_as_cisco
          mac_as_bpr       mac_as_ieee
          mac_as_ipv6_suffix
        )
    ],
);

Exporter::export_ok_tags( keys %EXPORT_TAGS );

=head1 NAME

OIE::Utils::MAC - Handles hardware MAC Addresses (EUI-48 and EUI-64)

=head1 SYNOPSIS

    use OIE::Utils::MAC;

    my $mac = OIE::Utils::MAC->new( '00:11:22:aa:bb:cc' );
    my $mac = OIE::Utils::MAC->new( mac => '0011.22AA.BBCC' );

    print "MAC provided at object creation was: ", $mac->original;

    print "EUI48\n" if $mac->is_eui48;
    print "EUI64\n" if $mac->is_eui64;

    print "Unicast\n" if $mac->is_unicast;
    print "Multicast\n" if $mac->is_multicast;

    print "Locally Administerd\n" if $mac->is_local;
    print "Universally Administered\n" if $mac->is_universal;

    print 'Basic Format: ',$mac->as_basic,"\n";
    print 'Bpr Format: ',$mac->as_bpr,"\n";
    print 'Cisco Format: '$mac->as_cisco,"\n";
    print 'IEEE Format: '$mac->as_ieee,"\n";
    print 'Microsoft Format: ',$mac->as_microsoft,"\n";
    print 'Sun Format: ',$mac->as_sun,"\n";


    use OIE::Utils::MAC qw( :all );

    my $mac = q/00.11.22.33.44.55/;

    print "EUI48\n" if mac_is_eui48($mac);
    print "EUI64\n" if mac_is_eui64($mac);

    print "Unicast\n" if mac_is_unicast($mac);
    print "Multicast\n" if mac_is_multicast($mac);

    print "Locally Administerd\n" if mac_is_local($mac);
    print "Universally Administered\n" if mac_is_universal($mac);

    print 'Basic Format: ',mac_as_basic($mac),"\n";
    print 'Bpr Format: ',mac_as_bpr($mac),"\n";
    print 'Cisco Format: 'mac_as_cisco($mac),"\n";
    print 'IEEE Format: 'mac_as_ieee($mac),"\n";
    print 'Microsoft Format: ',mac_as_microsoft($mac),"\n";
    print 'Sun Format: ',mac_as_sun($mac),"\n";

=head1 DESCRIPTION

This module provides an interface to deal with Media Access Control (or MAC)
addresses.  These are the addresses that uniquely identify a device on a
layer 2 network.  Although the common case is hardware addresses on Ethernet
network cards, there are a variety of devices that use this system.
This module supports both EUI-48 and EUI-64 addresses and implements an
OO and a functional interface.

Some devices that use EUI-48 (or MAC-48) addresses include:

    Ethernet
    802.11 wireless networks
    Bluetooth
    IEEE 802.5 token ring
    FDDI
    ATM

Some devices that use EUI-64 addresses include:

    Firewire
    IPv6
    ZigBee / 802.15.4 wireless personal-area networks

=head1 OO METHODS

=head2 OIE::Utils::MAC->new( mac => $mac )

Creates and returns a new OIE::Utils::MAC object.  The MAC value is required.

=head2 OIE::Utils::MAC->new( $mac )

Simplified creation method

=cut

sub new {

    my ( $p, @a ) = @_;
    my $c = ref($p) || $p;
    my $self = bless {}, $c;

    croak q|Please provide a mac address|
        unless @a;

    # massage a single argument into a mac argument if needed
    $self->_init( @a == 1 ? ( mac => shift @a ) : @a );

    return $self;

}

sub _init {

    my ( $self, %args ) = @_;

    $self->{mac}      = _mac_to_integers( $args{mac} );
    $self->{original} = $args{mac};

    return;

}

sub _mac_to_integers {

    my $mac = shift || return;

    $mac =~ s{^1,\d,}{}; # blindly remove the prefix from bpr, we could check that \d is the actual length, but oh well

    my @parts = grep { length } split( /[^a-z0-9]+/ix, $mac );

    croak "Invalid MAC format '$mac'"
        if first {m{[^a-f0-9]}i} @parts;

    # 12 characters for EUI-48, 16 for EUI-64
    if ( @parts == 1 &&
        (   length $parts[0] == EUI48LENGTHHEX
            || length $parts[0] == EUI64LENGTHHEX ) )
        {    # 0019e3010e72
            local $_ = shift(@parts);
            while (m{([a-f0-9]{2})}igx) { push( @parts, $1 ) }
            return [ map { hex } @parts ];
    }

    # 00:19:e3:01:0e:72
    if ( @parts == EUI48LENGTHDEC || @parts == EUI64LENGTHDEC )
    {
        return [ map { hex } @parts ];
    }

    # 0019:e301:0e72
    if ( @parts == EUI48LENGTHDEC / 2 || @parts == EUI64LENGTHDEC / 2 )
    {
        return [
            map { m{^ ([a-f0-9]{2}) ([a-f0-9]{2}) $}ix && ( hex($1), hex($2) ) }
              @parts
        ];
    }

    croak "Invalid MAC format '$mac'";

    return;
}

=head1 OO METHODS

=head2 original

returns the original B<mac> string as used when creating the MAC object

=cut

sub original {

    my $self = shift;
    return $self->{original};

}

=head1 OO PROPERTY METHODS

=head2 is_eui48

returns true if mac address is determined to be of the EUI48 standard

=cut

sub is_eui48 {
    my $self = shift;
    return scalar @{ $self->{mac} } == EUI48LENGTHDEC;
}

=head2 is_eui64

returns true if mac address is determined to be of the EUI64 standard

=cut

sub is_eui64 {
    my $self = shift;
    return scalar @{ $self->{mac} } == EUI64LENGTHDEC;
}

=head2 is_multicast

returns true if mac address is determined to be a multicast address

=cut

sub is_multicast {
    my $self = shift;
    return $self->{mac}->[0] & 1;
}

=head2 is_unicast

returns true if mac address is determined to be a unicast address

=cut

sub is_unicast {
    my $self = shift;
    return !is_multicast($self);
}

=head2 is_local

returns true if mac address is determined to be locally administered

=cut

sub is_local {
    my $self = shift;
    return $self->{mac}->[0] & 2;
}

=head2 is_universal

returns true if mac address is determined to be universally administered

=cut

sub is_universal {
    my $self = shift;

    return ! is_local($self);
}

=head1 OO NORMALIZATION METHODS

=head2 as_basic

returns the mac address normalized as a hexidecimal string that is 0 padded and without delimiters

 001122aabbcc

=cut

sub as_basic {
    my $self = shift;
    return join( q{}, map { sprintf( '%02x', $_ ) } @{ $self->{mac} } );
}

=head2 as_bpr

returns the mac address normalized as a hexidecimal string that is 0 padded with B<:> delimiters and with
B<1,length> leading where I<length> is the number of hex pairs (ie 6 for EUI48)

 1,6,00:11:22:aa:bb:cc

=cut

sub as_bpr {
    my $self = shift;
    return q{1,} . scalar @{$self->{mac}} . q{,} . join( q{:}, map { sprintf( '%02x', $_ ) } @{ $self->{mac} } );
}


=head2 as_cisco

returns the mac address normalized as a hexidecimal string that is 0 padded and with B<.> delimiting every 2nd octet
(ie after every 4th character)

 0011.22aa.bbcc

=cut

sub as_cisco {
    my $self = shift;
    return join( q{.},
        map { m{([a-f0-9]{4})}gxi }
          join( q{}, map { sprintf( '%02x', $_ ) } @{ $self->{mac} } ) );
}

=head2 as_ieee

returns the mac address normalized as a hexidecimal string that is 0 padded and with B<-> delimiting every octet
(ie after every 2nd character)

 00-34-56-78-9a-bc

=cut

sub as_ieee {
    my $self = shift;
    return join( q{-}, map { sprintf( '%02x', $_ ) } @{ $self->{mac} } );
}

=head2 as_ipv6_suffix

returns the EUI-64 address in the format used for an IPv6 autoconf address suffix

=cut

sub as_ipv6_suffix {

    my $self = shift;
    my @tmpmac;

    # be slightly evil here, so that hashrefs and objects work
    if (is_eui48($self)) {
       # save this for later
       @tmpmac = @{ $self->{mac} };

       to_eui64($self);

    }

    my @suffix = (
        @{ $self->{mac} }[0] ^ 0x02,
        @{ $self->{mac} }[1..7]
    );

    # restore the eui48 if needed
    $self->{mac} = \@tmpmac if @tmpmac;

    return join( q{:}, map { my $i = $_; $i *= 2; sprintf( '%02x%02x', $suffix[$i], $suffix[$i + 1]) } 0 .. 3 );
}

=head2 as_microsoft

returns the mac address normalized as a hexidecimal string that is 0 padded and with B<:> delimiting every octet
(ie after every 2nd character)

 00:34:56:78:9a:bc

=cut

sub as_microsoft {
    my $self = shift;
    return join( q{:}, map { sprintf( '%02x', $_ ) } @{ $self->{mac} } );
}

=head2 as_sun

returns the mac address normalized as a hexidecimal string that is B<not> padded and with B<-> delimiting every octet
(ie after every 2nd character)

 0-34-56-78-9a-bc

=cut

sub as_sun {
    my $self = shift;
    return join( q{-}, map { sprintf( '%01x', $_ ) } @{ $self->{mac} } );
}

=head2 as_tokenring

returns the mac address normalized as a hexidecimal string that is 0 padded and with B<-> delimiting every octet
(ie after every 2nd character) and each octect is bit-reversed order

 00-2d-6a-1e-59-3d

=cut

sub as_tokenring {
    croak 'not yet implemented';

    # my $self = shift;
    # return join( q{-}, map { sprintf( '%01x', $_ ) } @{ $self->{mac} } );
}

=head2 to_eui48

converts to EUI-48 (if the eui-64 was derived from eui-48)

=cut

sub to_eui48 {

    my $self = shift;

    # be slightly evil here, so that hashrefs and objects work
    if (is_eui64($self)) {
        if (@{ $self->{mac} }[3] == 0xff and (@{ $self->{mac} }[4] == 0xff or @{ $self->{mac} }[4] == 0xfe)) {
            # convert to eui-48
            $self->{mac} = [ @{ $self->{mac} }[0..2,5..7] ];
        } else {
            croak 'eui-64 address is not derived from an eui-48 address';
        }
    }

    return 1
}

=head2 to_eui64

converts to EUI-64

=cut

sub to_eui64 {

    my $self = shift;

    # be slightly evil here so that hashrefs and objects work
    if (is_eui48($self)) {
        # convert to eui-64
        $self->{mac} = [
            @{ $self->{mac} }[0..2],
            0xff, 0xfe,
            @{ $self->{mac} }[3..5]
        ];
    }

    return 1
}

=head1 STAND ALONE PROPERTY FUNCTIONS

=head2 mac_is_eui48($mac)

returns true if mac address in $mac is determined to be of the EUI48 standard

=cut

sub mac_is_eui48 {

    my $mac = shift;
    croak 'please use is_eui48'
      if ref $mac eq __PACKAGE__;
    croak 'argument must be a string' if ref $mac;

    return is_eui48( { mac => _mac_to_integers($mac) } )

}

=head2 mac_is_eui64($mac)

returns true if mac address in $mac is determined to be of the EUI64 standard

=cut

sub mac_is_eui64 {

    my $mac = shift;
    croak 'please use is_eui64'
      if ref $mac eq __PACKAGE__;
    croak 'argument must be a string' if ref $mac;

    return is_eui64( { mac => _mac_to_integers($mac) } )

}

=head2 mac_is_multicast($mac)

returns true if mac address in $mac is determined to be a multicast address

=cut

sub mac_is_multicast {

    my $mac = shift;
    croak 'please use is_multicast'
      if ref $mac eq __PACKAGE__;
    croak 'argument must be a string' if ref $mac;

    return is_multicast( { mac => _mac_to_integers($mac) } )

}

=head2 mac_is_unicast($mac)

returns true if mac address in $mac is determined to be a unicast address

=cut

sub mac_is_unicast {

    my $mac = shift;
    croak 'please use is_unicast'
      if ref $mac eq __PACKAGE__;
    croak 'argument must be a string' if ref $mac;

    return is_unicast( { mac => _mac_to_integers($mac) } )

}

=head2 mac_is_local($mac)

returns true if mac address in $mac is determined to be locally administered

=cut

sub mac_is_local {

    my $mac = shift;
    croak 'please use is_local'
      if ref $mac eq __PACKAGE__;
    croak 'argument must be a string' if ref $mac;

    return is_local( { mac => _mac_to_integers($mac) } )

}

=head2 mac_is_universal($mac)

returns true if mac address in $mac is determined to be universally administered

=cut

sub mac_is_universal {

    my $mac = shift;
    croak 'please use is_universal'
      if ref $mac eq __PACKAGE__;
    croak 'argument must be a string' if ref $mac;

    return is_universal( { mac => _mac_to_integers($mac) } )

}

=head1 STAND ALONE NORMALIZATION METHODS

=head2 mac_as_basic($mac)

returns the mac address in $mac normalized as a hexidecimal string that is 0 padded and without delimiters

 001122aabbcc

=cut

sub mac_as_basic {

    my $mac = shift;
    croak 'please use as_basic'
      if ref $mac eq __PACKAGE__;
    croak 'argument must be a string' if ref $mac;

    return as_basic( { mac => _mac_to_integers($mac) } )

}

=head2 mac_as_bpr($mac)

returns the mac address in $mac normalized as a hexidecimal string that is 0 padded, with B<:> delimiting and
B<1,length> leading. I<length> is the number of hex pairs (6 for EUI48)

 1,6,00:11:22:aa:bb:cc

=cut

sub mac_as_bpr {

    my $mac = shift;
    croak 'please use as_basic'
      if ref $mac eq __PACKAGE__;
    croak 'argument must be a string' if ref $mac;

    return as_bpr( { mac => _mac_to_integers($mac) } )

}


=head2 mac_as_cisco($mac)

returns the mac address in $mac normalized as a hexidecimal string that is 0 padded and with B<.> delimiting every 2nd octet
(ie after every 4th character)

 0011.22aa.bbcc

=cut

sub mac_as_cisco {

    my $mac = shift;
    croak 'please use as_cisco'
      if ref $mac eq __PACKAGE__;
    croak 'argument must be a string' if ref $mac;

    return as_cisco( { mac => _mac_to_integers($mac) } )

}

=head2 mac_as_ieee($mac)

returns the mac address in $mac normalized as a hexidecimal string that is 0 padded and with B<-> delimiting every octet
(ie after every 2nd character)

 00-34-56-78-9a-bc

=cut

sub mac_as_ieee {

    my $mac = shift;
    croak 'please use as_ieee'
      if ref $mac eq __PACKAGE__;
    croak 'argument must be a string' if ref $mac;

    return as_ieee( { mac => _mac_to_integers($mac) } )

}

=head2 mac_as_ipv6_suffix($mac)

returns the mac address in $mac in the format used for an IPv6 autoconf address suffix

will convert from eui48 or eui64 if needed

=cut

sub mac_as_ipv6_suffix {

    my $mac = shift;
    croak 'please use as_ipv6_suffix'
      if ref $mac eq __PACKAGE__;
    croak 'argument must be a string' if ref $mac;

    return as_ipv6_suffix( { mac => _mac_to_integers($mac) } )

}

=head2 mac_as_microsoft($mac)

returns the mac address in $mac normalized as a hexidecimal string that is 0 padded and with B<:> delimiting every octet
(ie after every 2nd character)

 00:34:56:78:9a:bc

=cut

sub mac_as_microsoft {

    my $mac = shift;

    croak 'please use as_microsoft'
      if ref $mac eq __PACKAGE__;
    croak 'argument must be a string' if ref $mac;

    return as_microsoft( { mac => _mac_to_integers($mac) } )

}

=head2 mac_as_sun($mac)

returns the mac address in $mac normalized as a hexidecimal string that is B<not> padded and with B<-> delimiting every octet
(ie after every 2nd character)

 0-34-56-78-9a-bc

=cut

sub mac_as_sun {

    my $mac = shift;

    croak 'please use as_sun'
      if ref $mac eq __PACKAGE__;
    croak 'argument must be a string' if ref $mac;

    return as_sun( { mac => _mac_to_integers($mac) } )

}

=head2 mac_as_tokenring($mac)

returns the mac address in $mac normalized as a hexidecimal string that is 0 padded and with B<-> delimiting every octet
(ie after every 2nd character) and each octect is bit-reversed order

 00-2d-6a-1e-59-3d

=cut

sub mac_as_tokenring {

    croak 'not yet implemented';

}

=head1 CREDITS

Stolen lots of ideas and some pod content from L<Device::MAC> and L<Net::MAC> 

=head1 TODO

 - tests!
 - as_tokenring - need to find a nifty way to reverse the bit order

=head1 AUTHOR

Dean Hamstead C<< <dean.hamstead@optusnet.com.au> >>

=cut

1;
