use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal;

local $TODO = 'RT#75054';

{
    package Account;
    use Moose;
    use MooseX::LazyRequire;

    has password => (
        is  => 'rw',
        isa => 'Str',
    );

    package AccountExt;

    use Moose;
    extends 'Account';
    use MooseX::LazyRequire;
    use Carp;

    has '+password' => (
        is            => 'ro',
        # Probably there also should be:
        # traits => ['LazyRequire'],
        # but I'm not sure
        lazy_required => 1,
    );

}
my $r = AccountExt->new;
like(
    exception { $r->password },
    qr/Attribute password must be provided before calling reader/,
    'works on inherited attributes'
);

