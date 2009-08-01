use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package Foo;
    use Moose;
    use MooseX::Method::Signatures;
    method bar { 42 }
}

my $foo = Foo->new;

lives_ok(sub {
    $foo->bar
}, 'method without signature succeeds when called without args');

lives_ok(sub {
    $foo->bar(42)
}, 'method without signature succeeds when called with args');

done_testing;
