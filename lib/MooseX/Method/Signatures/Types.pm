package MooseX::Method::Signatures::Types;

use MooseX::Types -declare => [qw/ Injections PrototypeInjections Params /];
use MooseX::Types::Moose qw/Str ArrayRef/;
use MooseX::Types::Structured qw/Dict/;
use Parse::Method::Signatures::Types qw/Param/;

subtype Injections,
    as ArrayRef[Str];

subtype PrototypeInjections,
    as Dict[declarator => Str, injections => Injections];

subtype Params,
    as ArrayRef[Param];

1;
