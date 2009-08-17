use strict;
use warnings;
use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

{
    package TestClass;
    use Moose;
    use MooseX::Method::Signatures;

    use aliased 'My::Annoyingly::Long::Name::Space', 'Shortcut';

    eval 'method alias_sig (Shortcut $affe) { }';
    ::ok(!$@, 'method with aliased type constraint compiles');
}

my $o = TestClass->new;
my $affe = My::Annoyingly::Long::Name::Space->new;

lives_ok(sub {
    $o->alias_sig($affe);
}, 'calling method with aliased type constraint');

done_testing;
