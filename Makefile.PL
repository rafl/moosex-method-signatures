use strict;
use warnings;
use inc::Module::Install 0.77;

name 'MooseX-Method-Signatures';
all_from 'lib/MooseX/Method/Signatures.pm';

requires 'B::Hooks::EndOfScope' => '0.07';
requires 'Parse::Method::Signatures' => '1.002000';
requires 'Devel::Declare' => '0.003004';
requires 'Moose::Util::TypeConstraints';
requires 'Moose';
requires 'MooseX::Types::Moose';
requires 'MooseX::Meta::Signature::Combined';
requires 'namespace::clean';

test_requires 'Test::Exception';

repository 'git://github.com/rafl/moosex-method-signatures.git';
bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Method-Signatures';

extra_tests();

WriteAll;
