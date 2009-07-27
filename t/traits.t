use strict;
use warnings;
use Test::More tests => 12;

use FindBin;
use lib "$FindBin::Bin/lib";

use TestClassTrait;

use Moose::Util qw(does_role);

my $c = TestClassTrait->new;

my $method = $c->meta->get_method('method_with_trait');
isa_ok($method, 'MooseX::Method::Signatures::Meta::Method');

ok(does_role($method, 'MXMSMoody'), 'method has MXMSMoody trait');
cmp_ok($method->mood, 'eq', 'happy', 'method is happy');

my $tt_method = $c->meta->get_method('method_with_two_traits');
isa_ok($tt_method, 'MooseX::Method::Signatures::Meta::Method');

ok(does_role($tt_method, 'MXMSMoody'), 'method has MXMSMoody trait');
ok(does_role($tt_method, 'MXMSLabeled'), 'method has MXMSLabeled trait');

my $twois_method = $c->meta->get_method('method_with_two_is_traits');
ok(does_role($twois_method, 'MXMSMoody'), 'two is method has MXMSMoody trait');
ok(does_role($twois_method, 'MXMSLabeled'), 'two is method has MXMSLabeled trait');

my $param_method = $c->meta->get_method('method_with_two_is_param_traits');
ok(does_role($twois_method, 'MXMSMoody'), 'param method has MXMSMoody trait');
ok(does_role($twois_method, 'MXMSLabeled'), 'param method has MXMSLabeled trait');

ok($param_method->has_label, 'method has label');
cmp_ok($param_method->label, 'eq', 'happy', 'label is happy');
