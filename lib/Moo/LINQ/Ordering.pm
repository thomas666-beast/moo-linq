package Moo::LINQ::Ordering;

use Moo::Role;
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.04';

sub _sort_with_spec {
    my ($self, $spec) = @_;

    my @items;
    my $iter = $self->_iterator;
    while (defined(my $item = $iter->())) {
        push @items, $item;
    }

    my @sorted = sort {
        for my $rule (@$spec) {
            my ($key_fn, $dir, $type) = @$rule;
            $type //= 'auto';

            my ($ka, $kb);
            { local $_ = $a; $ka = $key_fn->($a); }
            { local $_ = $b; $kb = $key_fn->($b); }

            my $cmp;
            if (!defined $ka && !defined $kb) {
                $cmp = 0;
            } elsif (!defined $ka) {
                $cmp = -1;
            } elsif (!defined $kb) {
                $cmp = 1;
            } elsif ($type eq 'numeric') {
                $cmp = $ka <=> $kb;
            } elsif ($type eq 'string') {
                $cmp = $ka cmp $kb;
            } elsif (looks_like_number($ka) && looks_like_number($kb)) {
                $cmp = $ka <=> $kb;
            } else {
                $cmp = $ka cmp $kb;
            }

            next if $cmp == 0;
            return $dir eq 'desc' ? -$cmp : $cmp;
        }
        return 0;
    } @items;

    my $i = 0;
    my $out_iter = sub {
        return $i < @sorted ? $sorted[$i++] : undef;
    };

    return ref($self)->new(_iterator => $out_iter, _sort_spec => $spec);
}

sub OrderBy {
    my ($self, $key_fn, $type) = @_;
    die "OrderBy requires a coderef" unless ref $key_fn eq 'CODE';
    $type //= 'auto';
    die "Unknown sort type '$type'"
        unless $type =~ /\A(?:auto|numeric|string)\z/;
    return $self->_sort_with_spec([ [ $key_fn, 'asc', $type ] ]);
}

sub OrderByDescending {
    my ($self, $key_fn, $type) = @_;
    die "OrderByDescending requires a coderef" unless ref $key_fn eq 'CODE';
    $type //= 'auto';
    die "Unknown sort type '$type'"
        unless $type =~ /\A(?:auto|numeric|string)\z/;
    return $self->_sort_with_spec([ [ $key_fn, 'desc', $type ] ]);
}

sub ThenBy {
    my ($self, $key_fn, $type) = @_;
    die "ThenBy requires a coderef" unless ref $key_fn eq 'CODE';
    die "ThenBy must follow OrderBy/ThenBy" unless $self->_has_sort_spec;
    $type //= 'auto';
    my @spec = @{ $self->_sort_spec };
    push @spec, [ $key_fn, 'asc', $type ];
    return $self->_sort_with_spec(\@spec);
}

sub ThenByDescending {
    my ($self, $key_fn, $type) = @_;
    die "ThenByDescending requires a coderef" unless ref $key_fn eq 'CODE';
    die "ThenByDescending must follow OrderBy/ThenBy" unless $self->_has_sort_spec;
    $type //= 'auto';
    my @spec = @{ $self->_sort_spec };
    push @spec, [ $key_fn, 'desc', $type ];
    return $self->_sort_with_spec(\@spec);
}

sub Reverse {
    my $self = shift;
    my @items = $self->ToArray;
    @items = reverse @items;
    my $i = 0;
    my $iter = sub {
        return $i < @items ? $items[$i++] : undef;
    };
    return ref($self)->new(_iterator => $iter);
}

1;

__END__

=head1 NAME

Moo::LINQ::Ordering - Ordering operators for Moo::LINQ

=head1 DESCRIPTION

Provides OrderBy, OrderByDescending, ThenBy, ThenByDescending, and Reverse.

Ordering operators materialize the sequence to sort it, then return
a new lazy Query over the sorted result. ThenBy chains by inspecting
the _sort_spec stored on the Query object.

=cut
