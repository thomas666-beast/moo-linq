use strict;
use warnings;
use Test::More;
use Moo::LINQ;

# --- Chunk ---
my @chunks = Moo::LINQ->Range(1, 7)->Chunk(3)->ToArray();
is_deeply \@chunks, [[1,2,3],[4,5,6],[7]], 'Chunk with remainder';

@chunks = Moo::LINQ->Range(1, 6)->Chunk(2)->ToArray();
is_deeply \@chunks, [[1,2],[3,4],[5,6]], 'Chunk even split';

@chunks = Moo::LINQ->Empty()->Chunk(3)->ToArray();
is_deeply \@chunks, [], 'Chunk on empty';

# --- Scan ---
my @running = Moo::LINQ->Range(1, 5)
    ->Scan(0, sub { $_[0] + $_[1] })
    ->ToArray();
is_deeply \@running, [1, 3, 6, 10, 15], 'Scan running sum';

my @strings = Moo::LINQ->From([qw(a b c)])
    ->Scan('', sub { $_[0] . $_[1] })
    ->ToArray();
is_deeply \@strings, [qw(a ab abc)], 'Scan running concat';

# --- Pairwise ---
my @diffs = Moo::LINQ->Range(1, 5)
    ->Pairwise(sub { $_[1] - $_[0] })
    ->ToArray();
is_deeply \@diffs, [1, 1, 1, 1], 'Pairwise differences';

my @sums = Moo::LINQ->From([1, 2, 3, 4])
    ->Pairwise(sub { $_[0] + $_[1] })
    ->ToArray();
is_deeply \@sums, [3, 5, 7], 'Pairwise sums';

@sums = Moo::LINQ->From([42])->Pairwise(sub { $_[0] + $_[1] })->ToArray();
is_deeply \@sums, [], 'Pairwise on single element';

@sums = Moo::LINQ->Empty()->Pairwise(sub { $_[0] + $_[1] })->ToArray();
is_deeply \@sums, [], 'Pairwise on empty';

# --- DistinctBy ---
my @people = (
    { id => 1, name => 'Alice' },
    { id => 2, name => 'Bob' },
    { id => 1, name => 'Alicia' },   # same id, different name
    { id => 3, name => 'Carol' },
);
my @unique = Moo::LINQ->From(\@people)
    ->DistinctBy(sub { $_->{id} })
    ->Select(sub { $_->{name} })
    ->ToArray();
is_deeply \@unique, [qw(Alice Bob Carol)], 'DistinctBy keeps first of each key';

# --- OrderByCmp ---
my @words = qw(banana apple cherry fig);

my @by_length = Moo::LINQ->From(\@words)
    ->OrderByCmp(sub {
        my ($x, $y) = @_;
        length($x) <=> length($y) || $x cmp $y;
    })
    ->ToArray();
is_deeply \@by_length, [qw(fig apple banana cherry)],
    'OrderByCmp custom comparator';

# Reverse comparator
my @by_length_desc = Moo::LINQ->From(\@words)
    ->OrderByCmp(sub {
        my ($x, $y) = @_;
        length($y) <=> length($x) || $y cmp $x;
    })
    ->ToArray();
is_deeply \@by_length_desc, [qw(cherry banana apple fig)],
    'OrderByCmp descending comparator';

# --- Repeat ---
my @rep = Moo::LINQ->From([1, 2])->Repeat(3)->ToArray();
is_deeply \@rep, [1,2,1,2,1,2], 'Repeat 3 times';

@rep = Moo::LINQ->From([1, 2])->Repeat(0)->ToArray();
is_deeply \@rep, [], 'Repeat 0 times';

@rep = Moo::LINQ->Empty()->Repeat(5)->ToArray();
is_deeply \@rep, [], 'Repeat on empty';

# --- Buffer (alias for Chunk) ---
my @buf = Moo::LINQ->Range(1, 5)->Buffer(2)->ToArray();
is_deeply \@buf, [[1,2],[3,4],[5]], 'Buffer = Chunk';

# --- WhereIndexed ---
my @even_pos = Moo::LINQ->From([qw(a b c d e f)])
    ->WhereIndexed(sub { $_[1] % 2 == 0 })
    ->ToArray();
is_deeply \@even_pos, [qw(a c e)], 'WhereIndexed keeps even indices';

# --- SelectIndexed ---
my @indexed = Moo::LINQ->From([qw(a b c)])
    ->SelectIndexed(sub { "$_[1]:$_[0]" })
    ->ToArray();
is_deeply \@indexed, [qw(0:a 1:b 2:c)], 'SelectIndexed';

# --- Combined pipeline ---
my @pipeline = Moo::LINQ->Range(1, 20)
    ->WhereIndexed(sub { $_[1] % 3 == 0 })
    ->Chunk(3)
    ->Select(sub { scalar @$_ })
    ->ToArray();
# Indices 0,3,6,9,12,15,18 → values 1,4,7,10,13,16,19
# Chunked into 3s: [1,4,7], [10,13,16], [19]
# Sizes: 3, 3, 1
is_deeply \@pipeline, [3, 3, 1], 'WhereIndexed + Chunk + Select pipeline';

done_testing;
