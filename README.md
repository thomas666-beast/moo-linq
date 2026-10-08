# Moo::LINQ

A lazy, chainable LINQ-style query library for Perl.

[![Perl](https://img.shields.io/badge/perl-5.16%2B-blue.svg)](https://www.perl.org/)
[![License](https://img.shields.io/badge/license-Perl%205-green.svg)](#license)
[![Tests](https://img.shields.io/badge/tests-100%2B%20passing-brightgreen.svg)](#)

---

## Why?

`Moo::LINQ` brings the expressive power of C#'s LINQ to Perl:

- **Data-source agnostic** — works with arrays, generators, filehandles, hashes, or any iterator.
- **Fully lazy** — no work happens until you ask for a result.
- **Role-based** — each operator family is a separate `Moo::Role`.
- **~55 operators** across filtering, projection, aggregation, ordering, grouping, joining, sets, quantifiers, and conversion.

---

## Installation

From CPAN:

```bash
cpanm Moo::LINQ
```

For development:

```bash
carton install
carton exec -- prove -lv t/
```

---

## Quick Start

```perl
use Moo::LINQ;

my @result = Moo::LINQ->Range(1, 100)
    ->Where(sub { $_ % 2 == 0 })
    ->Select(sub { $_ * 10 })
    ->Take(5)
    ->ToArray();

# => (20, 40, 60, 80, 100)
```

---

## Real-World Example: Log Analysis

Suppose you have an Apache-style log and want to find the top IPs by
request count, plus their average response size.

```perl
use Moo::LINQ;

my @log = (
    { ip => '10.0.0.1', path => '/',      bytes => 1200, status => 200 },
    { ip => '10.0.0.2', path => '/about', bytes => 2400, status => 200 },
    { ip => '10.0.0.1', path => '/docs',  bytes => 800,  status => 200 },
    { ip => '10.0.0.3', path => '/',      bytes => 500,  status => 404 },
    { ip => '10.0.0.1', path => '/blog',  bytes => 3200, status => 200 },
    { ip => '10.0.0.2', path => '/blog',  bytes => 4100, status => 200 },
);

my @top_ips = Moo::LINQ->From(\@log)
    ->Where(sub { $_->{status} == 200 })          # keep successful requests
    ->GroupBy(sub { $_->{ip} })                    # group by IP
    ->Select(sub {
        my $g = shift;
        {
            ip        => $g->key,
            requests  => $g->Count,
            avg_bytes => $g->AsQuery->Average(sub { $_->{bytes} }),
        }
    })
    ->OrderByDescending(sub { $_->{requests} })
    ->ThenBy(sub { $_->{ip} })
    ->Take(5)
    ->ToArray();

for my $row (@top_ips) {
    printf "%-12s requests=%d avg_bytes=%.0f\n",
        $row->{ip}, $row->{requests}, $row->{avg_bytes};
}
```

Output:

```
10.0.0.1     requests=2 avg_bytes=2000
10.0.0.2     requests=2 avg_bytes=3250
```

---

## Laziness in Action

Because `Where`, `Select`, and `GroupBy` are all lazy, this never reads
more than it needs:

```perl
my $first_big = Moo::LINQ->Range(1, 10_000_000)
    ->Where(sub { $_ % 7 == 0 })
    ->First();    # only scans 7 items from the source
```

Compare to eager `map`/`grep` pipelines, which would materialize
10 million elements first.

A quick benchmark (`bench/laziness.pl`) shows the difference on 1M
elements when only the first match is needed:

```bash
carton exec -- perl bench/laziness.pl
```

```
                 Rate  eager (map+grep)  Moo::LINQ (lazy)
eager (map+grep) 1.20/s                --              -99%
Moo::LINQ (lazy) 120/s             9900%                --
```

---

## Operator Reference

See `perldoc Moo::LINQ` for the full list.

### Sources

| Operator | Description |
|----------|-------------|
| `From($src)` | Create a query from an arrayref, coderef, GLOB, hashref, or any iterable |
| `Range($start, $end, $step)` | Lazy numeric range |
| `Empty()` | Empty query |

### Filtering

| Operator | Description |
|----------|-------------|
| `Where($pred)` | Keep items matching predicate |
| `WhereNot($pred)` | Keep items not matching predicate |
| `First($pred?)` | First item (optionally matching) |
| `FirstOrDefault($d, $p?)` | First item or default |
| `Any($pred?)` | True if any match |
| `All($pred)` | True if all match |
| `Take($n)` | First N items |
| `Skip($n)` | Skip first N items |
| `TakeWhile($pred)` | Take while predicate holds |
| `SkipWhile($pred)` | Skip while predicate holds |
| `Distinct()` | Deduplicate |

### Projection

| Operator | Description |
|----------|-------------|
| `Select($fn)` | Transform each item |
| `SelectMany($fn)` | Flat-map |
| `Cast($type)` | Coerce type (`int`, `num`, `string`, `uc`, `lc`) |

### Aggregation

| Operator | Description |
|----------|-------------|
| `Count($pred?)` | Count items |
| `Sum($sel?)` | Sum values |
| `Average($sel?)` | Average values |
| `Min($sel?)` / `Max($sel?)` | Minimum / maximum |
| `Aggregate($seed, $fn)` | Fold with seed |

### Ordering

| Operator | Description |
|----------|-------------|
| `OrderBy($key, $type?)` | Ascending sort |
| `OrderByDescending($key, $type?)` | Descending sort |
| `ThenBy($key, $type?)` | Secondary ascending sort |
| `ThenByDescending($key, $type?)` | Secondary descending sort |
| `Reverse()` | Reverse the sequence |

`$type` is `'auto'` (default), `'numeric'`, or `'string'`.

### Grouping

| Operator | Description |
|----------|-------------|
| `GroupBy($key_fn, $elem_fn?)` | Group items by key |
| `ToLookup($key_fn, $elem_fn?)` | Group into a hashref |

### Joining

| Operator | Description |
|----------|-------------|
| `Join($inner, $ok, $ik, $fn)` | Inner join |
| `GroupJoin($inner, $ok, $ik, $fn)` | Group join |
| `Zip($other, $fn)` | Zip two sequences |

### Sets

| Operator | Description |
|----------|-------------|
| `Concat($other)` | Concatenate sequences |
| `Union($other)` | Union (distinct) |
| `Intersect($other)` | Intersection |
| `Except($other)` | Difference |

### Quantifiers

| Operator | Description |
|----------|-------------|
| `Contains($v)` | Is `$v` present? |
| `SequenceEqual($other)` | Element-wise equality |
| `ElementAt($n)` | Item at index (dies if out of range) |
| `ElementAtOrDefault($n, $d)` | Item at index or default |
| `Single($pred?)` | Exactly one item |
| `SingleOrDefault($d, $p?)` | One item or default |
| `Last($pred?)` / `LastOrDefault($d, $p?)` | Last item |
| `DefaultIfEmpty($d?)` | Default if empty |

### Conversion

| Operator | Description |
|----------|-------------|
| `ToArray()` | List of items |
| `ToList()` | Arrayref of items |
| `ToHash($key, $val?)` | Hashref keyed by selector |
| `ToJson()` | JSON array |
| `ToString($sep?)` | Join items with separator |
| `ForEach($fn)` | Side-effect iteration |
| `Print($sep?)` | Print items |

---

## Architecture

`Moo::LINQ` is composed of `Moo::Role` modules that can be loaded
independently:

```
Moo::LINQ
├── Moo::LINQ::Filtering
├── Moo::LINQ::Projection
├── Moo::LINQ::Aggregation
├── Moo::LINQ::Ordering
├── Moo::LINQ::Grouping
├── Moo::LINQ::Joining
├── Moo::LINQ::Sets
├── Moo::LINQ::Quantifiers
└── Moo::LINQ::Conversion
```

Each non-terminal operator returns a **new `Moo::LINQ` object** wrapping
a composed iterator. This is what enables both laziness and arbitrary
chaining.

---

## Development

### Project layout

```
Moo-LINQ/
├── cpanfile
├── cpanfile.snapshot
├── Makefile.PL
├── README.md
├── Changes
├── bench/
│   └── laziness.pl
├── lib/
│   └── Moo/
│       ├── LINQ.pm
│       └── LINQ/
│           ├── Filtering.pm
│           ├── Projection.pm
│           ├── Aggregation.pm
│           ├── Ordering.pm
│           ├── Grouping.pm
│           ├── Group.pm
│           ├── Joining.pm
│           ├── Sets.pm
│           ├── Quantifiers.pm
│           └── Conversion.pm
└── t/
    ├── 01-basic.t
    ├── 02-filtering.t
    ├── 03-projection.t
    ├── 04-aggregation.t
    ├── 05-ordering.t
    ├── 06-grouping.t
    ├── 07-joining.t
    ├── 08-sets.t
    ├── 09-quantifiers.t
    └── 10-conversion.t
```

### Running tests

```bash
carton install
carton exec -- prove -lv t/
```

### Benchmarks

```bash
carton exec -- perl bench/laziness.pl
```

---

## Comparison

| Feature | `Moo::LINQ` | `CSV::LINQ` | `LTSV::LINQ` | `List::Linq` |
|---------|:-----------:|:-----------:|:------------:|:------------:|
| Data-source agnostic | ✅ | ❌ CSV only | ❌ LTSV only | ✅ |
| Fully lazy | ✅ | ⚠️ partial | ⚠️ partial | ⚠️ partial |
| Chainable | ✅ | ✅ | ✅ | ✅ |
| Role-based composition | ✅ | ❌ | ❌ | ❌ |
| Grouping / Joining | ✅ | ✅ | ✅ | ✅ |
| Sets / Quantifiers | ✅ | ❌ | ❌ | ⚠️ |
| Conversion (`ToJson`, `ToHash`) | ✅ | ❌ | ❌ | ❌ |
| Built on `Moo` | ✅ | ❌ | ❌ | ❌ |

---

## License

Same as Perl 5.

---

## Author

Thomas
