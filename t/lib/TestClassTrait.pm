package TestClassTrait;
use Moose;
use MooseX::Method::Signatures;

use aliased 'MXMSLabeled', 'Label';
use aliased 'MXMSMoody', 'Moody';

method method_with_trait (Str :$name!) is Moody {
    return 1;
}

method method_with_two_traits () is (Moody, Label) {
    return 1;
}

method method_with_two_is_traits () is Moody is Label {
    return 1;
}

method method_with_two_is_param_traits () is Moody
    is Label(label => 'happy') {
    return 1;
}

no Moose;

1;
