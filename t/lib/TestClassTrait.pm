package TestClassTrait;
use Moose;
use MooseX::Method::Signatures;

use MXMSMoody;
use MXMSLabeled;

method method_with_trait(Str :$name!) is MXMSMoody {

    return 1;
}

method method_with_two_traits() is (MXMSMoody, MXMSLabeled) {

    return 1;
}

method method_with_two_is_traits() is MXMSMoody is MXMSLabeled {

    return 1;
}

method method_with_two_is_param_traits() is MXMSMoody
    is MXMSLabeled(label => 'happy') {

    return 1;
}


no Moose;

1;
