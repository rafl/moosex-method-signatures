use MooseX::Method::Signatures;
use strict;
use warnings;

use Carp qw/croak/;

method meth1{
  croak "Binary operator $op expects 2 children, got " . $#$_
    if @{$_} > 3;
}

method meth2{ {
  "a" "b"
}

method meth3 {}
1;

