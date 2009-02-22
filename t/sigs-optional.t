
use strict;
use warnings;

use Test::More tests => 2;                      # last test to print

{
    package Optional;
    use MooseX::Method::Signatures;
    method foo ($arg?) {
        $arg;
    }
}

is( Optional->foo(), undef);
is( Optional->foo(1), 1);

__END__
t/sigs-optional....
1..2
Parameter 1: Must be specified# Looks like your test exited with 255 before it could output anything.
 Dubious, test returned 255 (wstat 65280, 0xff00)
 Failed 2/2 subtests 

Test Summary Report
-------------------
t/sigs-optional (Wstat: 65280 Tests: 0 Failed: 0)
  Non-zero exit status: 255
  Parse errors: Bad plan.  You planned 2 tests but ran 0.
Files=1, Tests=0,  1 wallclock secs ( 0.03 usr  0.01 sys +  0.60 cusr  0.02 csys =  0.66 CPU)
Result: FAIL
