package MooseX::LazyRequire::Meta::Attribute::Trait::LazyRequire;
# ABSTRACT: Attribute trait to make getters fail on unset attributes

our $VERSION = '0.12';

use Moose::Role;
use Carp qw/cluck/;
use namespace::autoclean;

has lazy_required => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
);

after _process_options => sub {
    my ($class, $name, $options) = @_;

    if (exists $options->{lazy_require}) {
        cluck "deprecated option 'lazy_require' used. use 'lazy_required' instead.";
        $options->{lazy_required} = delete $options->{lazy_require};
    }

    return unless $options->{lazy_required};

    $class->_enable_lazy_required($name, $options);
};

sub _enable_lazy_required {
    my ($class, $name, $options) = @_;
    
    # lazy_required + default or builder doesn't make sense because if there
    # is a default/builder, the reader will always be able to return a value.
    Moose->throw_error(
        "You may not use both a builder or a default and lazy_required for one attribute ($name)",
        data => $options,
    ) if $options->{builder} or $options->{default};

    $options->{ lazy     } = 1;
    $options->{ required } = 1;
    $options->{ default  } = sub {
        confess "Attribute '$name' must be provided before calling reader"
    };
};

around clone_and_inherit_options => sub {
    my ($orig, $self, %options) = @_;

    if ($options{lazy_required}) {
        $self->_enable_lazy_required($self->name, \%options);
    } else {
        for my $boolean_option (qw(lazy required)) {
            if (!exists $options{$boolean_option}) {
                $options{$boolean_option} = 0;
            }
        }
        ### FIXME: can we say "no, don't provide a default"?
        if (!exists $options{default}) {
            $options{default} = undef;
        }
    }
    $self->$orig(%options);
};

package # hide
    Moose::Meta::Attribute::Custom::Trait::LazyRequire;

sub register_implementation { 'MooseX::LazyRequire::Meta::Attribute::Trait::LazyRequire' }

1;
