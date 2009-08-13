use strict;
use warnings;
use Test::More;

BEGIN {
    eval 'use MooseX::Types::Path::Class';
    plan skip_all => 'MooseX::Types::Path::Class required for this test' if $@;
}

{
    package Foo;
    use Moose;
    use MooseX::Method::Signatures;
    use MooseX::Types::Path::Class qw/Dir/;

    method foo (Dir  $dir  does coerce) { $dir }
    method bar (Dir :$dir  does coerce) { $dir }
    method baz (Dir :$dir! does coerce) { $dir }

    warn Foo->meta->get_method('bar')->type_constraint->_type_constraint;
}

{
    my $foo = Foo->new;
    isa_ok($foo->foo('.'),        'Path::Class::Dir');
    isa_ok($foo->bar(dir => '.'), 'Path::Class::Dir');
    isa_ok($foo->baz(dir => '.'), 'Path::Class::Dir');
}

done_testing;
