use strict;
use warnings;
use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

use TestClass;

dies_ok(sub { TestClass->new });
dies_ok(sub { TestClass->new('moo', 23) });
dies_ok(sub { TestClass->new('moo', 8) });
lives_ok(sub { TestClass->new('moo', 52) });

my $o = TestClass->new('foo');
isa_ok($o, 'TestClass');

is($o->{foo}, 'foo');
is($o->{bar}, 42);

lives_ok(sub { $o->set_bar(23) });
is($o->{bar}, 23);

dies_ok(sub { $o->set_bar('bar') });

{
    my $test_hash = { foo => 1 };
    lives_ok(sub { $o->affe($test_hash) });
    is_deeply($o->{baz}, $test_hash);
}

{
    my $test_array = [qw/a b c/];
    lives_ok(sub { $o->affe($test_array) });
    is_deeply($o->{baz}, $test_array);
}

dies_ok(sub { $o->affe('foo') });

dies_ok(sub { $o->named });
dies_ok(sub { $o->named(optional => 42) });
throws_ok(sub { $o->named }, qr/\b at \b .* \b line \s+ \d+/x, "dies with proper exception");

lives_ok(sub {
    is_deeply(
        [$o->named(required => 23)],
        [undef, 23],
    );
});

lives_ok(sub {
    is_deeply(
        [$o->named(optional => 42, required => 23)],
        [42, 23],
    );
});

dies_ok(sub { $o->combined(1, 2) });
dies_ok(sub { $o->combined(1, required => 2) });

lives_ok(sub {
    is_deeply(
        [$o->combined(1, 2, 3, required => 4, optional => 5)],
        [1, 2, 3, 5, 4],
    );
});

lives_ok(sub { $o->with_coercion({}) });
dies_ok(sub { $o->without_coercion({}) });
lives_ok(sub { $o->named_with_coercion(foo => bless({}, 'MyType')) });
lives_ok(sub { $o->named_with_coercion(foo => {}) });

# MooseX::Meta::Signature::Combined bug? optional positional can't be omitted
#lives_ok(sub { $o->combined(1, 2, required => 3) });
#lives_ok(sub { $o->combined(1, 2, required => 3, optional => 4) });

use MooseX::Method::Signatures;

my $anon = method ($foo, $bar) { };
isa_ok($anon, 'Moose::Meta::Method');

done_testing;
