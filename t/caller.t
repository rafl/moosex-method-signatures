use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok("TestClass");


my $callstack = TestClass->callstack();

unlike $callstack, qr/Test::Class::.*?__ANON__/, "No anon methods in call chain";
