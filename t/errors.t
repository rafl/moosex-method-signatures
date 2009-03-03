use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

eval "use InvalidCase01;";
ok($@, "Got an error");
unlike($@, qr/^BEGIN not safe after errors--compilation aborted/s, "Sane error message")
  and diag $@;
