use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

{
    package MyTypes;
    use MooseX::Types::Moose qw/Str/;
    use Moose::Util::TypeConstraints;
    use MooseX::Types -declare => [qw/CustomType/];

    BEGIN {
        subtype CustomType,
            as Str,
            where { length($_) == 2 };
    }
}

{
    package TestClass;
    use MooseX::Method::Signatures;
    BEGIN { MyTypes->import('CustomType') };
    use MooseX::Types::Moose qw/ArrayRef/;

    method foo (CustomType $bar) { }

    method bar (ArrayRef[CustomType] $baz) { }
}

lives_ok(sub { TestClass->foo('42') });
dies_ok(sub { TestClass->foo('bar') });

lives_ok(sub { TestClass->bar(['42', '23']) });
dies_ok(sub { TestClass->bar(['foo', 'bar']) });
