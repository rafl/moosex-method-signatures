use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;
use MooseX::Method::Signatures;

my $meth = method ($foo, $bar, @rest) {
    return join q{,}, @rest;
};

my $o = bless {} => 'Foo';

dies_ok(sub { $o->${\$meth->body}() });
dies_ok(sub { $o->${\$meth->body}('foo') });

lives_and(sub {
    is($o->${\$meth->body}('foo', 'bar'), q{});
});

lives_and(sub {
    is($o->${\$meth->body}('foo', 'bar', 1 .. 5), q{1,2,3,4,5});
});

eval 'my $meth = method (:$foo, :@bar) { }';
like $@, qr/arrays or hashes cannot be named/i;
