use strict;
use warnings;

package TestClass;

use Moose;
use MooseX::Method::Signatures;
use Moose::Util::TypeConstraints;

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


method callstack_inner (ClassName $class:) {
    return Carp::longmess("Callstack is");
}

method callstack (ClassName $class:) {
    return $class->callstack_inner;
}

BEGIN {
    class_type 'MyType';

    coerce 'MyType',
        from 'HashRef',
        via { bless { %{$_} } => 'MyType' };
}

method without_coercion (MyType $foo) { $foo }
method with_coercion (MyType $foo does coerce) { $foo }
method named_with_coercion (MyType :$foo does coerce) { $foo }

method optional_with_coercion (MyType $foo? does coerce) { $foo }
method default_with_coercion (MyType $foo={} does coerce) { $foo }

no Moose;

1;
