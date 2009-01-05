use strict;
use warnings;

package MooseX::Method::Signatures;

use Moose;
use Carp qw/croak/;
use Devel::Declare ();
use Parse::Method::Signatures;
use Moose::Meta::Class;
use Moose::Meta::Method;
use Moose::Util::TypeConstraints ();
use MooseX::Meta::Signature::Combined;
use MooseX::Types::Moose qw/Str/;

use namespace::clean -except => 'meta';

our $VERSION = '0.06';

extends qw/Moose::Object Devel::Declare::MethodInstaller::Simple/;

has target => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'into',
    required => 1,
);

has keyword => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'name',
    required => 1,
);

sub import {
    my ($class) = @_;
    my $caller = caller();
    $class->setup_for($caller);
}

sub setup_for {
    my ($class, $pkg) = @_;

    $class->install_methodhandler(
        into => $pkg,
        name => 'method',
    );

    return;
}

sub param_to_spec {
    my ($self, $param) = @_;

    my $spec = q{};
    my $type;

    if ($param->has_type_constraints) {
        $type = join '|', $param->type_constraints;
        $type = qq{'${type}'};
    }

    if ($param->has_constraints) {
        my $cb = join ' && ', map { "sub {${_}}->(\\\@_)" } $param->constraints;
        $type = "Moose::Util::TypeConstraints::subtype(${type}, sub {${cb}})";
    }

    my $required = $param->required ? 1 : 0;

    $spec .= "{";
    $spec .= "required => ${required},";
    $spec .= "isa => ${type}," if defined $type;
    $spec .= "default => ${\$param->default_value}," if $param->has_default_value;
    $spec .= "},";

    return $spec;
}

sub parse_proto {
    my ($self, $proto) = @_;
    $proto ||= '';
    my ($vars, $param_spec) = (q//) x 2;

    my $sig = Parse::Method::Signatures->signature("(${proto})");
    croak "Invalid method signature (${proto})"
        unless $sig;

    if ($sig->has_invocant) {
        my $invocant = $sig->invocant;
        $vars       .= $invocant->variable_name . q{,};
        $param_spec .= $self->param_to_spec($invocant);
    }
    else {
        $vars       .= '$self,';
        $param_spec .= '{ required => 1 },';
    }

    if ($sig->has_positional_params) {
        for my $param ($sig->positional_params) {
            $vars .= $param->variable_name . q{,};
            $param_spec .= $self->param_to_spec($param);
        }
    }

    if ($sig->has_named_params) {
        for my $param ($sig->named_params) {
            $vars .= $param->variable_name . q{,};

            my $label    = $param->label;
            $param_spec .= "${label} => " . $self->param_to_spec($param);
        }
    }

    return ($vars, $param_spec);
}

sub inject_parsed_proto {
    my ($self, $vars, $param_spec) = @_;
    return "my (${vars}) = MooseX::Method::Signatures::validate(\\\@_, ${param_spec});";
}

sub code_for {
    my ($self, $name) = @_;

    my $pkg;
    my $meth_name = defined $name
        ? $name
        : '__ANON__';

    if ($meth_name =~ /::/) {
        ($pkg, $meth_name) = $meth_name =~ /^(.*)::([^:]+)$/;
    }
    else {
        $pkg = $self->get_curstash_name;
    }

    my $create_meta_method = sub {
        my ($code) = @_;
        return Moose::Meta::Method->wrap(
            body         => $code,
            package_name => $pkg,
            name         => $meth_name,
        );
    };

    if (defined $name) {
        return sub (&) {
            my ($code) = @_;
            my $meth = $create_meta_method->($code);
            my $meta = Moose::Meta::Class->initialize($pkg);
            $meta->add_method($meth_name => $meth);
            return;
        };
    }
    else {
        return sub (&) {
            return $create_meta_method->(shift);
        };
    }
}

sub validate {
    my ($args, @param_spec) = @_;

    my @named = grep { !ref $_ } @param_spec;
    my @ret = MooseX::Meta::Signature::Combined->new(@param_spec)->validate(@{ $args });
    return @ret unless @named;

    my $named_vals = pop @ret;
    return (@ret, map { $named_vals->{$_} } @named);
}

__PACKAGE__->meta->make_immutable;

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

    method foo (             $affe) # no type checking
    method bar (Animal       $affe) # $affe->isa('Animal')
    method baz (Animal|Human $affe) # $affe->isa('Animal') || $affe->isa('Human')

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
    method baz ($class: $moo) # invocant is called $class

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

L<Parse::Method::Signatures> is used to parse the signatures. However, some
signatures that can be parsed by it aren't supported by this module (yet).

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

=head2 Interaction with L<Moose::Role>

When composing a L<Moose::Role> into a class that uses
L<MooseX::Method::Signatures>, you may get a "Subroutine redefined"
warning. This happens when both the role and the class define a
method/subroutine of the same name. (The way roles work, the one
defined in the class takes precedence) To eliminate this warning,
make sure that your C<with> declaration happens after any
method/subroutine declarations that may have the same name as a
method/subroutine within a role.

=head1 SEE ALSO

L<Method::Signatures>

L<MooseX::Method>

L<Perl6::Subs>

L<Devel::Declare>

L<Parse::Method::Signatures>

L<Moose>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008  Florian Ragwitz

Code based on the tests for L<Devel::Declare>.

Documentation based on L<MooseX::Method> and L<Method::Signatures>.

Licensed under the same terms as Perl itself.

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=cut
