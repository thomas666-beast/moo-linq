package Moo::LINQ;

use Moo;
use Iterator::Simple qw(iterator iter);

use Moo::LINQ::Group;

with 'Moo::LINQ::Filtering',
     'Moo::LINQ::Projection',
     'Moo::LINQ::Aggregation',
     'Moo::LINQ::Ordering',
     'Moo::LINQ::Grouping',
     'Moo::LINQ::Joining',
     'Moo::LINQ::Sets',
     'Moo::LINQ::Quantifiers',
     'Moo::LINQ::Conversion',
     'Moo::LINQ::Advanced';

our $VERSION = '0.11';

has _iterator => (
    is       => 'ro',
    required => 1,
);

has _sort_spec => (
    is        => 'ro',
    predicate => '_has_sort_spec',
);

sub From {
    my ($class, $source) = @_;
    my $iter;

    if (ref $source eq 'ARRAY') {
        my $i = 0;
        $iter = sub { return $i < @$source ? $source->[$i++] : undef };
    }
    elsif (ref $source eq 'CODE') {
        $iter = $source;
    }
    elsif (ref $source eq 'GLOB') {
        $iter = sub { return scalar <$source> };
    }
    elsif (ref $source eq 'HASH') {
        my @pairs = map { [$_, $source->{$_}] } keys %$source;
        return $class->From(\@pairs);
    }
    else {
        $iter = iter($source);
    }

    return $class->new(_iterator => $iter);
}

sub Range {
    my ($class, $start, $end, $step) = @_;
    $step //= 1;
    my $current = $start;
    my $iter = sub {
        return undef if $current > $end;
        my $val = $current;
        $current += $step;
        return $val;
    };
    return $class->new(_iterator => $iter);
}

sub Empty {
    my $class = shift;
    return $class->new(_iterator => sub { return undef });
}

sub ToArray {
    my $self = shift;
    my @out;
    my $iter = $self->_iterator;
    while (defined(my $item = $iter->())) {
        push @out, $item;
    }
    return @out;
}

sub ToList {
    my $self = shift;
    my @items = $self->ToArray;
    return \@items;
}

1;

__END__

=head1 NAME

Moo::LINQ - A lazy, chainable LINQ-style query library for Perl

=head1 SYNOPSIS

    use Moo::LINQ;

    # Simple pipeline
    my @evens = Moo::LINQ->Range(1, 100)
        ->Where(sub { $_ % 2 == 0 })
        ->Select(sub { $_ * 10 })
        ->Take(5)
        ->ToArray();
    # => (20, 40, 60, 80, 100)

    # Group, aggregate, sort — all lazily
    my @people = (
        { name => 'Alice', dept => 'Eng',   salary => 120 },
        { name => 'Bob',   dept => 'Sales', salary => 90  },
        { name => 'Carol', dept => 'Eng',   salary => 130 },
    );

    my @summary = Moo::LINQ->From(\@people)
        ->GroupBy(sub { $_->{dept} })
        ->Select(sub {
            my $g = shift;
            [ $g->key, $g->AsQuery->Average(sub { $_->{salary} }) ]
        })
        ->OrderByDescending(sub { $_->[1] })
        ->ToArray();

=head1 DESCRIPTION

C<Moo::LINQ> brings C#-style Language Integrated Query to Perl. It provides
a fluent, chainable API over any iterable data source, with full lazy
evaluation powered by L<Iterator::Simple>.

Unlike data-source-specific modules (C<CSV::LINQ>, C<LTSV::LINQ>), it works
with arrays, generators, filehandles, hashes, or any object conforming to
the iterator protocol. Unlike eager alternatives, no work happens until a
terminal operator is invoked.

=head1 QUICK REFERENCE

=head2 Sources

    Moo::LINQ->From($arrayref | $coderef | $glob | $hashref | $iterable)
    Moo::LINQ->Range($start, $end, $step = 1)
    Moo::LINQ->Empty()

=head2 Filtering

    ->Where($pred)          ->WhereNot($pred)      ->First($pred?)
    ->FirstOrDefault($d, $p?)                       ->Any($pred?)
    ->All($pred)            ->Take($n)             ->Skip($n)
    ->TakeWhile($pred)      ->SkipWhile($pred)     ->Distinct()

=head2 Projection

    ->Select($mapper)       ->SelectMany($mapper)  ->Cast($type)

=head2 Aggregation

    ->Count($pred?)         ->Sum($sel?)           ->Average($sel?)
    ->Min($sel?)            ->Max($sel?)           ->Aggregate($seed, $fn)

=head2 Ordering

    ->OrderBy($key, $type?)           ->OrderByDescending($key, $type?)
    ->ThenBy($key, $type?)            ->ThenByDescending($key, $type?)
    ->Reverse()

C<$type> is C<'auto'> (default), C<'numeric'>, or C<'string'>.

=head2 Grouping

    ->GroupBy($key_fn, $elem_fn?)     ->ToLookup($key_fn, $elem_fn?)

=head2 Joining

    ->Join($inner, $outer_key, $inner_key, $result_fn)
    ->GroupJoin($inner, $outer_key, $inner_key, $result_fn)
    ->Zip($other, $result_fn)

=head2 Sets

    ->Concat($other)   ->Union($other)
    ->Intersect($other)->Except($other)

=head2 Quantifiers

    ->Contains($v)          ->SequenceEqual($other)
    ->ElementAt($n)         ->ElementAtOrDefault($n, $default)
    ->Single($pred?)        ->SingleOrDefault($default, $pred?)
    ->Last($pred?)          ->LastOrDefault($default, $pred?)
    ->DefaultIfEmpty($d?)

=head2 Conversion

    ->ToArray()   ->ToList()   ->ToHash($key, $val?)
    ->ToJson()    ->ToString($sep?) ->ForEach($fn) ->Print($sep?)

=head2 Advanced

    ->Chunk($size)                  ->Scan($seed, $fn)
    ->Pairwise($fn)                 ->DistinctBy($key_fn)
    ->OrderByCmp($cmp_fn)           ->Repeat($n)
    ->Buffer($size)                 ->WhereIndexed($pred)
    ->SelectIndexed($fn)

=head1 LAZINESS

Every non-terminal operator returns a new C<Moo::LINQ> object wrapping a
composed iterator. Nothing executes until you call a terminal operator
(C<ToArray>, C<First>, C<Sum>, C<ForEach>, C<Print>, etc.).

    my $query = Moo::LINQ->Range(1, 1_000_000)
        ->Where(sub { $_ % 2 == 0 })
        ->Select(sub { $_ * $_ });
    # No work has happened yet.

    my $first = $query->First();   # Only 1 item produced from the range.

=head1 ROLES

The library is composed of role modules that can be loaded independently:

    Moo::LINQ::Filtering
    Moo::LINQ::Projection
    Moo::LINQ::Aggregation
    Moo::LINQ::Ordering
    Moo::LINQ::Grouping
    Moo::LINQ::Joining
    Moo::LINQ::Sets
    Moo::LINQ::Quantifiers
    Moo::LINQ::Conversion
    Moo::LINQ::Advanced

=head1 SEE ALSO

=over 4

=item * L<Iterator::Simple> - the laziness engine

=item * L<Moo> - the OO foundation

=item * L<CSV::LINQ>, L<LTSV::LINQ> - data-source-specific alternatives

=back

=head1 AUTHOR

Thomas

=head1 LICENSE

Same as Perl 5.

=cut
