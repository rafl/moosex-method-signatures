use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

{
    package TestClass;
    use MooseX::Method::Signatures;

    use aliased 'My::AnnoyinglyLongTypeName::Aaa';
    use Another::AnnoyingTypeName::Bbb;

    method a  (My::AnnoyinglyLongTypeName::Aaa $affe)  { }
    method a2 (Aaa                             $loewe) { 'me_is_the_goal' }
    method b  (Another::AnnoyingTypeName::Bbb  $tiger) { }
}

use aliased "My::AnnoyinglyLongTypeName::Aaa";
use Another::AnnoyingTypeName::Bbb;

my $aaa             = bless {} => 'My::AnnoyinglyLongTypeName::Aaa';
my $aaa_aliased     = bless {} => Aaa;
my $bbb             = bless {} => 'Another::AnnoyingTypeName::Bbb';
my $bbb_thewrongway = bless {} => 'Bbb';

my $o = TestClass->new;

lives_ok( sub { $o->a($aaa) });
lives_ok( sub { $o->a2($aaa) });

lives_ok( sub { $o->a($aaa_aliased) });
lives_ok( sub { $o->a2($aaa_aliased) });

dies_ok( sub { $o->b($aaa) });
dies_ok( sub { $o->b($aaa_aliased) });

lives_ok( sub { $o->b($bbb) });
dies_ok(  sub { $o->b($bbb_thewrongway) });

is( $o->a2($aaa_aliased), 'me_is_the_goal', "all features in one go");
