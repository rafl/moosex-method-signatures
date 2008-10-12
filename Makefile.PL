use strict;
use warnings;
use inc::Module::Install;

name 'MooseX-Method-Signatures';
all_from 'lib/MooseX/Method/Signatures.pm';

requires 'Sub::Name';
requires 'Scope::Guard';
requires 'Perl6::Signature' => '0.03';
requires 'Devel::Declare' => '0.002000';
requires 'Moose::Util::TypeConstraints';
requires 'MooseX::Meta::Signature::Combined';

test_requires 'Test::Exception';

extra_tests;

WriteAll;
