package MooseX::Method::Signatures::Meta::Method;

use Moose;
use MooseX::Types::Moose qw/ArrayRef/;

use namespace::clean -except => 'meta';

extends 'Moose::Meta::Method';

has _signature => (
    is       => 'ro',
    isa      => 'Parse::Method::Signatures::Sig',
    required => 1,
);

has _param_spec => (
    is         => 'ro',
    isa        => ArrayRef,
    required   => 1,
    auto_deref => 1,
);

has type_constraint => (
    is => 'ro',
    required => 1,
);

around wrap => sub {
    my ($orig, $class, %args) = @_;
    my $self;
    $self = $orig->($class, %args, body => sub {
        @_ = $self->validate(\@_);
        goto $args{body};
    });
    return $self;
};

sub validate {
    my ($self, $args) = @_;

    my @param_spec = $self->_param_spec;
    my @named = grep { !ref $_ } @param_spec;

    my $coerced = $self->type_constraint->coerce($args);
    if ($coerced == $args) {
        confess 'failed to coerce';
    }

    if (defined (my $msg = $self->type_constraint->validate($coerced))) {
        confess $msg;
    }

    return @{ $coerced->[0] }, map { $coerced->[1]->{$_} } @named;
}

__PACKAGE__->meta->make_immutable;

1;
