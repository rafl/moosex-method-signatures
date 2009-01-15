use strict;
use warnings;

use Test::More tests => 1;    # last test to print
use MooseX::Method::Signatures;


my $evalcode = do {
    local $/ = undef;
    <DATA>;
};

ok(
    do {
        my $r = eval $evalcode;
        die $@ if not $r;
        1;
    },
    'Basic Eval Moose'
);
__DATA__
{
	package foo;

	use Moose;
    use MooseX::Method::Signatures;
	method example {
	}
}
1;
