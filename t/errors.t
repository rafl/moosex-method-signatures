use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

eval "use InvalidCase01;";
ok($@, "Got an error");
like($@, 
     qr/^Global symbol "\$op" requires explicit package name at .*?\bInvalidCase01.pm line 8\b/,
     "Sane error message for syntax error");


eval "use InvalidCase02;";
ok($@, "Got an error");
like($@, 
     qr/'SomeRandomTCThatDoesntExist' could not be parsed to a type constraint .*? at .*?\bInvalidCase02.pm line 5$/m,
     "Sane error message for invalid TC");


{
  my $warnings = "";
  local $SIG{__WARN__} = sub { $warnings .= $_[0] };

  eval "use Redefined;";
  is($@, '', "No error");
  like($warnings, qr/^Method meth1 redefined on package main at .*?\bRedefined.pm line 9$/,
       "Redefined method warning");
}
