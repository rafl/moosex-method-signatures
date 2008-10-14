use strict;
use warnings;

package TestClass;

use Moose;
use MooseX::Method::Signatures;

method new ($class: Str $foo, Int $bar = 42
                              where { $_ % 2 == 0 }
                              where { $_ > 10     }) {
    return bless {
        foo => $foo,
        bar => $bar,
    } => $class;
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

method named (:$optional, :$required!) {
    return ($optional, $required);
}

method combined ($a, $b, $c?, :$optional, :$required!) {
    return ($a, $b, $c, $optional, $required);
}

no Moose;

1;
