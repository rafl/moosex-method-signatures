
use strict;
use warnings;

use Test::More tests => 4;                      # last test to print

{
    package Optional;
    use MooseX::Method::Signatures;
    method foo ($arg?) {
        $arg;
    }

    method bar ($hr = {}) {
        ++$hr->{bar};
    }
}

is( Optional->foo(), undef);
is( Optional->foo(1), 1);
is( Optional->bar(), 1);
is( Optional->bar({bar=>1}), 2);

__END__
1..4
) required, found  '{'! at /opt/perl/lib/site_perl/5.10.0/Parse/Method/Signatures.pm line 556
	Parse::Method::Signatures::assert_token('Parse::Method::Signatures=HASH(0x2252000)', ')') called at /opt/perl/lib/site_perl/5.10.0/Parse/Method/Signatures.pm line 179
	Parse::Method::Signatures::signature('Parse::Method::Signatures', 'input', '($hr = {})', 'type_constraint_callback', 'CODE(0x2251dc0)') called at /opt/perl/lib/site_perl/5.10.0/MooseX/Method/Signatures.pm line 90
	MooseX::Method::Signatures::parse_proto('MooseX::Method::Signatures=HASH(0x20f80b0)', '$hr = {}') called at /opt/perl/lib/site_perl/5.10.0/MooseX/Method/Signatures.pm line 134
	MooseX::Method::Signatures::parser('MooseX::Method::Signatures=HASH(0x20f80b0)', 'method', 4) called at /opt/perl/lib/site_perl/5.10.0/x86_64-linux/Devel/Declare/MethodInstaller/Simple.pm line 23
	Devel::Declare::MethodInstaller::Simple::__ANON__('method', 4) called at /opt/perl/lib/site_perl/5.10.0/x86_64-linux/Devel/Declare.pm line 274
	Devel::Declare::linestr_callback('const', 'method', 4) called at t/sigs-optional.t line 14
# Looks like your test exited with 255 before it could output anything.
