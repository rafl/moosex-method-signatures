use strict;
use warnings;
use Test::More tests => 4;

{
    package Optional;
    use MooseX::Method::Signatures;
    method foo ($class: $arg?) {
        $arg;
    }

    method bar ($class: $hr = {}) {
        ++$hr->{bar};
    }
}

is( Optional->foo(), undef);
is( Optional->foo(1), 1);
is( Optional->bar(), 1);
is( Optional->bar({bar=>1}), 2);
