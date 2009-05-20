use strict;
use warnings;

package TestClassWithMxTypes;

use Moose;
use MooseX::Method::Signatures;
use MooseX::Types::Moose 'Str';

use MooseX::Types -declare => ['TypeConstraint'];
BEGIN {
  subtype TypeConstraint, as class_type('Moose::Meta::TypeConstraint');
  coerce  TypeConstraint, from Str, via { find_type_constraint($_) };
}

method new($class:) { return bless {}, $class }

method with_coercion( TypeConstraint $type does coerce ) {
  return $type;
}

method optional_with_coercion( TypeConstraint $type? does coerce ) {
  return $type;
}

1;

