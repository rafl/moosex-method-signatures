use strict;
use warnings;

package MooseX::Method::Signatures;

use Moose;
use Carp qw/croak/;
use Devel::Declare ();
use Parse::Method::Signatures;
use Moose::Meta::Class;
use Moose::Util::TypeConstraints;
use Moose::Util qw/does_role/;
use MooseX::Types::Moose qw/Str Defined Maybe Object ArrayRef/;
use MooseX::Types::Structured qw/Dict Tuple Optional/;
use aliased 'Parse::Method::Signatures::Param::Named';
use MooseX::Method::Signatures::Meta::Method;

use namespace::clean -except => 'meta';

our $VERSION = '0.09';

extends qw/Moose::Object Devel::Declare::MethodInstaller::Simple/;

has target => (
    is       => 'ro',
    isa      => Str,
    init_arg => 'into',
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

    my $tc = Defined;
    $tc = $param->meta_type_constraint
        if $param->has_type_constraints;

    if ($param->has_constraints) {
        my $cb = join ' && ', map { "sub {${_}}->(\\\@_)" } $param->constraints;
        my $code = eval "sub {${cb}}";
        $tc = subtype($tc, $code);
    }

    my %spec;
    $spec{tc} = $param->required
        ? $tc
        : does_role($param, Named)
            ? Optional[$tc]
            : Maybe[$tc];

    $spec{default} = $param->default_value
        if $param->has_default_value;

    if ($param->has_traits) {
        for my $trait (@{ $param->param_traits }) {
            next unless $trait->[1] eq 'coerce';
            $spec{coerce} = 1;
        }
    }

    return \%spec;
}

sub parse_proto {
    my ($self, $proto) = @_;
    $proto ||= '';

    my $vars = q{};
    my (@named, @positional);

    my $sig = Parse::Method::Signatures->signature(
        input => "(${proto})",
        type_constraint_callback => sub {
            my ($tc, $name) = @_;
            my $code = $self->target->can($name);
            return $code
                ? eval { $code->() }
                : $tc->find_registered_constraint($name);
        },
    );
    croak "Invalid method signature (${proto})"
        unless $sig;

    if ($sig->has_invocant) {
        my $invocant = $sig->invocant;
        $vars .= $invocant->variable_name . q{,};
        push @positional, $self->param_to_spec($invocant);
    }
    else {
        $vars .= '$self,';
        push @positional, { tc => Object };
    }

    if ($sig->has_positional_params) {
        for my $param ($sig->positional_params) {
            $vars .= $param->variable_name . q{,};
            push @positional, $self->param_to_spec($param);
        }
    }

    if ($sig->has_named_params) {
        for my $param ($sig->named_params) {
            $vars .= $param->variable_name . q{,};
            push @named, $param->label => $self->param_to_spec($param);
        }
    }

    my $tc = Tuple[
        Tuple[ map { $_->{tc}               } @positional ],
        Dict[  map { ref $_ ? $_->{tc} : $_ } @named      ],
    ];

    my $coerce_param = sub {
        my ($spec, $value) = @_;
        return $value unless exists $spec->{coerce};
        return $spec->{tc}->coerce($value);
    };

    my %named = @named;

    coerce $tc,
        from ArrayRef,
        via {
            my (@positional_args, %named_args);

            my $i = 0;
            for my $param (@positional) {
                push @positional_args,
                    $#{ $_ } < $i
                        ? (exists $param->{default} ? $param->{default} : ())
                        : $coerce_param->($param, $_->[$i]);
                $i++;
            }

            unless ($#{ $_ } < $i) {
                my %rest = @{ $_ }[$i .. $#{ $_ }];
                while (my ($key, $spec) = each %named) {
                    if (exists $rest{$key}) {
                        $named_args{$key} = $coerce_param->($spec, delete $rest{$key});
                        next;
                    }

                    if (exists $spec->{default}) {
                        $named_args{$key} = $spec->{default};
                    }
                }

                @named_args{keys %rest} = values %rest;
            }

            return [\@positional_args, \%named_args];
        };

    return ($sig, $vars, [@positional, @named], $tc);
}

sub inject_parsed_proto {
    my ($self, $vars) = @_;
    return "my (${vars}) = \@_;";
}

sub parser {
    my $self = shift;
    $self->init(@_);

    $self->skip_declarator;
    my $name   = $self->strip_name;
    my $proto  = $self->strip_proto;
    my $attrs  = $self->strip_attrs;
    my ($sig, $vars, $param_spec, $tc) = $self->parse_proto($proto);
    my $inject = $self->inject_parsed_proto($vars);

    if (defined $name) {
        $inject = $self->scope_injector_call() . $inject;
    }

    $self->inject_if_block($inject, $attrs ? "sub ${attrs} " : '');

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
        return MooseX::Method::Signatures::Meta::Method->wrap(
            _signature      => $sig,
            _param_spec     => $param_spec,
            body            => $code,
            package_name    => $pkg,
            name            => $meth_name,
            type_constraint => $tc,
        );
    };

    if (defined $name) {
        $self->shadow(sub (&) {
            my ($code) = @_;
            my $meth = $create_meta_method->($code);
            my $meta = Moose::Meta::Class->initialize($pkg);
            $meta->add_method($meth_name => $meth);
            return;
        });
    }
    else {
        $self->shadow(sub (&) {
            return $create_meta_method->(shift);
        });
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=head1 NAME

MooseX::Method::Signatures - Method declarations with type constraints and no source filter

=head1 SYNOPSIS

    package Foo;

    use Moose;
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

=head2 Traits

    method foo (Affe $bar does trait)
    method foo (Affe $bar is trait)

The only currently supported trait is C<coerce>, which will attempt to coerce
the value provided if it doesn't satisfy the requirements of the type
constraint.

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

=head3 Methods not seen by a role's C<requires>

Because the processing of the L<MooseX::Method::Signatures>
C<method> and the L<Moose> C<with> keywords are both
done at runtime, it can happen that a role will require
a method before it is declared (which will cause
Moose to complain very loudly and abort the program).

For example, the following will not work:

    # in file Canine.pm

    package Canine;

    use Moose;
    use MooseX::Method::Signatures;

    with 'Watchdog';

    method bark { print "Woof!\n"; }

    1;


    # in file Watchdog.pm

    package Watchdog;

    use Moose::Role;

    requires 'bark';  # will assert! evaluated before 'method' is processed

    sub warn_intruder {
        my $self = shift;
        my $intruder = shift;

        $self->bark until $intruder->gone;
    }

    1;


A workaround for this problem is to use C<with> only
after the methods have been defined.  To take our previous
example, B<Canine> could be reworked thus:

    package Canine;

    use Moose;
    use MooseX::Method::Signatures;

    method bark { print "Woof!\n"; }

    with 'Watchdog';

    1;


A better solution is to use L<MooseX::Declare> instead of plain
L<MooseX::Method::Signatures>. It defers application of roles until the end
of the class definition. With it, our example would becomes:


    # in file Canine.pm

    use MooseX::Declare;

    class Canine with Watchdog {

        method bark { print "Woof!\n"; }

    }

    1;

    # in file Watchdog.pm

    use MooseX::Declare;

    role Watchdog {

        requires 'bark';

        method warn_intruder ( $intruder ) {
            $self->bark until $intruder->gone;
        }
    }

    1;


=head3 I<Subroutine redefined> warnings

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
