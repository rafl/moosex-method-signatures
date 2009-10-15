use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package Foo;
    use Moose;
    use MooseX::Method::Signatures;

    method foo ($bar) { $bar }
}

my $o = Foo->new;
lives_ok(sub { $o->foo(42) });
throws_ok(sub { $o->foo(42, 23) }, qr/Validation failed/);

done_testing;
