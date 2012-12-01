use strict;
use warnings;
use Test::More 0.88;
use Test::Fatal;

{
    package Foo;
    use Moose;
    use MooseX::LazyRequire;

    has bar => (
        is            => 'ro',
        lazy_required => 1,
    );

    has baz => (
        is      => 'ro',
        builder => '_build_baz',
    );

    sub _build_baz { shift->bar + 1 }
}

{
    my $foo;
    is(
        exception { $foo = Foo->new(bar => 42) },
        undef,
    );
    is($foo->baz, 43);
}

{
    my $foo;
    is(
        exception { $foo = Foo->new(baz => 23) },
        undef,
        'can set other attr explicitly without interfering',
    );
    is($foo->baz, 23);
}

like(
    exception { Foo->new },
    qr/Attribute bar must be provided/,
);

{
    package Bar;
    use Moose;
    use MooseX::LazyRequire;

    has foo => (
        is            => 'rw',
        lazy_required => 1,
    );

    has baz => (
        is      => 'ro',
        lazy    => 1,
        builder => '_build_baz',
    );

    sub _build_baz { shift->foo + 1 }
}

{
    my $bar = Bar->new;

    like(
        exception { $bar->baz },
        qr/Attribute foo must be provided/,
        'lazy_required dependency is not satisfied',
    );

    $bar->foo(42);

    my $baz;
    is(
        exception { $baz = $bar->baz },
        undef,
        'lazy_required dependency is satisfied',
    );

    is($baz, 43, 'builder uses correct value');
}

SKIP:
{
    skip 'These tests require Moose 1.9900+', 3
        unless $Moose::VERSION >= 1.9900;

{
    package Role;
    use Moose::Role;
    use MooseX::LazyRequire;

    has foo => (
        is            => 'rw',
        lazy_required => 1,
    );

    has baz => (
        is      => 'ro',
        lazy    => 1,
        builder => '_build_baz',
    );

    sub _build_baz { shift->foo + 1 }
}

{
    package Quux;
    use Moose;
    with 'Role';
}

{
    my $bar = Quux->new;

    like(
        exception { $bar->baz },
        qr/Attribute foo must be provided/,
        'lazy_required dependency is not satisfied (in a role)',
    );

    $bar->foo(42);

    my $baz;
    is(
        exception { $baz = $bar->baz },
        undef,
        'lazy_required dependency is satisfied (in a role)',
    );

    is($baz, 43, 'builder uses correct value (in a role)');
}
}

done_testing;
