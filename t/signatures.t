use strict;
use warnings;

use Test::More;
use Test::Exception;
use MooseX::Method::Signatures;
use Moose::Util::TypeConstraints;

{

    package Bar::Foo;
    use Moose;
    has 'x' => ( isa => 'Str', );
}

my $ISTODO = 1;
my $ISFAIL = 2;

# == 0 disables TODO mode
my $dotodo = 1;

my @signatures;
@signatures = (

    # basic tests.
    [ 0, '$arg',   'Optional(implicit) Positional' ],    #1
    [ 0, '$arg?',  'Optional Positional' ],
    [ 0, '$arg!',  'Required Positional' ],
    [ 0, ':$arg',  'Required(implicit) Named' ],
    [ 0, ':$arg?', 'Optional Named' ],
    [ 0, ':$arg!', 'Required Named' ],                   #6

    # type tests
    [ 0, 'Str $arg',       'Positional String Type' ],    #7
    [ 0, 'Int $arg',       'Positional Int Type' ],
    [ 0, 'Bar::Foo $arg',  'Positional Class Type' ],
    [ 0, 'Str :$arg',      'Named String Type' ],
    [ 0, 'Int :$arg',      'Named Int Type' ],
    [ 0, 'Bar::Foo :$arg', 'Named Class Type' ],          #12

    # coerce does tests
    [ 0, 'Str $arg does coerce',  'COERCE Positional String Type' ],  # 13
    [ 0, 'Int $arg does coerce ', 'COERCE Positional Int Type' ],
    [ 0, 'Bar::Foo $arg does coerce',  'COERCE Positi Class Type' ],
    [ 0, 'Str :$arg does coerce',      'COERCE Named String Type' ],
    [ 0, 'Int :$arg does coerce',      'COERCE Named Int Type' ],
    [ 0, 'Bar::Foo :$arg does coerce', 'COERCE Named Class Type' ],
    [ 0, ':$arg does coerce',          'COERCE Named ' ],
    [ 0, '$arg does coerce',           'COERCE Postional ' ],         # 20

    # coerce is tests
    [ 0, 'Str $arg does coerce',  'COERCE_IS Positional String Type' ],  #21
    [ 0, 'Int $arg does coerce ', 'COERCE_IS Positional Int Type' ],
    [ 0, 'Bar::Foo $arg does coerce',  'COERCE_IS Positi Class Type' ],
    [ 0, 'Str :$arg does coerce',      'COERCE_IS Named String Type' ],
    [ 0, 'Int :$arg does coerce',      'COERCE_IS Named Int Type' ],
    [ 0, 'Bar::Foo :$arg does coerce', 'COERCE_IS Named Class Type' ],
    [ 0, ':$arg does coerce',          'COERCE_IS Named ' ],
    [ 0, '$arg does coerce',           'COERCE_IS Postional ' ],        # 28

    # coerce is where tests
    [
        0,
        'Str $arg does coerce where { 1 } ',
        'COERCE_WHERE Positional String Type'
    ],                                                                      #29
    [
        0,
        'Int $arg does coerce where { 1 } ',
        'COERCE_WHERE Positional Int Type'
    ],
    [
        0,
        'Bar::Foo $arg does coerce where { 1 }',
        'COERCE_WHERE Positi Class Type'
    ],
    [
        0,
        'Str :$arg does coerce where { 1 }',
        'COERCE_WHERE Named String Type'
    ],
    [
        0,
        'Int :$arg does coerce where { 1 }',
        'COERCE_WHERE Named Int Type'
    ],
    [
        0,
        'Bar::Foo :$arg does coerce where { 1 }',
        'COERCE_WHERE Named Class Type'
    ],
    [ 0, ':$arg does coerce where { 1 } ', 'COERCE_WHERE Named ' ],
    [ 0, '$arg does coerce where { 1 }',   'COERCE_WHERE Postional ' ], # 36

    # where tests
    [ 0, 'Str $arg where { 1 } ', 'WHERE Positional String Type' ],    #37
    [ 0, 'Int $arg where { 1 } ', 'WHERE Positional Int Type' ],
    [ 0, 'Bar::Foo $arg where { 1 }',  'WHERE Positi Class Type' ],
    [ 0, 'Str :$arg where { 1 }',      'WHERE Named String Type' ],
    [ 0, 'Int :$arg where { 1 }',      'WHERE Named Int Type' ],
    [ 0, 'Bar::Foo :$arg where { 1 }', 'WHERE Named Class Type' ],
    [ 0, ':$arg  where { 1 } ',        'WHERE Named ' ],
    [ 0, '$arg  where { 1 }',          'WHERE Postional ' ],          # 44

    # defaults tests.
    [ 0, '$arg = 42',   'Default+ Optional(implicit) Positional' ],    #45
    [ 0, '$arg? = 42',  'Default+ Optional Positional' ],
    [ 0, '$arg! = 42',  'Default+ Required Positional' ],
    [ 0, ':$arg = 42',  'Default+ Required(implicit) Named' ],
    [ 0, ':$arg? = 42', 'Default+ Optional Named' ],
    [ 0, ':$arg! = 42', 'Default+ Required Named' ],                   #50

    # invocant tests.
    [ 0, '$self: $arg',   'Invocant + Positional ' ],                  #51
    [ 0, '$class: $arg',  'Nondefault Invocant + Positional ' ],
    [ 0, '$self: :$arg',  'Invocant + Named ' ],                       #53
    [ 0, '$class: :$arg', 'Nondefault Invocant + Named ' ],

    # label tests .
    [ 0, ':foo($arg)', 'Label' ],                                      #55
);

plan tests => $#signatures + 1;

# --------[ EXECUTE ]------------------------------------------------------- #
my $template = do { local $/ = undef; <DATA> };

my $package_iteration = 'A';
for my $test (@signatures) {
    my $pkg = $package_iteration;
    $package_iteration++;
    my ( $stability, $signature, $description ) = @{$test};

    my $dotest = sub {
        my $code    = sprintf $template, $pkg, $signature, '$arg';
        my $message = "$description (Test: $pkg Syntax: '( $signature )') ";
        my $res     = 1;
        $res = eval $code;
        if ( $@ eq '' ) {
            pass($message);
        }
        else {
            fail($message)

              #. "\n------\n$@\n--------\n" );
        }
    };

    if ( $dotodo && ( $stability & $ISTODO ) ) {

      TODO: {
            local $TODO = 'Signatures/Coercion Support';
            $dotest->();
        }
    }
    else {
        $dotest->();
    }

}
__DATA__

{
    package %s; 
    use Moose; 
    use MooseX::Method::Signatures;
    use Moose::Util::TypeConstraints;
    method alpha ( %s ){ 
        return %s; 
    };
}



