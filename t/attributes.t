use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

use attributes;
use MooseX::Method::Signatures;

my $attrs;
my $cb_called;

sub MODIFY_CODE_ATTRIBUTES {
    my ($pkg, $code, @attrs) = @_;
    $cb_called = 1;
    $attrs = \@attrs;
    return ();
}

#TODO: doesn't work when : and the start of the block aren't on the same line yet

method foo ($a, $b) : Bar Baz(fubar) {
};

ok($cb_called, 'attribute handler got called');
is_deeply($attrs, [qw/Bar Baz(fubar)/], '... with the right attributes');
