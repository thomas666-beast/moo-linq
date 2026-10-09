# NAME

Moo::LINQ - A lazy, chainable LINQ-style query library for Perl

# SYNOPSIS

    use Moo::LINQ;

    # Simple pipeline
    my @evens = Moo::LINQ->Range(1, 100)
        ->Where(sub { $_ % 2 == 0 })
        ->Select(sub { $_ * 10 })
        ->Take(5)
        ->ToArray();
    # => (20, 40, 60, 80, 100)

    # Group, aggregate, sort -- all lazily
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

# DESCRIPTION

`Moo::LINQ` brings C#-style Language Integrated Query to Perl. It provides
a fluent, chainable API over any iterable data source, with full lazy
evaluation powered by [Iterator::Simple](https://metacpan.org/pod/Iterator%3A%3ASimple).

Unlike data-source-specific modules (`CSV::LINQ`, `LTSV::LINQ`), it works
with arrays, generators, filehandles, hashes, or any object conforming to
the iterator protocol. Unlike eager alternatives, no work happens until a
terminal operator is invoked.

# QUICK REFERENCE

## Sources

    Moo::LINQ->From($arrayref | $coderef | $glob | $hashref | $iterable)
    Moo::LINQ->Range($start, $end, $step = 1)
    Moo::LINQ->Empty()

## Filtering

    ->Where($pred)          ->WhereNot($pred)      ->First($pred?)
    ->FirstOrDefault($d, $p?)                       ->Any($pred?)
    ->All($pred)            ->Take($n)             ->Skip($n)
    ->TakeWhile($pred)      ->SkipWhile($pred)     ->Distinct()

## Projection

    ->Select($mapper)       ->SelectMany($mapper)  ->Cast($type)

## Aggregation

    ->Count($pred?)         ->Sum($sel?)           ->Average($sel?)
    ->Min($sel?)            ->Max($sel?)           ->Aggregate($seed, $fn)

## Ordering

    ->OrderBy($key, $type?)           ->OrderByDescending($key, $type?)
    ->ThenBy($key, $type?)            ->ThenByDescending($key, $type?)
    ->Reverse()

`$type` is `'auto'` (default), `'numeric'`, or `'string'`.

## Grouping

    ->GroupBy($key_fn, $elem_fn?)     ->ToLookup($key_fn, $elem_fn?)

## Joining

    ->Join($inner, $outer_key, $inner_key, $result_fn)
    ->GroupJoin($inner, $outer_key, $inner_key, $result_fn)
    ->Zip($other, $result_fn)

## Sets

    ->Concat($other)   ->Union($other)
    ->Intersect($other)->Except($other)

## Quantifiers

    ->Contains($v)          ->SequenceEqual($other)
    ->ElementAt($n)         ->ElementAtOrDefault($n, $default)
    ->Single($pred?)        ->SingleOrDefault($default, $pred?)
    ->Last($pred?)          ->LastOrDefault($default, $pred?)
    ->DefaultIfEmpty($d?)

## Conversion

    ->ToArray()   ->ToList()   ->ToHash($key, $val?)
    ->ToJson()    ->ToString($sep?) ->ForEach($fn) ->Print($sep?)

## Advanced

    ->Chunk($size)                  ->Scan($seed, $fn)
    ->Pairwise($fn)                 ->DistinctBy($key_fn)
    ->OrderByCmp($cmp_fn)           ->Repeat($n)
    ->Buffer($size)                 ->WhereIndexed($pred)
    ->SelectIndexed($fn)

## Sources

    Moo::LINQ->From($arrayref | $coderef | $glob | $hashref | $iterable)
    Moo::LINQ->Range($start, $end, $step = 1)
    Moo::LINQ->Empty()

    # File sources (Moo::LINQ::Source role)
    Moo::LINQ->FromLines($path, %opts)
    Moo::LINQ->FromCSV($path, %opts)
    Moo::LINQ->FromTSV($path, %opts)
    Moo::LINQ->FromLTSV($path, %opts)
    Moo::LINQ->FromJSON($path, %opts)

    # SQLite (requires DBI + DBD::SQLite)
    Moo::LINQ->FromSQLite($path, $sql, \@params?)

# LAZINESS

Every non-terminal operator returns a new `Moo::LINQ` object wrapping a
composed iterator. Nothing executes until you call a terminal operator
(`ToArray`, `First`, `Sum`, `ForEach`, `Print`, etc.).

    my $query = Moo::LINQ->Range(1, 1_000_000)
        ->Where(sub { $_ % 2 == 0 })
        ->Select(sub { $_ * $_ });
    # No work has happened yet.

    my $first = $query->First();   # Only 1 item produced from the range.

# ROLES

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
    Moo::LINQ::Source
    Moo::LINQ::Source::Lines
    Moo::LINQ::Source::CSV
    Moo::LINQ::Source::TSV
    Moo::LINQ::Source::LTSV
    Moo::LINQ::Source::JSON
    Moo::LINQ::Source::SQLite

# SEE ALSO

- [Iterator::Simple](https://metacpan.org/pod/Iterator%3A%3ASimple) - the laziness engine
- [Moo](https://metacpan.org/pod/Moo) - the OO foundation
- [CSV::LINQ](https://metacpan.org/pod/CSV%3A%3ALINQ), [LTSV::LINQ](https://metacpan.org/pod/LTSV%3A%3ALINQ) - data-source-specific alternatives

# AUTHOR

Thomas

# LICENSE

Same as Perl 5.
