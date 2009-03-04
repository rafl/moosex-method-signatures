use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

eval "use InvalidCase01;";
ok($@, "Got an error");
like($@, qr/"\$op" requires explicit package name/s, "Sane error message")
