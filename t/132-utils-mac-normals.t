#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;
use Test::Trap;

BEGIN {
	use_ok('NetAddr::MAC', qw( :normals ))
		or die "# NetAddr::MAC not available\n";
}

