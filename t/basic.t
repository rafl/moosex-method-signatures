use strict;
use warnings;
use Test::More tests => 19;
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

# p6::signatures bug
#lives_ok(sub { $o->affe({ foo => 1 }) });
lives_ok(sub { $o->affe([qw/a b c/]) });
dies_ok(sub { $o->affe('foo') });

dies_ok(sub { $o->positional });
dies_ok(sub { $o->positional(optional => 42) });
lives_ok(sub { $o->positional(required => 23) });
lives_ok(sub { $o->positional(optional => 42, required => 23) });

dies_ok(sub { $o->combined(1, 2) });
dies_ok(sub { $o->combined(1, required => 2) });
lives_ok(sub { $o->combined(1, 2, 3, required => 4, optional => 5) });

# MooseX::Meta::Signature::Combined bug? optional positional can't be omitted
#lives_ok(sub { $o->combined(1, 2, required => 3) });
#lives_ok(sub { $o->combined(1, 2, required => 3, optional => 4) });
