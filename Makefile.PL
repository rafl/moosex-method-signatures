use strict;
use warnings;
use inc::Module::Install;

name 'MooseX-Method-Signatures';
all_from 'lib/MooseX/Method/Signatures.pm';

requires 'B::Hooks::EndOfScope';
requires 'Parse::Method::Signatures';
requires 'Devel::Declare' => '0.002000';
requires 'Moose::Util::TypeConstraints';
requires 'MooseX::Meta::Signature::Combined';

test_requires 'Test::Exception';

extra_tests;

WriteAll;
