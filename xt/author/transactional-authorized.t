use Test::More;
use Test::Moose;

{ package MyClass;
  use Moose;
  use MooseX::Method::Signatures;
  use aliased 'MooseX::Meta::Method::Transactional';
  use aliased 'MooseX::Meta::Method::Authorized';

  has user => (is => 'ro');
  has schema => (is => 'ro');

  # this was supposed to die, but the trait is not really applied.
  method m01 does Transactional does Authorized(requires => ['foo']) { 'm01' }
  method m02 does Transactional { 'm02' }
  method m03 does Authorized(requires => ['gah']) { 'm03' }
  method m04 does Transactional does Authorized(requires => ['gah']) { 'm01' }

};
{ package MySchema;
  use Moose;
  sub txn_do {
      my $self = shift;
      my $code = shift;
      return 'txn_do '.$code->(@_);
  }
};
{ package MyUser;
  use Moose;
  sub roles { qw<foo bar baz> }
};

my $meth = MyClass->meta->get_method('m01');
my $obj = MyClass->new({user => MyUser->new, schema => MySchema->new });

is($obj->m01, 'txn_do m01', 'applying both roles work.');
is($obj->m02, 'txn_do m02', 'Applyign just Transactional');
eval {
    $obj->m03;
};
like($@.'', qr(Access Denied)i, $@);

eval {
    $obj->m04;
};
like($@.'', qr(Access Denied)i, $@);

done_testing();
1;
