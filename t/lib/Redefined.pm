use MooseX::Method::Signatures;
use strict;
use warnings;

use Carp qw/croak/;

method meth1 {}

method meth1 {}

# this one should not trigger a redfined warning
sub meth2 {}
method meth2 {}

# This one shouldn't either
method meth3 {}
{ no warnings 'redefine';
  method meth3 {}
}
1;


