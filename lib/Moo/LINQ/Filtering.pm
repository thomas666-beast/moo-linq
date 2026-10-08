package Moo::LINQ::Filtering;

use Moo::Role;

our $VERSION = '0.02';

sub Where {
    my ($self, $pred) = @_;
    die "Where requires a coderef" unless ref $pred eq 'CODE';

    my $src = $self->_iterator;
    my $iter = sub {
        while (defined(my $item = $src->())) {
            local $_ = $item;
            return $item if $pred->($item);
        }
        return undef;
    };

    return ref($self)->new(_iterator => $iter);
}

sub WhereNot {
    my ($self, $pred) = @_;
    die "WhereNot requires a coderef" unless ref $pred eq 'CODE';
    return $self->Where(sub { !$pred->(@_) });
}

sub First {
    my ($self, $pred) = @_;
    my $iter = $self->_iterator;

    if ($pred) {
        die "First predicate must be a coderef" unless ref $pred eq 'CODE';
        while (defined(my $item = $iter->())) {
            local $_ = $item;
            return $item if $pred->($item);
        }
        return undef;
    }

    return $iter->();
}

sub FirstOrDefault {
    my ($self, $default, $pred) = @_;
    my $found = $self->First($pred);
    return defined $found ? $found : $default;
}

sub Any {
    my ($self, $pred) = @_;
    my $iter = $self->_iterator;

    if ($pred) {
        while (defined(my $item = $iter->())) {
            local $_ = $item;
            return 1 if $pred->($item);
        }
        return 0;
    }

    my $first = $iter->();
    return defined $first ? 1 : 0;
}

sub All {
    my ($self, $pred) = @_;
    die "All requires a coderef" unless ref $pred eq 'CODE';

    my $iter = $self->_iterator;
    while (defined(my $item = $iter->())) {
        local $_ = $item;
        return 0 unless $pred->($item);
    }
    return 1;
}

sub Take {
    my ($self, $n) = @_;
    die "Take requires a positive integer" unless $n && $n > 0;

    my $src = $self->_iterator;
    my $taken = 0;
    my $iter = sub {
        return undef if $taken >= $n;
        my $item = $src->();
        return undef unless defined $item;
        $taken++;
        return $item;
    };

    return ref($self)->new(_iterator => $iter);
}

sub Skip {
    my ($self, $n) = @_;
    $n //= 0;
    die "Skip requires a non-negative integer" if $n < 0;

    my $src = $self->_iterator;
    my $skipped = 0;
    my $iter = sub {
        while ($skipped < $n) {
            return undef unless defined $src->();
            $skipped++;
        }
        return $src->();
    };

    return ref($self)->new(_iterator => $iter);
}

sub TakeWhile {
    my ($self, $pred) = @_;
    die "TakeWhile requires a coderef" unless ref $pred eq 'CODE';

    my $src = $self->_iterator;
    my $done = 0;
    my $iter = sub {
        return undef if $done;
        my $item = $src->();
        return undef unless defined $item;
        local $_ = $item;
        if ($pred->($item)) {
            return $item;
        }
        $done = 1;
        return undef;
    };

    return ref($self)->new(_iterator => $iter);
}

sub SkipWhile {
    my ($self, $pred) = @_;
    die "SkipWhile requires a coderef" unless ref $pred eq 'CODE';

    my $src = $self->_iterator;
    my $skipping = 1;
    my $iter = sub {
        while ($skipping) {
            my $item = $src->();
            return undef unless defined $item;
            local $_ = $item;
            if (!$pred->($item)) {
                $skipping = 0;
                return $item;
            }
        }
        return $src->();
    };

    return ref($self)->new(_iterator => $iter);
}

sub Distinct {
    my $self = shift;
    my $src = $self->_iterator;
    my %seen;
    my $iter = sub {
        while (defined(my $item = $src->())) {
            my $key = defined $item ? "$item" : '__undef__';
            next if $seen{$key}++;
            return $item;
        }
        return undef;
    };
    return ref($self)->new(_iterator => $iter);
}

1;

__END__

=head1 NAME

Moo::LINQ::Filtering - Filtering operators for Moo::LINQ

=head1 DESCRIPTION

Provides C<Where>, C<WhereNot>, C<First>, C<FirstOrDefault>, C<Any>,
C<All>, C<Take>, C<Skip>, C<TakeWhile>, C<SkipWhile>, C<Distinct>.

All operators except C<First>, C<FirstOrDefault>, C<Any>, and C<All>
are lazy.

=head1 SEE ALSO

L<Moo::LINQ>

=cut
