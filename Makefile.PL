use strict;
use warnings;
use inc::Module::Install;

name 'MooseX-Method-Signatures';
all_from 'lib/MooseX/Method/Signatures.pm';

extra_tests;

WriteAll;
