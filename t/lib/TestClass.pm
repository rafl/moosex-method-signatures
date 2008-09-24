use strict;
use warnings;

package TestClass;

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

# p6::signatures bug
#method affe (ArrayRef | HashRef $zomtec) {
method affe (ArrayRef $zomtec) {
    $self->{baz} = $zomtec;
}

method positional (:$optional, :$required!) { }

method combined ($a, $b, $c?, :$optional, :$required!) { }

1;
