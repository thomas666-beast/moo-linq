package Moo::LINQ::Aggregation;

use Moo::Role;

our $VERSION = '0.02';

sub Count {
    my ($self, $pred) = @_;
    my $iter = $self->_iterator;
    my $n = 0;

    if ($pred) {
        die "Count predicate must be a coderef" unless ref $pred eq 'CODE';
        while (defined(my $item = $iter->())) {
            local $_ = $item;
            $n++ if $pred->($item);
        }
    }
    else {
        while (defined $iter->()) { $n++ }
    }

    return $n;
}

sub Sum {
    my ($self, $selector) = @_;
    my $iter = $self->_iterator;
    my $total = 0;

    while (defined(my $item = $iter->())) {
        my $val;
        if ($selector) {
            local $_ = $item;
            $val = $selector->($item);
        }
        else {
            $val = $item;
        }
        $total += $val if defined $val;
    }

    return $total;
}

sub Average {
    my ($self, $selector) = @_;
    my $iter = $self->_iterator;
    my ($total, $n) = (0, 0);

    while (defined(my $item = $iter->())) {
        my $val;
        if ($selector) {
            local $_ = $item;
            $val = $selector->($item);
        }
        else {
            $val = $item;
        }
        next unless defined $val;
        $total += $val;
        $n++;
    }

    die "Average on empty sequence" if $n == 0;
    return $total / $n;
}

sub Min {
    my ($self, $selector) = @_;
    my $iter = $self->_iterator;
    my $best;
    my $seen = 0;

    while (defined(my $item = $iter->())) {
        my $val;
        if ($selector) {
            local $_ = $item;
            $val = $selector->($item);
        }
        else {
            $val = $item;
        }
        next unless defined $val;
        if (!$seen || $val < $best) {
            $best = $val;
            $seen = 1;
        }
    }

    return $best;
}

sub Max {
    my ($self, $selector) = @_;
    my $iter = $self->_iterator;
    my $best;
    my $seen = 0;

    while (defined(my $item = $iter->())) {
        my $val;
        if ($selector) {
            local $_ = $item;
            $val = $selector->($item);
        }
        else {
            $val = $item;
        }
        next unless defined $val;
        if (!$seen || $val > $best) {
            $best = $val;
            $seen = 1;
        }
    }

    return $best;
}

sub Aggregate {
    my ($self, $seed, $func) = @_;
    die "Aggregate requires a coderef" unless ref $func eq 'CODE';

    my $iter = $self->_iterator;
    my $acc = $seed;

    while (defined(my $item = $iter->())) {
        local $_ = $item;
        $acc = $func->($acc, $item);
    }

    return $acc;
}

1;

__END__

=head1 NAME

Moo::LINQ::Aggregation - Aggregate operators for Moo::LINQ

=head1 DESCRIPTION

Provides Count, Sum, Average, Min, Max, and Aggregate.

All operators are terminals (they consume the iterator).

=cut
