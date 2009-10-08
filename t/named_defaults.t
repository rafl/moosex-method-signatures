use strict;
use warnings;
use Test::More;

{
    package Foo;

    use Moose;
    use MooseX::Method::Signatures;

    method bar (:$baz = 42) { $baz }
}

my $o = Foo->new;
is($o->bar, 42);
is($o->bar(baz => 0xaffe), 0xaffe);

done_testing;
