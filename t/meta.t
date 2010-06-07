use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;

use MooseX::Method::Signatures::Meta::Method;

{
    package Foo;
    use metaclass;

    my $method = MooseX::Method::Signatures::Meta::Method->wrap(
        sub {
            my ($class, $foo, $bar) = @_;
            return $bar x $foo;
        },
        signature    => '($class: Int :$foo, Str :$bar)',
        package_name => 'Foo',
        name         => 'bar',
    );
    ::isa_ok($method, 'Moose::Meta::Method');

    Foo->meta->add_method(bar => $method);
}

lives_and(sub {
    is(Foo->bar(foo => 3, bar => 'baz'), 'bazbazbaz');
});

dies_ok(sub {
    Foo->bar(foo => 'moo', bar => 'baz');
});

# Makes sure we still support the old API.

{
    package Bar;
    use metaclass;

    my $method = MooseX::Method::Signatures::Meta::Method->wrap(
        signature    => '($class: Int :$foo, Str :$bar)',
        package_name => __PACKAGE__,
        name         => 'bar',
        body         => sub {
            my ($class, $foo, $bar) = @_;
            return $bar x $foo;
        },
    );
    ::isa_ok($method, 'Moose::Meta::Method');

    Bar->meta->add_method(bar => $method);
}

lives_and(sub {
    is(Bar->bar(foo => 3, bar => 'baz'), 'bazbazbaz');
});

dies_ok(sub {
    Bar->bar(foo => 'moo', bar => 'baz');
});
