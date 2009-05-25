package MXMSMoody;
use Moose::Role;

has mood => (
    is => 'rw',
    isa => 'Str',
    default => sub { 'happy' }
);

1;