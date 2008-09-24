use strict;
use warnings;

package MooseX::Method::Signatures;

use Carp qw/croak/;
use Sub::Name;
use Scope::Guard;
use Devel::Declare ();
use Perl6::Signature;
use Moose::Util::TypeConstraints ();
use MooseX::Meta::Signature::Combined;

our $VERSION = '0.02';

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

sub param_to_spec {
    my ($param, $required) = @_;
    $required ||= 0;

    my $spec = q{};
    my $type;

    if (my @types = @{ $param->p_types }) {
        $type = join '|', @types;
        $type = qq{'${type}'};
    }

    if (my $constraints = $param->p_constraints) {
        my $cb = join ' && ', map { "sub {${_}}->(\\\@_)" } @{ $constraints };
        $type = "Moose::Util::TypeConstraints::subtype(${type}, sub {${cb}})";
    }

    my $default = $param->p_default;

    $spec .= "{";
    $spec .= "required => ${required},";
    $spec .= "isa => ${type}," if defined $type;
    $spec .= "default => ${default}," if defined $default;
    $spec .= "},";

    return $spec;
}

sub parse_proto {
    my ($proto) = @_;
    my ($vars, $param_spec) = (q//) x 2;

    my $sig = Perl6::Signature->parse(":(${proto})");
    croak "Invalid method signature (${proto})"
        unless $sig;

    if (my $invocant = $sig->s_invocant) {
        $vars       .= $invocant->p_variable . q{,};
        $param_spec .= param_to_spec($invocant, 1);
    }
    else {
        $vars       .= '$self,';
        $param_spec .= '{ required => 1 },';
    }

    my $i = 1;
    for my $param (@{ $sig->s_positionalList }) {
        $vars .= $param->p_variable . q{,};

        my $required = $i > $sig->s_requiredPositionalCount ? 0 : 1;
        $param_spec .= param_to_spec($param, $required);

        $i++;
    }

    for my $param (@{ $sig->s_namedList }) {
        $vars .= $param->p_variable . q{,};

        my $label    = $param->p_label;
        my $required = $sig->s_requiredNames->{ $label };
        $param_spec .= "${label} => " . param_to_spec($param, $required);
    }

    return ($vars, $param_spec);
}

sub make_proto_unwrap {
    my ($proto) = @_;

    if (!defined $proto) {
        $proto = '';
    }

    my ($vars, $param_spec) = parse_proto($proto);
    my $inject = "my (${vars}) = MooseX::Meta::Signature::Combined->new(${param_spec})->validate(\@_);";

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

__END__
=head1 NAME

MooseX::Method::Signatures - Method declarations with type constraints and no source filter

=head1 SYNOPSIS

    package Foo;

    use MooseX::Method::Signatures;

    method morning (Str $name) {
        $self->say("Good morning ${name}!");
    }

    method hello (Str :$who, Int :$age where { $_ > 0 }) {
        $self->say("Hello ${who}, I am ${age} years old!");
    }

    method greet (Str $name, Bool :$excited = 0) {
        if ($excited) {
            $self->say("GREETINGS ${name}!");
        }
        else {
            $self->say("Hi ${name}!");
        }
    }

    $foo->morning('Resi');                          # This works.

    $foo->hello(who => 'world', age => 42);         # This too.

    $foo->greet('Resi', excited => 1);              # And this as well.

    $foo->hello(who => 'world', age => 'fortytwo'); # This doesn't.

    $foo->hello(who => 'world', age => -23);        # This neither.

    $foo->morning;                                  # Won't work.

    $foo->greet;                                    # Will fail.

=head1 DISCLAIMER

This is B<ALPHA SOFTWARE>. Use at your own risk. Features may change.

=head1 DESCRIPTION

Provides a proper method keyword, like "sub" but specificly for making methods
and validating their arguments against Moose type constraints.

=head1 SIGNATURE SYNTAX

The signature syntax is heavily based on Perl 6. However not the full Perl 6
signature syntax is supported yet and some of it never will be.

=head2 Type Constraints

    method foo ($affe)        # no type checking
    method bar (Animal $affe) # $affe->isa('Animal')

=for later, when p6::signatures is fixed
    method baz (Animal|Human $affe) # $affe->isa('Animal') || $affe->isa('Human')
=back

=head2 Positional vs. Named

    method foo ( $a,  $b,  $c) # positional
    method bar (:$a, :$b, :$c) # named
    method baz ( $a,  $b, :$c) # combined

=head2 Required vs. Optional

    method foo ($a , $b!, :$c!, :$d!) # required
    method bar ($a?, $b?, :$c , :$d?) # optional

=for later, when mx::method::signature::combined is fixed
    method baz ($a , $b?, :$c ,  $d?) # combined
=back

=head2 Defaults

    method foo ($a = 42) # defaults to 42

=head2 Constraints

    method foo ($foo where { $_ % 2 == 0 }) # only even

=head2 Invocant

    method foo (        $moo) # invocant is called $self and is required
    method bar ($self:  $moo) # same, but explicit
    method baz ($class: $moo) # invocant is called $self

=head2 Labels

    method foo (:     $affe ) # called as $obj->foo(affe => $value)
    method bar (:apan($affe)) # called as $obj->foo(apan => $value)

=head2 Complex Example

    method foo ( SomeClass $thing where { $_->can('stuff') }:
                 Str  $bar  = "apan"
                 Int :$baz! = 42 where { $_ % 2 == 0 } where { $_ > 10 } )

    # the invocant is called $thing, must be an instance of SomeClass and
           has to implement a 'stuff' method
    # $bar is positional, required, must be a string and defaults to "affe"
    # $baz is named, required, must be an integer, defaults to 42 and needs
    #      to be even and greater than 10

=head1 BUGS, CAVEATS AND NOTES

=head2 Non-scalar parameters

Currently parameters that aren't scalars are unsupported. This is going to
change soon.

=head2 Fancy signatures

L<Perl6::Signature> is used to parse the signatures. However, some signatures
that can be parsed by it aren't supported by this module (yet).

=head2 Debugging

This totally breaks the debugger.  Will have to wait on Devel::Declare fixes.

=head2 No source filter

While this module does rely on the hairy black magic of L<Devel::Declare> it
does not depend on a source filter. As such, it doesn't try to parse and
rewrite your source code and there should be no weird side effects.

Devel::Declare only effects compilation. After that, it's a normal subroutine.
As such, for all that hairy magic, this module is surprisnigly stable.

=head2 What about regular subroutines?

L<Devel::Declare> cannot yet change the way C<sub> behaves.

=head2 What about the return value?

Currently there is no support for types or declaring the type of the return
value.

=head1 SEE ALSO

L<Method::Signatures>

L<MooseX::Method>

L<Perl6::Subs>

L<Devel::Declare>

L<Perl6::Signature>

L<Moose>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008  Florian Ragwitz

Code based on the tests for L<Devel::Declare>.

Documentation based on L<MooseX::Method> and L<Method::Signatures>.

Licensed under the same terms as Perl itself.

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=cut
