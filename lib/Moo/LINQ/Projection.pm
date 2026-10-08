package Moo::LINQ::Projection;

use Moo::Role;

our $VERSION = '0.02';

sub Select {
    my ($self, $mapper) = @_;
    die "Select requires a coderef" unless ref $mapper eq 'CODE';

    my $src = $self->_iterator;
    my $iter = sub {
        my $item = $src->();
        return undef unless defined $item;
        local $_ = $item;
        return $mapper->($item);
    };

    return ref($self)->new(_iterator => $iter);
}

sub SelectMany {
    my ($self, $mapper) = @_;
    die "SelectMany requires a coderef" unless ref $mapper eq 'CODE';

    my $src = $self->_iterator;
    my @buffer;

    my $iter = sub {
        while (1) {
            if (@buffer) {
                return shift @buffer;
            }

            my $item = $src->();
            return undef unless defined $item;

            my @mapped;
            {
                local $_ = $item;
                @mapped = $mapper->($item);
            }

            if (@mapped == 1 && ref $mapped[0] eq 'ARRAY') {
                @buffer = @{ $mapped[0] };
            } else {
                @buffer = @mapped;
            }
        }
    };

    return ref($self)->new(_iterator => $iter);
}

sub Cast {
    my ($self, $type) = @_;
    my %casters = (
        int    => sub { int($_[0]) },
        num    => sub { 0 + $_[0] },
        string => sub { "$_[0]" },
        uc     => sub { uc $_[0] },
        lc     => sub { lc $_[0] },
    );
    die "Unknown cast type '$type'" unless exists $casters{$type};
    return $self->Select($casters{$type});
}

1;

__END__

=head1 NAME

Moo::LINQ::Projection - Projection operators for Moo::LINQ

=head1 DESCRIPTION

Provides Select (map), SelectMany (flat-map), and Cast (type coercion).

All operators are lazy.

=cut
