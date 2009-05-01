use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;

use MooseX::Method::Signatures;

my $o = bless {} => 'Foo';

{
    my $meth = method ([$x, $y]) {
        return "${x}-${y}";
    };

    lives_and(sub {
        is($meth->($o, [42, 23]), '42-23');
    });
}
