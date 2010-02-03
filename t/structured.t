use strict;
use warnings;
use Test::More tests => 18;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw/Any Object Maybe Str Int/;
use MooseX::Types::Structured qw/Dict Tuple Optional/;
use MooseX::Method::Signatures;

my $o = bless {}, 'Class';

{ # ($foo, $bar?)
    my $meth = method ($foo, $bar?) {
        $bar ||= 'default';
        return "${\ref $self} ${foo} ${bar}";
    };

    my $expected = Tuple[Tuple[Object,Any,Optional[Any]], Dict[]];
    is($meth->type_constraint->name, $expected->name);

    eval {
        is($o->${\$meth->body}('foo', 'bar'), 'Class foo bar');
    };
    ok(!$@);

    eval {
        is($o->${\$meth->body}('foo'), 'Class foo default');
    };
    ok(!$@);

    eval {
        $o->${\$meth->body}();
    };
    ok($@);
}

{
    my $meth = method (:$foo!, :$bar) {
        $bar ||= 'default';
        return "${\ref $self} ${foo} ${bar}";
    };

    my $expected = Tuple[Tuple[Object], Dict[foo => Any, bar => Optional[Any]]];
    is($meth->type_constraint->name, $expected->name);

    eval {
        is($o->${\$meth->body}(foo => 1, bar => 2), 'Class 1 2');
    };
    ok(!$@);

    eval {
        is($o->${\$meth->body}(foo => 1), 'Class 1 default');
    };
    ok(!$@);

    eval {
        $o->${\$meth->body}(foo => 1, bar => 2, baz => 3);
    };
    ok($@);

    eval {
        $o->${\$meth->body}(bar => 1);
    };
    ok($@);

    eval {
        $o->${\$meth->body}();
    };
    ok($@);
}

{
    my $meth = method ($class: Str $foo, Int $bar where { $_ % 2 == 0 }) {
        return "${class} ${foo} ${bar}";
    };

    my $expected = Tuple[Tuple[Any, Str, subtype(Int, where { $_ % 2 == 0 })], Dict[]];
    is($meth->type_constraint->name, $expected->name);

    eval {
        is(Class->${\$meth->body}('foo', 42), 'Class foo 42');
    };
    ok(!$@);

    eval {
        Class->${\$meth->body}('foo', 23);
    };
    ok($@);
}
