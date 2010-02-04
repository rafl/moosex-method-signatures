#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use MooseX::Method::Signatures;
method m1(:$bar!) { }
method m2(:$bar?) { }
method m3(:$bar ) { }

method m4( $bar!) { }
method m5( $bar?) { }
method m6( $bar ) { }

lives_ok(sub { m1(bar => undef) }, 'Explicitly pass undef to positional required arg');
lives_ok(sub { m2(bar => undef) }, 'Explicitly pass undef to positional explicit optional arg');
lives_ok(sub { m3(bar => undef) }, 'Explicitly pass undef to positional implicit optional arg');

lives_ok(sub { m4(undef) }, 'Explicitly pass undef to required arg');
lives_ok(sub { m5(undef) }, 'Explicitly pass undef to explicit required arg');
lives_ok(sub { m6(undef) }, 'Explicitly pass undef to implicit required arg');
