use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;

use MooseX::Method::Signatures;

my $o = bless {} => 'Foo';

my $meth = method ($, $, $foo, $, $bar, $) {
    return $foo . $bar;
};
isa_ok($meth, 'Moose::Meta::Method');

dies_ok(sub {
    $meth->($o, 1, 2, 3, 4, 5);
});

lives_and(sub {
    is($meth->($o, 1, 2, 3, 4, 5, 6), 35);
});

1;
