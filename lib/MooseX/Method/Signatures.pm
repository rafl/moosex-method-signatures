use strict;
use warnings;

package MooseX::Method::Signatures;

use Carp qw/croak/;
use Sub::Name;
use Scope::Guard;
use Devel::Declare ();
use Perl6::Signature;
use MooseX::Meta::Signature::Positional;

our $VERSION = '0.01_01';

our ($Declarator, $Offset);

sub import {
    my $caller = caller();

    Devel::Declare->setup_for(
        $caller,
        { method => { const => \&parser } },
    );

    {
        no strict 'refs';
        *{$caller.'::method'} = sub (&) {};
    }
}

sub skip_declarator {
    $Offset += Devel::Declare::toke_move_past_token($Offset);
}

sub skipspace {
    $Offset += Devel::Declare::toke_skipspace($Offset);
}

sub strip_name {
    skipspace;

    if (my $len = Devel::Declare::toke_scan_word($Offset, 1)) {
        my $linestr = Devel::Declare::get_linestr();
        my $name    = substr($linestr, $Offset, $len);
        substr($linestr, $Offset, $len) = '';
        Devel::Declare::set_linestr($linestr);
        return $name;
    }

    return;
}

sub strip_proto {
    skipspace;

    my $linestr = Devel::Declare::get_linestr();
    if (substr($linestr, $Offset, 1) eq '(') {
        my $length = Devel::Declare::toke_scan_str($Offset);
        my $proto  = Devel::Declare::get_lex_stuff();
        Devel::Declare::clear_lex_stuff();
        $linestr = Devel::Declare::get_linestr();
        substr($linestr, $Offset, $length) = '';
        Devel::Declare::set_linestr($linestr);
        return $proto;
    }

    return;
}

sub shadow {
    my $pack = Devel::Declare::get_curstash_name;
    Devel::Declare::shadow_sub("${pack}::${Declarator}", $_[0]);
}

sub parse_proto {
    my ($proto) = @_;
    my ($vars, $param_spec) = (q//) x 2;

    my $sig = Perl6::Signature->parse(":(${proto})");
    croak "Invalid method signature (${proto})"
        unless $sig;

    my $i = 1;
    for my $param (@{ $sig->s_positionalList }) {
        $vars .= $param->p_variable . q{,};

        my $required = $i > $sig->s_requiredPositionalCount ? 0 : 1;
        my $default  = $param->p_default;
        my $type;

        if (my @types = @{ $param->p_types }) {
            $type = join '|', @types;
            $type = qq{'${type}'};
        }

        $param_spec .= "{";
        $param_spec .= "required => ${required},";
        $param_spec .= "isa => ${type}," if defined $type;
        $param_spec .= "default => ${default}," if defined $default;
        $param_spec .= "},";

        $i++;
    }

    return ($vars, $param_spec);
}

sub make_proto_unwrap {
    my ($proto) = @_;

    my $inject = 'my $self = shift; ';
    if (defined $proto && length $proto) {
        my ($vars, $param_spec) = parse_proto($proto);
        $inject .= "my (${vars}) = MooseX::Meta::Signature::Positional->new(${param_spec})->validate(\@_);";
    }

    print STDERR $inject, "\n";

    return $inject;
}

sub inject_if_block {
    my $inject = shift;

    skipspace;

    my $linestr = Devel::Declare::get_linestr;
    if (substr($linestr, $Offset, 1) eq '{') {
        substr($linestr, $Offset+1, 0) = $inject;
        Devel::Declare::set_linestr($linestr);
    }
}

sub scope_injector_call {
    return ' BEGIN { MooseX::Method::Signatures::inject_scope }; ';
}

sub parser {
    local ($Declarator, $Offset) = @_;

    skip_declarator;

    my $name   = strip_name;
    my $proto  = strip_proto;
    my $inject = make_proto_unwrap($proto);

    if (defined $name) {
        $inject = scope_injector_call().$inject;
    }

    inject_if_block($inject);

    if (defined $name) {
        $name = join('::', Devel::Declare::get_curstash_name(), $name)
            unless ($name =~ /::/);
        shadow(sub (&) { no strict 'refs'; *{$name} = subname $name => shift; });
    }
    else {
        shadow(sub (&) { shift });
    }
}

sub inject_scope {
    $^H |= 0x120000;
    $^H{DD_METHODHANDLERS} = Scope::Guard->new(sub {
        my $linestr = Devel::Declare::get_linestr;
        my $offset  = Devel::Declare::get_linestr_offset;
        substr($linestr, $offset, 0) = ';';
        Devel::Declare::set_linestr($linestr);
    });
}

1;
