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

method moo ($a, $b) : Bar Baz(fubar) {
}

method foo
:
Bar
:Moo(:Ko{oh)
: Baz(fu{bar:): { return {} }

ok($cb_called, 'attribute handler got called');
is_deeply($attrs, [qw/Bar Moo(:Ko{oh) Baz(fu{bar:)/], '... with the right attributes');
