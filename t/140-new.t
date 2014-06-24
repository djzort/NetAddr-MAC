#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 11;

BEGIN {
  use_ok('NetAddr::MAC')
      or die "# NetAddr::MAC not available\n";
}

# just create an object
{

ok( ! $NetAddr::MAC::errstr, 'initial errstr empty before fcf8aeb721a9');
my $ret = NetAddr::MAC->new('fcf8aeb721a9');
ok( $ret, 'return value is true for fcf8aeb721a9' );
ok( ref $ret eq 'NetAddr::MAC', 'return value is a NetAddr::MAC object for fcf8aeb721a9' );
ok( ! $NetAddr::MAC::errstr, 'again errstr empty after fcf8aeb721a9');

}

# check we return errors properly
{

ok( ! $NetAddr::MAC::errstr, 'initial errstr empty before 11223344zz55');
my $ret = NetAddr::MAC->new('11223344zz55');
ok( ! $ret, 'return value is false for 11223344zz55' );
ok( $NetAddr::MAC::errstr, 'errstr populated after 11223344zz55');
like ($NetAddr::MAC::errstr,
  qr/Invalid MAC format/, 'Bad MAC character for 11223344zz55');

}

# now create again, make sure things work right
{

my $ret = NetAddr::MAC->new('742b62803518');
ok( $ret, 'return value is true for 742b62803518' );
ok( ! $NetAddr::MAC::errstr, 'errstr emptied after 742b62803518');

}


__END__

eval{NetAddr::MAC->new()};
like ($@,
  qr/please provide a mac address/i, 'Undef MAC');

eval{NetAddr::MAC->new('11:22:33:44:xx:55')};
like ($@,
  qr/Invalid MAC format/, 'Bad MAC character');

eval{NetAddr::MAC->new('1:1')};
like ($@,
  qr/Invalid MAC format/, 'Bad MAC octet');

eval{NetAddr::MAC->new('11:22:33')};
like ($@,
  qr/Invalid MAC format/, 'Short MAC');
