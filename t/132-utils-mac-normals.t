use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok('NetAddr::MAC', qw( :normals ))
		or die "# NetAddr::MAC not available\n";
}


## more stuff needed here
