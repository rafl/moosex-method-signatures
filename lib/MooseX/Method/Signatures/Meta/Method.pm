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

    my @ret = MooseX::Meta::Signature::Combined->new(@param_spec)->validate(@{ $args });
    return @ret unless @named;

    my $named_vals = pop @ret;
    return (@ret, map { $named_vals->{$_} } @named);
}

__PACKAGE__->meta->make_immutable;

1;
