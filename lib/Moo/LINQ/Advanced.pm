package Moo::LINQ::Advanced;

use Moo::Role;

our $VERSION = '0.01';

# --- Chunk: split into arrayrefs of $size items ---
sub Chunk {
    my ($self, $size) = @_;
    die "Chunk requires a positive integer"
        unless defined $size && $size > 0;

    my $src = $self->_iterator;
    my $exhausted = 0;

    my $iter = sub {
        return undef if $exhausted;
        my @chunk;
        while (@chunk < $size) {
            my $item = $src->();
            if (!defined $item) {
                $exhausted = 1;
                last;
            }
            push @chunk, $item;
        }
        return @chunk ? \@chunk : undef;
    };

    return ref($self)->new(_iterator => $iter);
}

# --- Scan: running fold, yields each intermediate accumulator ---
sub Scan {
    my ($self, $seed, $fn) = @_;
    die "Scan requires a coderef" unless ref $fn eq 'CODE';

    my $src = $self->_iterator;
    my $acc = $seed;

    my $iter = sub {
        my $item = $src->();
        return undef unless defined $item;
        local $_ = $item;
        $acc = $fn->($acc, $item);
        return $acc;
    };

    return ref($self)->new(_iterator => $iter);
}

# --- Pairwise: yields result of fn(prev, curr) for each adjacent pair ---
sub Pairwise {
    my ($self, $fn) = @_;
    die "Pairwise requires a coderef" unless ref $fn eq 'CODE';

    my $src = $self->_iterator;
    my $prev = $src->();
    my $done = !defined $prev;

    my $iter = sub {
        return undef if $done;
        my $curr = $src->();
        if (!defined $curr) {
            $done = 1;
            return undef;
        }
        my $result;
        {
            local $_ = $curr;
            $result = $fn->($prev, $curr);
        }
        $prev = $curr;
        return $result;
    };

    return ref($self)->new(_iterator => $iter);
}

# --- DistinctBy: dedupe using a key selector ---
sub DistinctBy {
    my ($self, $key_fn) = @_;
    die "DistinctBy requires a coderef" unless ref $key_fn eq 'CODE';

    my $src = $self->_iterator;
    my %seen;

    my $iter = sub {
        while (defined(my $item = $src->())) {
            my $key;
            { local $_ = $item; $key = $key_fn->($item); }
            my $k = defined $key ? "$key" : '__undef__';
            next if $seen{$k}++;
            return $item;
        }
        return undef;
    };

    return ref($self)->new(_iterator => $iter);
}

# --- OrderByCmp: custom comparator (receives ($x, $y) as arguments) ---
sub OrderByCmp {
    my ($self, $cmp_fn) = @_;
    die "OrderByCmp requires a coderef" unless ref $cmp_fn eq 'CODE';

    my @items = $self->ToArray;
    my @sorted = sort { $cmp_fn->($a, $b) } @items;

    my $i = 0;
    my $iter = sub {
        return $i < @sorted ? $sorted[$i++] : undef;
    };

    return ref($self)->new(_iterator => $iter);
}

# --- Repeat: repeat the sequence N times ---
sub Repeat {
    my ($self, $n) = @_;
    die "Repeat requires a non-negative integer"
        unless defined $n && $n >= 0;

    my @items = $self->ToArray;

    my $round = 0;
    my $idx = 0;

    my $iter = sub {
        return undef if $round >= $n;
        return undef unless @items;

        my $item = $items[$idx];
        $idx++;
        if ($idx >= @items) {
            $idx = 0;
            $round++;
        }
        return $item;
    };

    return ref($self)->new(_iterator => $iter);
}

# --- Buffer: alias for Chunk ---
sub Buffer {
    my ($self, $size) = @_;
    return $self->Chunk($size);
}

# --- WhereIndexed: predicate receives ($item, $index) ---
sub WhereIndexed {
    my ($self, $pred) = @_;
    die "WhereIndexed requires a coderef" unless ref $pred eq 'CODE';

    my $src = $self->_iterator;
    my $i = 0;

    my $iter = sub {
        while (defined(my $item = $src->())) {
            my $idx = $i++;
            local $_ = $item;
            return $item if $pred->($item, $idx);
        }
        return undef;
    };

    return ref($self)->new(_iterator => $iter);
}

# --- SelectIndexed: mapper receives ($item, $index) ---
sub SelectIndexed {
    my ($self, $fn) = @_;
    die "SelectIndexed requires a coderef" unless ref $fn eq 'CODE';

    my $src = $self->_iterator;
    my $i = 0;

    my $iter = sub {
        my $item = $src->();
        return undef unless defined $item;
        my $idx = $i++;
        local $_ = $item;
        return $fn->($item, $idx);
    };

    return ref($self)->new(_iterator => $iter);
}

1;

__END__

=head1 NAME

Moo::LINQ::Advanced - Advanced operators for Moo::LINQ

=head1 SYNOPSIS

    use Moo::LINQ;

    # Sliding-window rolling average (chunks of 3)
    my @rolling = Moo::LINQ->From(\@values)
        ->Chunk(3)
        ->Select(sub {
            my $c = shift;
            my $sum = 0;
            $sum += $_ for @$c;
            $sum / @$c;
        })
        ->ToArray();

    # Cumulative sum
    my @cumsum = Moo::LINQ->From(\@values)
        ->Scan(0, sub { $_[0] + $_[1] })
        ->ToArray();

    # Day-over-day deltas
    my @deltas = Moo::LINQ->From(\@daily)
        ->Pairwise(sub { $_[1] - $_[0] })
        ->ToArray();

    # Dedupe by a key
    my @unique_users = Moo::LINQ->From(\@events)
        ->DistinctBy(sub { $_->{user_id} })
        ->ToArray();

    # Custom comparator: length, then alphabetical
    my @sorted = Moo::LINQ->From(\@words)
        ->OrderByCmp(sub {
            my ($x, $y) = @_;
            length($x) <=> length($y) || $x cmp $y;
        })
        ->ToArray();

    # Repeat the sequence three times
    my @rep = Moo::LINQ->From([1, 2])->Repeat(3)->ToArray();
    # => (1, 2, 1, 2, 1, 2)

    # Indexed filtering: keep every other item
    my @evens = Moo::LINQ->From(\@items)
        ->WhereIndexed(sub { $_[1] % 2 == 0 })
        ->ToArray();

    # Indexed projection
    my @tagged = Moo::LINQ->From([qw(a b c)])
        ->SelectIndexed(sub { "$_[1]:$_[0]" })
        ->ToArray();
    # => ('0:a', '1:b', '2:c')

=head1 DESCRIPTION

C<Moo::LINQ::Advanced> adds nine operators to L<Moo::LINQ> that cover
window-based, stateful, or index-aware transformations. They compose
freely with all other operators and preserve the library's lazy
evaluation guarantee, except where noted.

This role is automatically applied to C<Moo::LINQ> — you do not need to
load it directly.

=head1 OPERATORS

=head2 Chunk

    my @chunks = $query->Chunk($size)->ToArray();

Splits the sequence into arrayrefs of at most C<$size> items. The final
chunk may be shorter if the sequence length is not a multiple of
C<$size>. Returns an empty sequence when the source is empty.

Lazy: only pulls C<$size> items from the source per output chunk.

    Moo::LINQ->Range(1, 7)->Chunk(3)->ToArray();
    # => ([1,2,3], [4,5,6], [7])

=head2 Buffer

    my @buffers = $query->Buffer($size)->ToArray();

Alias for C<Chunk>. Provided as a semantically clearer name when the
intent is batching rather than splitting.

=head2 Scan

    my @running = $query->Scan($seed, $fn)->ToArray();

Running fold. Yields each intermediate accumulator value, starting with
the result of applying C<$fn> to the first item. The accumulator begins
at C<$seed>.

C<$fn> is called as C<< $fn->($acc, $item) >>.

Lazy: yields one accumulator per input item.

    Moo::LINQ->Range(1, 5)->Scan(0, sub { $_[0] + $_[1] })->ToArray();
    # => (1, 3, 6, 10, 15)

Use C<Scan> when you want every intermediate value; use C<Aggregate> when
you only want the final result.

=head2 Pairwise

    my @pairs = $query->Pairwise($fn)->ToArray();

Applies C<$fn> to each adjacent pair of items. Yields C<count - 1>
results for a source of C<count> items. Returns an empty sequence when
the source has fewer than two items.

C<$fn> is called as C<< $fn->($prev, $curr) >>.

Lazy: yields one result per adjacent pair.

    Moo::LINQ->Range(1, 5)->Pairwise(sub { $_[1] - $_[0] })->ToArray();
    # => (1, 1, 1, 1)

=head2 DistinctBy

    my @unique = $query->DistinctBy($key_fn)->ToArray();

Deduplicates items using a key selector rather than the item's own value.
The first item seen for each distinct key is retained; subsequent items
with the same key are dropped.

The key is stringified for comparison, so numeric C<1> and string C<"1">
are treated as the same key.

Lazy: yields items on demand as they are first seen.

    Moo::LINQ->From(\@people)
        ->DistinctBy(sub { $_->{id} })
        ->ToArray();

=head2 OrderByCmp

    my @sorted = $query->OrderByCmp($cmp_fn)->ToArray();

Sort using a custom comparator function. This is the escape hatch when
C<OrderBy> / C<ThenBy> cannot express the ordering you need (multi-key
with mixed directions, natural sort, custom collation, etc.).

B<Important:> The comparator receives its two arguments as C<$_[0]> and
C<$_[1]> (or via C<my ($x, $y) = @_>). It does B<not> have access to
C<$a> and C<$b>, because Perl does not propagate the sort globals into
subs called from within a sort block.

The comparator must return a negative number, zero, or a positive
number — the same contract as Perl's built-in C<sort>.

Materializing: the entire sequence is buffered to sort it.

    Moo::LINQ->From(\@words)->OrderByCmp(sub {
        my ($x, $y) = @_;
        length($x) <=> length($y) || $x cmp $y;
    })->ToArray();

=head2 Repeat

    my @repeated = $query->Repeat($n)->ToArray();

Repeats the entire sequence C<$n> times. C<Repeat(0)> yields an empty
sequence. Repeating an empty sequence yields an empty sequence.

Materializing: the source is buffered once so it can be iterated
multiple times.

    Moo::LINQ->From([1, 2])->Repeat(3)->ToArray();
    # => (1, 2, 1, 2, 1, 2)

=head2 WhereIndexed

    my @kept = $query->WhereIndexed($pred)->ToArray();

Like C<Where>, but the predicate is called as
C<< $pred->($item, $index) >>, where C<$index> is the zero-based position
of the item in the source sequence. This mirrors C#'s
C<Where((x, i) => ...)> overload.

Lazy: yields matching items on demand.

    # Keep only items at even positions
    Moo::LINQ->From([qw(a b c d e f)])
        ->WhereIndexed(sub { $_[1] % 2 == 0 })
        ->ToArray();
    # => ('a', 'c', 'e')

=head2 SelectIndexed

    my @mapped = $query->SelectIndexed($fn)->ToArray();

Like C<Select>, but the mapper is called as
C<< $fn->($item, $index) >>, where C<$index> is the zero-based position
of the item in the source sequence. This mirrors C#'s
C<Select((x, i) => ...)> overload.

Lazy: yields mapped items on demand.

    Moo::LINQ->From([qw(a b c)])
        ->SelectIndexed(sub { "$_[1]:$_[0]" })
        ->ToArray();
    # => ('0:a', '1:b', '2:c')

=head1 LAZINESS NOTES

Eight of the nine operators are fully lazy. The two exceptions are:

=over 4

=item * C<OrderByCmp> — must buffer the entire sequence to sort it.

=item * C<Repeat> — buffers the source once so it can be iterated
multiple times.

=back

Both return a new C<Moo::LINQ> object immediately; only the subsequent
iterator is eager.

=head1 SEE ALSO

=over 4

=item * L<Moo::LINQ> — the main class and operator reference

=item * L<Moo::LINQ::Filtering> — C<Where>, C<Take>, C<Skip>, C<Distinct>

=item * L<Moo::LINQ::Projection> — C<Select>, C<SelectMany>, C<Cast>

=item * L<Moo::LINQ::Aggregation> — C<Aggregate>, C<Sum>, C<Average>

=item * L<Moo::LINQ::Ordering> — C<OrderBy>, C<ThenBy>

=back

=head1 AUTHOR

Thomas

=head1 LICENSE

Same as Perl 5.

=cut
