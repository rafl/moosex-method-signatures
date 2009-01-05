use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

{
    package MyTypes;
    use MooseX::Types::Moose qw/Str/;
    use Moose::Util::TypeConstraints;
    use MooseX::Types -declare => [qw/CustomType/];

    subtype CustomType,
        as Str,
        where { length($_) == 2 };
}

{
    package TestClass;
    use MooseX::Method::Signatures;
    BEGIN { MyTypes->import('CustomType') };

    method foo (CustomType $bar) { }
}

lives_ok(sub { TestClass->foo('42') });
dies_ok(sub { TestClass->foo('bar') });
