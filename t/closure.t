use strict;
use warnings;
use Test::More;

{
    package Foo;

    use Moose;
    use MooseX::Method::Signatures;

    for my $meth (qw/foo bar baz/) {
        Foo->meta->add_method("anon_$meth" => method (Str $bar) {
            $meth . $bar
        });

        method "str_$meth" (Str $bar) {
            $meth . $bar
        }
    }
}

can_ok('Foo', map { ("anon_$_", "str_$_") } qw/foo bar baz/);

my $foo = Foo->new;

for my $meth (qw/foo bar baz/) {
    is($foo->${\"anon_$meth"}('bar'), $meth . 'bar');
    is($foo->${\"str_$meth"}('bar'), $meth . 'bar');
}

done_testing;
