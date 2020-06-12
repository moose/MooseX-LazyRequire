use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

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

    package AccountExt::Lax;
    
    use Moose;
    extends 'AccountExt';
    use MooseX::LazyRequire;

    has '+password' => (
        lazy_required => 0,
        default       => sub { 'hunter2' },
    );
}
my $r = AccountExt->new;

my $e = exception { $r->password };
isnt($e, undef, 'works on inherited attributes: exception') &&
like(
    exception { $r->password },
    qr/Attribute 'password' must be provided before calling reader/,
    'works on inherited attributes: mentions password by name'
);

my $lax = AccountExt::Lax->new;
is($lax->password, 'hunter2', 'We can override LazyRequired *off* as well');

done_testing;
