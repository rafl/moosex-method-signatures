package MooseX::Method::Signatures::Meta::Method;

use Moose;
use Context::Preserve;
use Parse::Method::Signatures;
use Parse::Method::Signatures::TypeConstraint;
use Scalar::Util qw/weaken/;
use Moose::Util qw/does_role/;
use Moose::Util::TypeConstraints;
use MooseX::Meta::TypeConstraint::ForceCoercion;
use MooseX::Types::Util qw/has_available_type_export/;
use MooseX::Types::Structured qw/Tuple Dict Optional slurpy/;
use MooseX::Types::Moose qw/ArrayRef Str Maybe Object Defined CodeRef Bool/;
use aliased 'Parse::Method::Signatures::Param::Named';
use aliased 'Parse::Method::Signatures::Param::Placeholder';

use namespace::clean -except => 'meta';

extends 'Moose::Meta::Method';

has signature => (
    is       => 'ro',
    isa      => Maybe[Str],
    required => 1,
);

has _parsed_signature => (
    is      => 'ro',
    isa     => class_type('Parse::Method::Signatures::Sig'),
    lazy    => 1,
    builder => '_build__parsed_signature',
);

has _lexicals => (
    is      => 'ro',
    isa     => ArrayRef[Str],
    lazy    => 1,
    builder => '_build__lexicals',
);

has injectable_code => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_injectable_code',
);

has _positional_args => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build__positional_args',
);

has _named_args => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build__named_args',
);

has _has_slurpy_positional => (
    is   => 'rw',
    isa  => Bool,
);

has type_constraint => (
    is      => 'ro',
    isa     => class_type('Moose::Meta::TypeConstraint'),
    lazy    => 1,
    builder => '_build_type_constraint',
);

has return_signature => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_return_signature',
);

has _return_type_constraint => (
    is      => 'ro',
    isa     => class_type('Moose::Meta::TypeConstraint'),
    lazy    => 1,
    builder => '_build__return_type_constraint',
);

has actual_body => (
    is        => 'ro',
    isa       => CodeRef,
    writer    => '_set_actual_body',
    predicate => '_has_actual_body',
);

before actual_body => sub {
    my ($self) = @_;
    confess "method doesn't have an actual body yet"
        unless $self->_has_actual_body;
};

around name => sub {
    my ($next, $self) = @_;
    my $ret = $self->$next;
    confess "method doesn't have a name yet"
        unless defined $ret;
    return $ret;
};

sub _set_name {
    my ($self, $name) = @_;
    $self->{name} = $name;
}

sub _set_package_name {
    my ($self, $package_name) = @_;
    $self->{package_name} = $package_name;
}

sub wrap {
    my ($class, %args) = @_;

    $args{actual_body} = delete $args{body}
        if exists $args{body};

    my ($to_wrap, $self);

    if (exists $args{return_signature}) {
        $to_wrap = sub {
            my @args = $self->validate(\@_);
            return preserve_context { $self->actual_body->(@args) }
                after => sub {
                    if (defined (my $msg = $self->_return_type_constraint->validate(\@_))) {
                        confess $msg;
                    }
                };
        };
    } else {
        my $actual_body;
        $to_wrap = sub {
            @_ = $self->validate(\@_);
            $actual_body ||= $self->actual_body;
            goto &{ $actual_body };
        }
    }

    $self = $class->_new(%args, body => $to_wrap );

    # Vivify the type constraints so TC lookups happen before namespace::clean
    # removes them
    $self->type_constraint;
    $self->_return_type_constraint if $self->has_return_signature;

    weaken($self->{associated_metaclass})
        if $self->{associated_metaclass};

    return $self;
};

sub _build__parsed_signature {
    my ($self) = @_;
    return Parse::Method::Signatures->signature(
        input => $self->signature,
        from_namespace => $self->package_name,
    );
}

sub _build__return_type_constraint {
    my ($self) = @_;
    confess 'no return type constraint'
        unless $self->has_return_signature;

    my $parser = Parse::Method::Signatures->new(
        input => $self->return_signature,
        from_namespace => $self->package_name,
    );

    my $param = $parser->_param_typed({});
    confess 'failed to parse return value type constraint'
        unless exists $param->{type_constraints};

    return Tuple[$param->{type_constraints}->tc];
}

sub _param_to_spec {
    my ($self, $param) = @_;

    my $tc = Defined;
    {
        # Ensure errors get reported from the right place
        local $Carp::Internal{'MooseX::Method::Signatures::Meta::Method'} = 1;
        local $Carp::Internal{'Moose::Meta::Method::Delegation'} = 1;
        local $Carp::Internal{'Moose::Meta::Method::Accessor'} = 1;
        local $Carp::Internal{'MooseX::Method::Signatures'} = 1;
        local $Carp::Internal{'Devel::Declare'} = 1;
        $tc = $param->meta_type_constraint
          if $param->has_type_constraints;
    }

    if ($param->has_constraints) {
        my $cb = join ' && ', map { "sub {${_}}->(\\\@_)" } $param->constraints;
        my $code = eval "sub {${cb}}";
        $tc = subtype($tc, $code);
    }

    my %spec;
    if ($param->sigil ne '$') {
        $spec{slurpy} = 1;
        $tc = slurpy ArrayRef[$tc];
    }

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

sub _build__lexicals {
    my ($self) = @_;
    my ($sig) = $self->_parsed_signature;

    my @lexicals;
    push @lexicals, $sig->has_invocant
        ? $sig->invocant->variable_name
        : '$self';

    push @lexicals,
        (does_role($_, Placeholder)
            ? 'undef'
            : $_->variable_name)
        for (($sig->has_positional_params ? $sig->positional_params : ()),
             ($sig->has_named_params      ? $sig->named_params      : ()));

    return \@lexicals;
}

sub _build_injectable_code {
    my ($self) = @_;
    my $vars = join q{,}, @{ $self->_lexicals };
    return "my (${vars}) = \@_;";
}

sub _build__positional_args {
    my ($self) = @_;
    my $sig = $self->_parsed_signature;

    my @positional;

    push @positional, $sig->has_invocant
        ? $self->_param_to_spec($sig->invocant)
        : { tc => Object };

    my $slurpy = 0;
    if ($sig->has_positional_params) {
        for my $param ($sig->positional_params) {
            my $spec = $self->_param_to_spec($param);
            $slurpy ||= 1 if $spec->{slurpy};
            push @positional, $spec;
        }
    }

    $self->_has_slurpy_positional($slurpy);
    return \@positional;
}

sub _build__named_args {
    my ($self) = @_;
    my $sig = $self->_parsed_signature;

    # triggering building of positionals before named params is important
    # because the latter needs to know if there have been any slurpy
    # positionals to report errors
    $self->_positional_args;

    my @named;

    if ($sig->has_named_params) {
        confess 'Named parameters can not be combined with slurpy positionals'
            if $self->_has_slurpy_positional;
        for my $param ($sig->named_params) {
            push @named, $param->label => $self->_param_to_spec($param);
        }
    }

    return \@named;
}

sub _build_type_constraint {
    my ($self) = @_;
    my ($positional, $named) = map { $self->$_ } map { "_${_}_args" } qw/positional named/;

    my $tc = Tuple[
        Tuple[ map { $_->{tc}               } @{ $positional } ],
        Dict[  map { ref $_ ? $_->{tc} : $_ } @{ $named      } ],
    ];

    my $coerce_param = sub {
        my ($spec, $value) = @_;
        return $value unless exists $spec->{coerce};
        return $spec->{tc}->coerce($value);
    };

    my %named = @{ $named };

    coerce $tc,
        from ArrayRef,
        via {
            my (@positional_args, %named_args);

            my $i = 0;
            for my $param (@{ $positional }) {
                push @positional_args,
                    $#{ $_ } < $i
                        ? (exists $param->{default} ? eval $param->{default} : ())
                        : $coerce_param->($param, $_->[$i]);
                $i++;
            }

            if ($self->_has_slurpy_positional) {
                push @positional_args, @{ $_ }[$i .. $#{ $_ }];
            }
            else {
                unless ($#{ $_ } < $i) {
                    my %rest = @{ $_ }[$i .. $#{ $_ }];
                    while (my ($key, $spec) = each %named) {
                        if (exists $rest{$key}) {
                            $named_args{$key} = $coerce_param->($spec, delete $rest{$key});
                            next;
                        }

                        if (exists $spec->{default}) {
                            $named_args{$key} = eval $spec->{default};
                        }
                    }

                    @named_args{keys %rest} = values %rest;
                }
            }

            return [\@positional_args, \%named_args];
        };

    return MooseX::Meta::TypeConstraint::ForceCoercion->new(
        type_constraint => $tc,
    );
}

sub validate {
    my ($self, $args) = @_;

    my @named = grep { !ref $_ } @{ $self->_named_args };

    my $coerced;
    if (defined (my $msg = $self->type_constraint->validate($args, \$coerced))) {
        confess $msg;
    }

    return @{ $coerced->[0] }, map { $coerced->[1]->{$_} } @named;
}

__PACKAGE__->meta->make_immutable;

1;
