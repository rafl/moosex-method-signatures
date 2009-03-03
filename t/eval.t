use strict;
use warnings;

use Test::More tests => 3;    # last test to print
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

my $foo = foo->new({});
is ($foo->example (), 1, 'First method declared');
is ($foo->example2(), 2, 'Second method declared (after injected semicolon)');

__DATA__
{
    package foo;

    use Moose;
    use MooseX::Method::Signatures;
    method example  { 1 } # look Ma, no semicolon!
    method example2 { 2 }
}
1;


