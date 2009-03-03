use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

use MooseX::Method::Signatures;

my $o = bless {} => 'Foo';

{
    my $meth = method (Str $foo, Int $bar) returns (ArrayRef[Str]) {
        return [($foo) x $bar];
    };
    isa_ok($meth, 'Moose::Meta::Method');

    dies_ok(sub {
        $o->${\$meth->body}('foo')
    });

    lives_and(sub {
        my $ret = $o->${\$meth->body}('foo', 3);
        is_deeply($ret, [('foo') x 3]);
    });
}

{
    my $meth = method (Str $foo) returns (Int) {
        return 42.5;
    };

    dies_ok(sub {
        my $x = $o->${\$meth->body}('foo');
    });
}
