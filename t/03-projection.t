use strict;
use warnings;
use Test::More;
use Moo::LINQ;

# --- Select ---
my @squares = Moo::LINQ->Range(1, 5)
    ->Select(sub { $_ * $_ })
    ->ToArray();
is_deeply \@squares, [1, 4, 9, 16, 25], 'Select squares';

# --- Select after Where ---
my @r = Moo::LINQ->Range(1, 10)
    ->Where(sub { $_ % 2 == 0 })
    ->Select(sub { $_ * 10 })
    ->ToArray();
is_deeply \@r, [20, 40, 60, 80, 100], 'Where then Select';

# --- Select transforming hashes ---
my @users = (
    { name => 'Alice', age => 30 },
    { name => 'Bob',   age => 25 },
    { name => 'Carol', age => 35 },
);
my @names = Moo::LINQ->From(\@users)
    ->Select(sub { $_->{name} })
    ->ToArray();
is_deeply \@names, [qw(Alice Bob Carol)], 'Select extracts field';

# --- SelectMany (flat map) ---
my $data = [ [1, 2], [3, 4], [5] ];
my @flat = Moo::LINQ->From($data)
    ->SelectMany(sub { $_ })
    ->ToArray();
is_deeply \@flat, [1, 2, 3, 4, 5], 'SelectMany flattens arrays';

# --- SelectMany with mapper returning list ---
@flat = Moo::LINQ->Range(1, 3)
    ->SelectMany(sub { ($_, $_ * 10) })
    ->ToArray();
is_deeply \@flat, [1, 10, 2, 20, 3, 30], 'SelectMany expands lists';

# --- Cast ---
my @ints = Moo::LINQ->From(['1', '2', '3'])
    ->Cast('int')
    ->ToArray();
is_deeply \@ints, [1, 2, 3], 'Cast to int';

my @up = Moo::LINQ->From([qw(foo bar)])
    ->Cast('uc')
    ->ToArray();
is_deeply \@up, [qw(FOO BAR)], 'Cast to upper';

# --- Combined pipeline ---
my @pipeline = Moo::LINQ->Range(1, 20)
    ->Where(sub { $_ % 2 == 0 })
    ->Select(sub { $_ * $_ })
    ->Take(3)
    ->ToArray();
is_deeply \@pipeline, [4, 16, 36], 'Full pipeline: Where+Select+Take';

# --- Regression: SelectMany list-order preservation ---
@r = Moo::LINQ->Range(1, 3)
    ->SelectMany(sub { ($_, $_ * 10) })
    ->ToArray();
is_deeply \@r, [1, 10, 2, 20, 3, 30], 'SelectMany list-order regression';

# --- SelectMany arrayref flat-map ---
@r = Moo::LINQ->From([ [1,2], [3,4], [5] ])
    ->SelectMany(sub { $_ })
    ->ToArray();
is_deeply \@r, [1, 2, 3, 4, 5], 'SelectMany arrayref regression';

done_testing;
