use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;

use MooseX::Method::Signatures::Meta::Method;

{
    package Foo;
    use metaclass;

    my $method = MooseX::Method::Signatures::Meta::Method->wrap(
        signature    => '($class: Int :$foo, Str :$bar)',
        package_name => 'Foo',
        name         => 'bar',
        body         => sub {
            my ($class, $foo, $bar) = @_;
            return $bar x $foo;
        },
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
