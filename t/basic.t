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
    );
    is($foo->baz, 23);
}

like(
    exception { Foo->new },
    qr/must be provided/,
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
        qr/must be provided/,
    );

    $bar->foo(42);

    my $baz;
    is(
        exception { $baz = $bar->baz },
        undef,
    );

    is($baz, 43);
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
        qr/must be provided/,
    );

    $bar->foo(42);

    my $baz;
    is(
        exception { $baz = $bar->baz },
        undef,
);

    is($baz, 43);
}
}

done_testing;
