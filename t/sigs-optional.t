use strict;
use warnings;
use Test::More tests => 2;

{
    package Optional;
    use MooseX::Method::Signatures;
    method foo ($class: $arg?) {
        $arg;
    }
}

is( Optional->foo(), undef);
is( Optional->foo(1), 1);
