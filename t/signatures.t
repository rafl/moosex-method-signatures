use strict;
use warnings;

use Test::More;
use Test::Exception;
use MooseX::Method::Signatures;
use Moose::Util::TypeConstraints;
use Readonly;

{

    package Bar::Foo;
    use Moose;
    has 'x' => ( isa => 'Str', );
}

Readonly my $ISTODO => 1;
Readonly my $ISFAIL => 2;

# == 0 disables TODO mode
my $dotodo = 1;

my @signatures;
@signatures = (

    # basic tests.
    [ $ISTODO, '$arg',   'Optional(implicit) Positional' ],    #1
    [ $ISTODO, '$arg?',  'Optional Positional' ],
    [ $ISTODO, '$arg!',  'Required Positional' ],
    [ $ISTODO, ':$arg',  'Required(implicit) Named' ],
    [ $ISTODO, ':$arg?', 'Optional Named' ],
    [ $ISTODO, ':$arg!', 'Required Named' ],                   #6

    # type tests
    [ $ISTODO, 'Str $arg',       'Positional String Type' ],    #7
    [ $ISTODO, 'Int $arg',       'Positional Int Type' ],
    [ $ISTODO, 'Bar::Foo $arg',  'Positional Class Type' ],
    [ $ISTODO, 'Str :$arg',      'Named String Type' ],
    [ $ISTODO, 'Int :$arg',      'Named Int Type' ],
    [ $ISTODO, 'Bar::Foo :$arg', 'Named Class Type' ],          #12

    # coerce does tests
    [ $ISTODO, 'Str $arg does coerce',  'COERCE Positional String Type' ],  # 13
    [ $ISTODO, 'Int $arg does coerce ', 'COERCE Positional Int Type' ],
    [ $ISTODO, 'Bar::Foo $arg does coerce',  'COERCE Positi Class Type' ],
    [ $ISTODO, 'Str :$arg does coerce',      'COERCE Named String Type' ],
    [ $ISTODO, 'Int :$arg does coerce',      'COERCE Named Int Type' ],
    [ $ISTODO, 'Bar::Foo :$arg does coerce', 'COERCE Named Class Type' ],
    [ $ISTODO, ':$arg does coerce',          'COERCE Named ' ],
    [ $ISTODO, '$arg does coerce',           'COERCE Postional ' ],         # 20

    # coerce is tests
    [ $ISTODO, 'Str $arg is coerce',  'COERCE_IS Positional String Type' ],  #21
    [ $ISTODO, 'Int $arg is coerce ', 'COERCE_IS Positional Int Type' ],
    [ $ISTODO, 'Bar::Foo $arg is coerce',  'COERCE_IS Positi Class Type' ],
    [ $ISTODO, 'Str :$arg is coerce',      'COERCE_IS Named String Type' ],
    [ $ISTODO, 'Int :$arg is coerce',      'COERCE_IS Named Int Type' ],
    [ $ISTODO, 'Bar::Foo :$arg is coerce', 'COERCE_IS Named Class Type' ],
    [ $ISTODO, ':$arg is coerce',          'COERCE_IS Named ' ],
    [ $ISTODO, '$arg is coerce',           'COERCE_IS Postional ' ],        # 28

    # coerce is where tests
    [
        $ISTODO,
        'Str $arg is coerce where { 1 } ',
        'COERCE_WHERE Positional String Type'
    ],                                                                      #29
    [
        $ISTODO,
        'Int $arg is coerce where { 1 } ',
        'COERCE_WHERE Positional Int Type'
    ],
    [
        $ISTODO,
        'Bar::Foo $arg is coerce where { 1 }',
        'COERCE_WHERE Positi Class Type'
    ],
    [
        $ISTODO,
        'Str :$arg is coerce where { 1 }',
        'COERCE_WHERE Named String Type'
    ],
    [
        $ISTODO,
        'Int :$arg is coerce where { 1 }',
        'COERCE_WHERE Named Int Type'
    ],
    [
        $ISTODO,
        'Bar::Foo :$arg is coerce where { 1 }',
        'COERCE_WHERE Named Class Type'
    ],
    [ $ISTODO, ':$arg is coerce where { 1 } ', 'COERCE_WHERE Named ' ],
    [ $ISTODO, '$arg is coerce where { 1 }',   'COERCE_WHERE Postional ' ], # 36

    # where tests
    [ $ISTODO, 'Str $arg where { 1 } ', 'WHERE Positional String Type' ],    #37
    [ $ISTODO, 'Int $arg where { 1 } ', 'WHERE Positional Int Type' ],
    [ $ISTODO, 'Bar::Foo $arg where { 1 }',  'WHERE Positi Class Type' ],
    [ $ISTODO, 'Str :$arg where { 1 }',      'WHERE Named String Type' ],
    [ $ISTODO, 'Int :$arg where { 1 }',      'WHERE Named Int Type' ],
    [ $ISTODO, 'Bar::Foo :$arg where { 1 }', 'WHERE Named Class Type' ],
    [ $ISTODO, ':$arg  where { 1 } ',        'WHERE Named ' ],
    [ $ISTODO, '$arg  where { 1 }',          'WHERE Postional ' ],          # 44

    # defaults tests.
    [ $ISTODO, '$arg = 42',   'Default+ Optional(implicit) Positional' ],    #45
    [ $ISTODO, '$arg? = 42',  'Default+ Optional Positional' ],
    [ $ISTODO, '$arg! = 42',  'Default+ Required Positional' ],
    [ $ISTODO, ':$arg = 42',  'Default+ Required(implicit) Named' ],
    [ $ISTODO, ':$arg? = 42', 'Default+ Optional Named' ],
    [ $ISTODO, ':$arg! = 42', 'Default+ Required Named' ],                   #50

    # invocant tests.
    [ $ISTODO, '$self: $arg',   'Invocant + Positional ' ],                  #51
    [ $ISTODO, '$class: $arg',  'Nondefault Invocant + Positional ' ],
    [ $ISTODO, '$self: :$arg',  'Invocant + Named ' ],                       #53
    [ $ISTODO, '$class: :$arg', 'Nondefault Invocant + Named ' ],

    # label tests .
    [ $ISTODO, ':foo($arg)', 'Label' ],                                      #55
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



