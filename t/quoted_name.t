use strict;
use warnings;
use Test::More tests => 2;

use MooseX::Method::Signatures;

my $foo = 'bar';

method "$foo" ($class:) { $foo }

my $meth = __PACKAGE__->can($foo);
ok($meth);
is(__PACKAGE__->$meth, $foo);
