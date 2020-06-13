package MooseX::LazyRequire;
# ABSTRACT: Required attributes which fail only when trying to use them
# KEYWORDS: moose extension attribute required lazy defer populate method

our $VERSION = '0.12';

use Moose 0.94 ();
use Moose::Exporter;
use aliased 0.30 'MooseX::LazyRequire::Meta::Attribute::Trait::LazyRequire';
use namespace::autoclean;

=head1 SYNOPSIS

    package Foo;

    use Moose;
    use MooseX::LazyRequire;

    has foo => (
        is            => 'ro',
        lazy_required => 1,
    );

    has bar => (
        is      => 'ro',
        builder => '_build_bar',
    );

    sub _build_bar { shift->foo }


    Foo->new(foo => 42); # succeeds, foo and bar will be 42
    Foo->new(bar => 42); # succeeds, bar will be 42
    Foo->new;            # fails, neither foo nor bare were given

    package Foo::Nevermind;

    use Moose;
    use MooseX::LazyRequire;
    extends 'Foo';

    has foo => ( lazy_required => 0 );

    Foo::Nevermind->new;    # succeeds

=head1 DESCRIPTION

This module adds a C<lazy_required> option to Moose attribute declarations.

The reader methods for all attributes with that option will throw an exception
unless a value for the attributes was provided earlier by a constructor
parameter or through a writer method.

You can override an attribute declaration in a parent class, either enabling
or disabling lazy-required. Note, though, that because lazy_required works by
declaring a default value that's evaluated lazily, if you say "never mind, this
attribute isn't lazy-required any more", you I<still> need to provide a
default value or coderef. B<Especially> if C<undef> isn't a valid value for
your attribute, because that's what MooseX::LazyRequire will try to enforce
in the absence of any better guidance.

=head1 CAVEATS

Prior to Moose 1.9900, roles didn't have an attribute metaclass, so this module can't
easily apply its magic to attributes defined in roles. If you want to use
C<lazy_required> in role attributes, you'll have to apply the attribute trait
yourself:

    has foo => (
        traits        => ['LazyRequire'],
        is            => 'ro',
        lazy_required => 1,
    );

With Moose 1.9900, you can use this module in roles just the same way you can
in classes.

=cut

my %metaroles = (
    class_metaroles => {
        attribute => [LazyRequire],
    },
);

$metaroles{role_metaroles} = {
    applied_attribute => [LazyRequire],
    }
    if $Moose::VERSION >= 1.9900;

Moose::Exporter->setup_import_methods(%metaroles);

1;

=begin Pod::Coverage

init_meta

=end Pod::Coverage
