#!/usr/bin/perl

use warnings;
use strict;
use Module::Build;
my $build = Module::Build->new(
    dist_name => q|NetAddr-MAC|,
    dist_author => q|Dean Hamstead <dean@fragfest.com.au>|,
    license => q|perl|,
    module_name => q|NetAddr::MAC|,
    requires    => {
        Carp       => 0,
        'List::Util' => 0,
    },
    build_requires => {
        'Test::Trap' => 0,
    },
);
$build->create_build_script();
