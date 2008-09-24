use strict;
use warnings;

package TestClass;

use MooseX::Method::Signatures;

method new (Str $foo, Int $bar = 42) {
    return bless {
        foo => $foo,
        bar => $bar,
    } => $self;
}

method foo {
    return $self->{foo};
}

method set_bar (Int $bar) {
    $self->{bar} = $bar;
}

method affe (ArrayRef | HashRef $zomtec) {
    $self->{baz} = $zomtec;
}

1;
