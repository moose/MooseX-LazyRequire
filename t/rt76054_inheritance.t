use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

{
    # Our base class has an attribute that's nothing special.
    package Account;
    use Moose;
    use MooseX::LazyRequire;

    has password => (
        is  => 'rw',
        isa => 'Str',
    );

    # The extended class wants you to specify a password, eventually.
    package AccountExt;

    use Moose;
    extends 'Account';
    use MooseX::LazyRequire;

    has '+password' => (
        is            => 'ro',
        lazy_required => 1,
    );

    # A further subclass insists that you supply the password immediately.
    package AccountExt::Harsh;

    use Moose;
    extends 'AccountExt';
    use MooseX::LazyRequire;

    has '+password' => (
        is            => 'ro',
        lazy_required => 0,
        required      => 1,
    );

    # Another subclass makes the attribute lazy.
    package AccountExt::Lazy;

    use Moose;
    extends 'AccountExt';
    use MooseX::LazyRequire;

    $AccountExt::Lazy::default_password = 'password';
    has '+password' => (
        lazy_required => 0,
        lazy          => 1,
        default       => sub { $AccountExt::Lazy::default_password },
    );

    # Another subclass will supply one for you if you don't specify one.
    package AccountExt::Lax::Default;

    use Moose;
    extends 'AccountExt';
    use MooseX::LazyRequire;

    has '+password' => (
        lazy_required => 0,
        default       => sub { 'hunter2' },
    );

    # But if you don't override the default, you're SOL.
    package AccountExt::Lax::Woo;

    use Moose;
    extends 'AccountExt';
    use MooseX::LazyRequire;

    has '+password' => (lazy_required => 0);
}

# In the extension class, asking about a password generates an exception,
# when you ask about it.
my $account_ext = AccountExt->new;
my $exception_ext_password = exception { $account_ext->password };
isnt($exception_ext_password, undef,
    'works on inherited attributes: exception')
&& like(
    $exception_ext_password,
    qr/Attribute 'password' must be provided before calling reader/,
    'works on inherited attributes: mentions password by name'
);
my $attribute_ext = $account_ext->meta->find_attribute_by_name('password');
ok($attribute_ext->lazy_required,
    'The inherited attribute is now lazy-required');

# The harsh subclass generates an exception as soon as you don't provide a
# password.
my $exception_harsh_constructor = exception { AccountExt::Harsh->new };
isnt($exception_harsh_constructor, undef,
    'Cannot create a harsh object without a password');

# The lazy subclass will use a lazily-generated value.
my $lazy = AccountExt::Lazy->new;
{
    local $AccountExt::Lazy::default_password = 'qwerty';
    is($lazy->password, 'qwerty',
        'The lazy object resolves its default value as late as possible'
    );
}

# The lax subclass is happy to provide you with a default password.
my $account_ext_lax_default = AccountExt::Lax::Default->new;
is($account_ext_lax_default->password,
    'hunter2',
    'We can override LazyRequired *off* as well');

# The woo subclass really wants to be the base subclass, but can't, because
# a default option got in the way in the inheritance hierarchy.
my $exception_ext_woo_password = exception { AccountExt::Lax::Woo->new };
like(
    $exception_ext_woo_password,
    qr/Attribute .+ password .+ \Qdoes not pass the type constraint\E/x,
    'Falling back to undef as a last resort violates type constraints'
);

done_testing;
