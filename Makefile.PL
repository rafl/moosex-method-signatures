use strict;
use warnings;
use inc::Module::Install;

name 'MooseX-Method-Signatures';
all_from 'lib/MooseX/Method/Signatures.pm';

requires 'Sub::Name';
requires 'Scope::Guard';
requires 'Devel::Declare';
requires 'Perl6::Signature';
requires 'Moose::Util::TypeConstraints';
requires 'MooseX::Meta::Signature::Combined';

test_requires 'Test::Exception';

extra_tests;

WriteAll;
