use strict;
use warnings;
use Test::More tests => 4;

use MooseX::Method::Signatures;

my @methods = (method { 1 }, method { 2 }, method { 3 });
is(scalar @methods, 3);

isa_ok($_, 'Moose::Meta::Method') for @methods;
