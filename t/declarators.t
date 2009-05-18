use strict;
use warnings;
use Test::More tests => 16;

package MultipleDeclarators;

use Moose;
use MooseX::Method::Signatures
    mtfnpy => ['CodeRef $flarg'],
    qperty => ['Str $goof'],
    zorbwf => ['HashRef $hakh'];
use Test::More;

mtfnpy foo (Int $yarg) {
    ok(defined($self), '$self is defined');
    ok(defined($flarg), '$flarg is defined');
    ok(defined($yarg), '$yarg is defined');
    is(ref($flarg), 'CODE', '$flarg is a coderef');
    is($yarg, 1, '$yarg is 1');
}

qperty bar (ClassName $floof: Int $yarg) {
    ok(defined($goof), '$goof is defined');
    ok(defined($floof), '$floof is defined');
    ok(defined($yarg), '$yarg is defined');
    is($goof, 'HELLO', '$goof is HELLO');
    is($floof, 'MultipleDeclarators', '$floof is a class name');
    is($yarg, 1, '$yarg is 1');
}

zorbwf baz (Int $yarg) {
    ok(defined($self), '$self is defined');
    ok(defined($hakh), '$hakh is defined');
    ok(defined($yarg), '$yarg is defined');
    is(ref($hakh), 'HASH', '$hahk is a HashRef');
    is($yarg, 1, '$yarg is 1');
}

package main;

my $md = MultipleDeclarators->new();

my ($mtfnpy, $qperty, $zorbwf);

{
    no strict 'refs';
    $mtfnpy = *{'MultipleDeclarators::foo'};
    $qperty = *{'MultipleDeclarators::bar'};
    $zorbwf = *{'MultipleDeclarators::baz'};
}

$mtfnpy->(sub { 1 }, $md, 1);
$qperty->('HELLO', 'MultipleDeclarators', 1);
$zorbwf->({}, $md, 1);
